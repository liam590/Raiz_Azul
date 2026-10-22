<?php
// backend/services/AgronomiaService.php

class AgronomiaService {
    public static $CROPS = [
        'Tomate' => [
            'ciclo' => 100,
            'riego' => 3,
            'ref' => 4500,
            'fert' => [[15, '1.ª fertilización'], [35, '2.ª fertilización'], [55, '3.ª fertilización']]
        ],
        'Chile' => [
            'ciclo' => 110,
            'riego' => 3,
            'ref' => 4000,
            'fert' => [[15, '1.ª fertilización'], [40, '2.ª fertilización']]
        ],
        'Repollo' => [
            'ciclo' => 90,
            'riego' => 3,
            'ref' => 4000,
            'fert' => [[14, '1.ª fertilización'], [35, '2.ª fertilización']]
        ],
        'Maíz' => [
            'ciclo' => 120,
            'riego' => 6,
            'ref' => 6000,
            'fert' => [[15, '1.ª fertilización'], [35, '2.ª fertilización']]
        ],
        'Frijol' => [
            'ciclo' => 75,
            'riego' => 6,
            'ref' => 4000,
            'fert' => [[12, 'Fertilización de arranque'], [30, 'Refuerzo de fertilización']]
        ]
    ];

    public static function diffDays($date1, $date2) {
        $d1 = new DateTime($date1);
        $d2 = new DateTime($date2);
        $diff = $d1->diff($d2);
        return $diff->invert ? -$diff->days : $diff->days;
    }

    public static function addDays($date, $days) {
        $d = new DateTime($date);
        if ($days >= 0) {
            $d->modify("+{$days} days");
        } else {
            $d->modify("{$days} days");
        }
        return $d->format('Y-m-d');
    }

    public static function calcularEtapa($cultivoNombre, $fechaSiembra) {
        $c = self::$CROPS[$cultivoNombre] ?? self::$CROPS['Maíz'];
        $hoy = date('Y-m-d');
        
        $d1 = new DateTime($fechaSiembra);
        $d2 = new DateTime($hoy);
        $diff = $d1->diff($d2);
        $dias = $diff->invert ? 0 : $diff->days;
        
        $pct = $c['ciclo'] > 0 ? $dias / $c['ciclo'] : 0;
        
        $etapa = 'Establecimiento';
        if ($pct >= 1.0) {
            $etapa = 'Punto de cosecha';
        } elseif ($pct >= 0.80) {
            $etapa = 'Maduración';
        } elseif ($pct >= 0.50) {
            $etapa = 'Floración y llenado';
        } elseif ($pct >= 0.15) {
            $etapa = 'Desarrollo';
        }

        return [
            'pct' => min(1.0, max(0.0, round($pct, 2))),
            'etapa' => $etapa,
            'dias' => $dias,
            'ciclo' => $c['ciclo'],
            'fechaCosechaEstimada' => self::addDays($fechaSiembra, $c['ciclo'])
        ];
    }

    public static function calcularRecomendaciones($parcela, $registros) {
        $cultivo = $parcela['cultivo'] ?? $parcela['NombreCultivo'] ?? 'Maíz';
        $siembra = $parcela['siembra'] ?? $parcela['FechaSiembra'] ?? date('Y-m-d');
        $parcelaId = $parcela['id'] ?? $parcela['IdParcela'];
        $fincaNombre = $parcela['finca'] ?? $parcela['NombreFinca'] ?? '';

        $c = self::$CROPS[$cultivo] ?? self::$CROPS['Maíz'];
        $hoy = date('Y-m-d');

        // Filtrar registros propios de la parcela
        $own = array_filter($registros, function($r) use ($parcelaId) {
            return ($r['parcelaId'] ?? $r['IdParcela'] ?? null) == $parcelaId;
        });

        // Verificar si ya fue cosechada
        $esCosechada = ($parcela['Cosechada'] ?? false) || !empty(array_filter($own, function($r) {
            return ($r['tipo'] ?? $r['TipoCodigo'] ?? '') === 'labor' && ($r['detalle'] ?? $r['Detalle'] ?? '') === 'Cosecha';
        }));

        if ($esCosechada) {
            return [
                [
                    'nivel' => 'ok',
                    'titulo' => 'Cosecha registrada',
                    'descripcion' => 'Revisar el reporte de consumo de este ciclo.'
                ]
            ];
        }

        $out = [];
        $d1 = new DateTime($siembra);
        $d2 = new DateTime($hoy);
        $diff = $d1->diff($d2);
        $dia = $diff->invert ? 0 : $diff->days;
        $rest = $c['ciclo'] - $dia;

        // Lluvias de la parcela o de la finca general
        $lluvias = array_filter($registros, function($r) use ($parcelaId, $fincaNombre) {
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $pid = $r['parcelaId'] ?? $r['IdParcela'] ?? '';
            return $tipo === 'lluvia' && ($pid == $parcelaId || $pid === "finca:{$fincaNombre}");
        });

        $rainDays = function($days) use ($lluvias, $hoy) {
            $total = 0;
            foreach ($lluvias as $r) {
                $f = $r['fecha'] ?? $r['Fecha'];
                $d = (new DateTime($f))->diff(new DateTime($hoy));
                if (!$d->invert && $d->days >= 0 && $d->days < $days) {
                    $total += floatval($r['valor'] ?? $r['Valor'] ?? 0);
                }
            }
            return $total;
        };

        $r3 = $rainDays(3);
        $r7 = $rainDays(7);

        // Último riego
        $riegos = array_filter($own, function($r) {
            return ($r['tipo'] ?? $r['TipoCodigo'] ?? '') === 'riego';
        });
        usort($riegos, function($a, $b) {
            return strcmp($b['fecha'] ?? $b['Fecha'], $a['fecha'] ?? $a['Fecha']);
        });

        $desde = $dia;
        if (!empty($riegos)) {
            $fUlt = $riegos[0]['fecha'] ?? $riegos[0]['Fecha'];
            $d = (new DateTime($fUlt))->diff(new DateTime($hoy));
            $desde = $d->invert ? 0 : $d->days;
        }

        // Cosecha
        if ($rest <= 0) {
            $out[] = [
                'nivel' => 'alerta',
                'titulo' => 'Cosecha estimada cumplida',
                'descripcion' => "El ciclo de " . strtolower($cultivo) . " ({$c['ciclo']} días) ya terminó. Confirmar el punto de cosecha en campo."
            ];
        } elseif ($rest <= 10) {
            $out[] = [
                'nivel' => 'info',
                'titulo' => "Cosecha estimada en {$rest} días",
                'descripcion' => "Reducir el riego según el cultivo y preparar la mano de obra."
            ];
        }

        // Riesgo de escorrentía
        $insumosRecientes = array_filter($own, function($r) use ($hoy) {
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $f = $r['fecha'] ?? $r['Fecha'];
            $d = (new DateTime($f))->diff(new DateTime($hoy));
            return $tipo === 'insumo' && !$d->invert && $d->days >= 0 && $d->days <= 3;
        });

        if ($r3 >= 40 && !empty($insumosRecientes)) {
            $out[] = [
                'nivel' => 'alerta',
                'titulo' => 'Riesgo de escorrentía',
                'descripcion' => "Se aplicó fertilizante y cayeron {$r3} mm en 3 días. Revisar zanjas y barreras para evitar pérdida de insumo hacia las fuentes de agua."
            ];
        }

        // Recomendación de Riego
        if ($r3 >= 20) {
            $out[] = [
                'nivel' => 'info',
                'titulo' => 'Posponer el riego',
                'descripcion' => "Llovieron {$r3} mm en los últimos 3 días. Revisar el drenaje y la humedad antes de volver a regar."
            ];
        } elseif ($desde >= $c['riego'] && $rest > 0) {
            if ($r7 >= 30) {
                $out[] = [
                    'nivel' => 'info',
                    'titulo' => 'Revisar humedad antes de regar',
                    'descripcion' => "Han pasado {$desde} días del último riego, pero la lluvia acumulada en 7 días suma {$r7} mm. Comprobar el suelo antes de regar."
                ];
            } else {
                $out[] = [
                    'nivel' => 'alerta',
                    'titulo' => 'Revisar el riego',
                    'descripcion' => "Han pasado {$desde} días desde el último riego. Para " . strtolower($cultivo) . " la referencia es cada {$c['riego']} días. Confirmar la humedad del suelo."
                ];
            }
        }

        // Ventana de fertilización
        foreach ($c['fert'] as $fert) {
            $d = $fert[0];
            $nombreLab = $fert[1];
            $fMin = self::addDays($siembra, $d - 6);

            $insumoAplicado = !empty(array_filter($own, function($r) use ($fMin) {
                return ($r['tipo'] ?? $r['TipoCodigo'] ?? '') === 'insumo' && ($r['fecha'] ?? $r['Fecha']) >= $fMin;
            }));

            if ($dia >= ($d - 2) && $dia <= ($d + 10) && !$insumoAplicado) {
                if ($dia >= $d) {
                    $out[] = [
                        'nivel' => 'alerta',
                        'titulo' => "Toca: " . lcfirst($nombreLab),
                        'descripcion' => "Van {$dia} días desde la siembra y no hay un insumo registrado en esta ventana. La dosis debe definirse con un técnico o análisis de suelo."
                    ];
                } else {
                    $diasFaltan = $d - $dia;
                    $out[] = [
                        'nivel' => 'info',
                        'titulo' => "Se acerca: " . lcfirst($nombreLab),
                        'descripcion' => "Corresponde alrededor del día {$d} del cultivo, en {$diasFaltan} días."
                    ];
                }
            }
        }

        if (empty($out)) {
            $out[] = [
                'nivel' => 'ok',
                'titulo' => 'Manejo al día',
                'descripcion' => 'Sin alertas por ahora. Seguir registrando riegos, lluvias e insumos.'
            ];
        }

        // Ordenar por prioridad (alerta primero, luego info, luego ok)
        $prioridad = ['alerta' => 0, 'info' => 1, 'ok' => 2];
        usort($out, function($a, $b) use ($prioridad) {
            return ($prioridad[$a['nivel']] ?? 3) <=> ($prioridad[$b['nivel']] ?? 3);
        });

        return $out;
    }
}
