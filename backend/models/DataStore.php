<?php
// backend/models/DataStore.php

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../services/AgronomiaService.php';

class DataStore {
    private $db;
    private $conn;
    private $jsonFile;

    public function __construct() {
        $this->db = new Database();
        $this->conn = $this->db->getConnection();
        $this->jsonFile = __DIR__ . '/../data_fallback.json';
        $this->initFallbackData();
    }

    public function isSqlServerConnected() {
        return $this->conn !== null;
    }

    public function getDriverName() {
        return $this->db->driverUsed;
    }

    private function initFallbackData() {
        if (!file_exists($this->jsonFile)) {
            $hoy = date('Y-m-d');
            $sample = [
                'fincas' => [
                    ['id' => 1, 'nombre' => 'La Esperanza', 'zona' => 'Matagalpa'],
                    ['id' => 2, 'nombre' => 'El Mirador', 'zona' => 'Jinotega']
                ],
                'parcelas' => [
                    [
                        'id' => 1,
                        'idFinca' => 1,
                        'nombre' => 'Lote Alto',
                        'finca' => 'La Esperanza',
                        'zona' => 'Matagalpa',
                        'cultivo' => 'Tomate',
                        'area' => 1.5,
                        'siembra' => AgronomiaService::addDays($hoy, -52),
                        'cosechada' => false
                    ],
                    [
                        'id' => 2,
                        'idFinca' => 1,
                        'nombre' => 'Vega del Río',
                        'finca' => 'La Esperanza',
                        'zona' => 'Matagalpa',
                        'cultivo' => 'Frijol',
                        'area' => 2.0,
                        'siembra' => AgronomiaService::addDays($hoy, -38),
                        'cosechada' => false
                    ],
                    [
                        'id' => 3,
                        'idFinca' => 2,
                        'nombre' => 'Terraza Norte',
                        'finca' => 'El Mirador',
                        'zona' => 'Jinotega',
                        'cultivo' => 'Maíz',
                        'area' => 3.0,
                        'siembra' => AgronomiaService::addDays($hoy, -96),
                        'cosechada' => false
                    ],
                    [
                        'id' => 4,
                        'idFinca' => 2,
                        'nombre' => 'Ladera Sur',
                        'finca' => 'El Mirador',
                        'zona' => 'Jinotega',
                        'cultivo' => 'Repollo',
                        'area' => 1.0,
                        'siembra' => AgronomiaService::addDays($hoy, -84),
                        'cosechada' => false
                    ]
                ],
                'registros' => [
                    // Lluvias
                    ['id' => 1, 'parcelaId' => 'finca:La Esperanza', 'idFinca' => 1, 'tipo' => 'lluvia', 'fecha' => AgronomiaService::addDays($hoy, -2), 'valor' => 24, 'detalle' => '', 'nota' => '', 'autor' => 'Liam'],
                    ['id' => 2, 'parcelaId' => 'finca:La Esperanza', 'idFinca' => 1, 'tipo' => 'lluvia', 'fecha' => AgronomiaService::addDays($hoy, -9), 'valor' => 8, 'detalle' => '', 'nota' => '', 'autor' => 'Cristin'],
                    ['id' => 3, 'parcelaId' => 'finca:El Mirador', 'idFinca' => 2, 'tipo' => 'lluvia', 'fecha' => AgronomiaService::addDays($hoy, -1), 'valor' => 5, 'detalle' => '', 'nota' => '', 'autor' => 'Iris'],
                    // Riegos
                    ['id' => 4, 'parcelaId' => 1, 'idFinca' => 1, 'tipo' => 'riego', 'fecha' => AgronomiaService::addDays($hoy, -4), 'valor' => 6700, 'detalle' => '', 'nota' => 'Riego por goteo', 'metodoRiego' => 'Goteo', 'duracionMinutos' => 45, 'grupoRiego' => null, 'autor' => 'Liam'],
                    ['id' => 5, 'parcelaId' => 2, 'idFinca' => 1, 'tipo' => 'riego', 'fecha' => AgronomiaService::addDays($hoy, -3), 'valor' => 8000, 'detalle' => '', 'nota' => 'Riego matutino', 'metodoRiego' => 'Aspersión', 'duracionMinutos' => 60, 'grupoRiego' => null, 'autor' => 'Cristin'],
                    ['id' => 6, 'parcelaId' => 3, 'idFinca' => 2, 'tipo' => 'riego', 'fecha' => AgronomiaService::addDays($hoy, -4), 'valor' => 18000, 'detalle' => '', 'nota' => '', 'metodoRiego' => 'Gravedad', 'duracionMinutos' => 90, 'grupoRiego' => null, 'autor' => 'Iris'],
                    // Insumos
                    ['id' => 7, 'parcelaId' => 1, 'idFinca' => 1, 'tipo' => 'insumo', 'fecha' => AgronomiaService::addDays($hoy, -17), 'valor' => 90, 'detalle' => 'Fórmula 12-30-10', 'nota' => '1.ª fertilización', 'autor' => 'Cristin'],
                    // Labores
                    ['id' => 8, 'parcelaId' => 1, 'idFinca' => 1, 'tipo' => 'labor', 'fecha' => AgronomiaService::addDays($hoy, -12), 'valor' => 0, 'detalle' => 'Deshierbe', 'nota' => '', 'autor' => 'Iris']
                ]
            ];
            file_put_contents($this->jsonFile, json_encode($sample, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        }
    }

    private function getFallbackData() {
        return json_decode(file_get_contents($this->jsonFile), true);
    }

    private function saveFallbackData($data) {
        file_put_contents($this->jsonFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }

    // -------------------------------------------------------------
    // PARCELAS
    // -------------------------------------------------------------
    public function getParcelas($idFinca = null) {
        if ($this->conn) {
            $stmt = $this->conn->prepare("EXEC sp_ListarParcelas @IdFinca = :idFinca");
            $stmt->execute([':idFinca' => $idFinca]);
            $list = $stmt->fetchAll();
            $registros = $this->getRegistros();
            
            foreach ($list as &$p) {
                $p['recomendaciones'] = AgronomiaService::calcularRecomendaciones($p, $registros);
            }
            return $list;
        }

        $data = $this->getFallbackData();
        $registros = $data['registros'];
        $parcelas = $data['parcelas'];

        if ($idFinca) {
            $parcelas = array_filter($parcelas, fn($p) => $p['idFinca'] == $idFinca);
        }

        $result = [];
        foreach ($parcelas as $p) {
            $etapa = AgronomiaService::calcularEtapa($p['cultivo'], $p['siembra']);
            $recs = AgronomiaService::calcularRecomendaciones($p, $registros);

            $result[] = [
                'IdParcela' => $p['id'],
                'NombreParcela' => $p['nombre'],
                'IdFinca' => $p['idFinca'],
                'NombreFinca' => $p['finca'],
                'NombreZona' => $p['zona'],
                'NombreCultivo' => $p['cultivo'],
                'AreaManzanas' => (float)$p['area'],
                'FechaSiembra' => $p['siembra'],
                'Cosechada' => $p['cosechada'],
                'CicloDias' => $etapa['ciclo'],
                'DiasDesdeSiembra' => $etapa['dias'],
                'FechaEstimadaCosecha' => $etapa['fechaCosechaEstimada'],
                'PorcentajeCiclo' => $etapa['pct'] * 100,
                'EtapaActual' => $etapa['etapa'],
                'recomendaciones' => $recs
            ];
        }
        return $result;
    }

    public function agregarParcela($nombre, $fincaNombre, $zona, $cultivo, $area, $siembra) {
        if ($this->conn) {
            // Buscar o crear finca
            $stmtFinca = $this->conn->prepare("SELECT TOP 1 IdFinca FROM Fincas WHERE NombreFinca = :finca");
            $stmtFinca->execute([':finca' => $fincaNombre]);
            $f = $stmtFinca->fetch();
            $idFinca = $f ? $f['IdFinca'] : null;

            if (!$idFinca) {
                $stmtZona = $this->conn->prepare("SELECT TOP 1 IdZona FROM Zonas WHERE NombreZona = :zona");
                $stmtZona->execute([':zona' => $zona]);
                $z = $stmtZona->fetch();
                $idZona = $z ? $z['IdZona'] : 1;

                $stmtInsertFinca = $this->conn->prepare("INSERT INTO Fincas (NombreFinca, IdZona) VALUES (:finca, :zona); SELECT SCOPE_IDENTITY() as Id;");
                $stmtInsertFinca->execute([':finca' => $fincaNombre, ':zona' => $idZona]);
                $idFinca = $this->conn->lastInsertId();
            }

            // Buscar IdCultivo
            $stmtCult = $this->conn->prepare("SELECT TOP 1 IdCultivo FROM Cultivos WHERE NombreCultivo = :cultivo");
            $stmtCult->execute([':cultivo' => $cultivo]);
            $c = $stmtCult->fetch();
            $idCultivo = $c ? $c['IdCultivo'] : 1;

            $stmt = $this->conn->prepare("EXEC sp_RegistrarParcela @IdFinca = :idFinca, @NombreParcela = :nombre, @IdCultivo = :idCultivo, @AreaManzanas = :area, @FechaSiembra = :siembra");
            $stmt->execute([
                ':idFinca' => $idFinca,
                ':nombre' => $nombre,
                ':idCultivo' => $idCultivo,
                ':area' => $area,
                ':siembra' => $siembra
            ]);
            $row = $stmt->fetch();
            return $row['IdParcelaGenerada'] ?? 0;
        }

        $data = $this->getFallbackData();
        $newId = count($data['parcelas']) > 0 ? max(array_column($data['parcelas'], 'id')) + 1 : 1;
        $nueva = [
            'id' => $newId,
            'idFinca' => 1,
            'nombre' => $nombre,
            'finca' => $fincaNombre,
            'zona' => $zona,
            'cultivo' => $cultivo,
            'area' => (float)$area,
            'siembra' => $siembra,
            'cosechada' => false
        ];
        $data['parcelas'][] = $nueva;
        $this->saveFallbackData($data);
        return $newId;
    }

    public function eliminarParcela($id) {
        if ($this->conn) {
            $stmt = $this->conn->prepare("DELETE FROM Parcelas WHERE IdParcela = :id");
            return $stmt->execute([':id' => $id]);
        }
        $data = $this->getFallbackData();
        $data['parcelas'] = array_values(array_filter($data['parcelas'], fn($p) => $p['id'] != $id));
        $data['registros'] = array_values(array_filter($data['registros'], fn($r) => ($r['parcelaId'] ?? null) != $id));
        $this->saveFallbackData($data);
        return true;
    }

    // -------------------------------------------------------------
    // REGISTROS DE CAMPO
    // -------------------------------------------------------------
    public function getRegistros($idParcela = null, $idFinca = null) {
        if ($this->conn) {
            $sql = "SELECT r.IdRegistro, r.IdFinca, r.IdParcela, t.Codigo AS TipoCodigo, t.Nombre AS TipoNombre,
                           r.Fecha, r.Valor, r.Detalle, r.Nota, r.NombreAutor,
                           r.MetodoRiego, r.DuracionMinutos, r.GrupoRiego,
                           ISNULL(p.NombreParcela, CONCAT('Toda la finca ', f.NombreFinca)) AS Destino
                    FROM RegistrosCampo r
                    INNER JOIN TiposRegistro t ON r.IdTipoRegistro = t.IdTipoRegistro
                    INNER JOIN Fincas f ON r.IdFinca = f.IdFinca
                    LEFT JOIN Parcelas p ON r.IdParcela = p.IdParcela
                    WHERE (:idParcela IS NULL OR r.IdParcela = :idParcela)
                      AND (:idFinca IS NULL OR r.IdFinca = :idFinca)
                    ORDER BY r.Fecha DESC, r.IdRegistro DESC";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute([':idParcela' => $idParcela, ':idFinca' => $idFinca]);
            return $stmt->fetchAll();
        }

        $data = $this->getFallbackData();
        $regs = $data['registros'];
        if ($idParcela) {
            $regs = array_filter($regs, fn($r) => ($r['parcelaId'] ?? null) == $idParcela);
        }
        usort($regs, fn($a, $b) => strcmp($b['fecha'], $a['fecha']));
        return array_values($regs);
    }

    public function agregarRegistro($idFinca, $idParcela, $tipo, $fecha, $valor, $detalle, $nota, $nombreAutor, $metodoRiego = null, $duracionMinutos = null, $grupoRiego = null) {
        if ($this->conn) {
            $stmt = $this->conn->prepare("EXEC sp_GuardarRegistroCampo 
                @IdFinca = :idFinca, 
                @IdParcela = :idParcela, 
                @CodigoTipo = :tipo, 
                @Fecha = :fecha, 
                @Valor = :valor, 
                @Detalle = :detalle, 
                @Nota = :nota, 
                @NombreAutor = :autor,
                @MetodoRiego = :metodoRiego,
                @DuracionMinutos = :duracionMinutos,
                @GrupoRiego = :grupoRiego");
            $stmt->execute([
                ':idFinca' => $idFinca,
                ':idParcela' => $idParcela,
                ':tipo' => $tipo,
                ':fecha' => $fecha,
                ':valor' => $valor,
                ':detalle' => $detalle,
                ':nota' => $nota,
                ':autor' => $nombreAutor,
                ':metodoRiego' => $metodoRiego,
                ':duracionMinutos' => $duracionMinutos,
                ':grupoRiego' => $grupoRiego
            ]);
            $row = $stmt->fetch();
            return $row['IdRegistroGenerado'] ?? 0;
        }

        $data = $this->getFallbackData();
        $newId = count($data['registros']) > 0 ? max(array_column($data['registros'], 'id')) + 1 : 1;
        $nuevo = [
            'id' => $newId,
            'parcelaId' => $idParcela,
            'idFinca' => $idFinca ?? 1,
            'tipo' => $tipo,
            'fecha' => $fecha,
            'valor' => (float)$valor,
            'detalle' => $detalle ?? '',
            'nota' => $nota ?? '',
            'metodoRiego' => $tipo === 'riego' ? $metodoRiego : null,
            'duracionMinutos' => $tipo === 'riego' ? $duracionMinutos : null,
            'grupoRiego' => $tipo === 'riego' ? $grupoRiego : null,
            'autor' => $nombreAutor ?: 'Productor'
        ];
        $data['registros'][] = $nuevo;

        if ($tipo === 'labor' && $detalle === 'Cosecha' && $idParcela) {
            foreach ($data['parcelas'] as &$p) {
                if ($p['id'] == $idParcela) {
                    $p['cosechada'] = true;
                }
            }
        }

        $this->saveFallbackData($data);
        return $newId;
    }

    public function eliminarRegistro($id) {
        if ($this->conn) {
            $stmt = $this->conn->prepare("DELETE FROM RegistrosCampo WHERE IdRegistro = :id");
            return $stmt->execute([':id' => $id]);
        }
        $data = $this->getFallbackData();
        $data['registros'] = array_values(array_filter($data['registros'], fn($r) => $r['id'] != $id));
        $this->saveFallbackData($data);
        return true;
    }

    // -------------------------------------------------------------
    // DASHBOARD
    // -------------------------------------------------------------
    public function getDashboard() {
        $parcelas = $this->getParcelas();
        $registros = $this->getRegistros();
        $hoy = date('Y-m-d');
        $hace7 = AgronomiaService::addDays($hoy, -7);

        // Litros regados en últimos 7 días
        $litros7 = 0;
        foreach ($registros as $r) {
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $f = $r['fecha'] ?? $r['Fecha'];
            if ($tipo === 'riego' && $f >= $hace7 && $f <= $hoy) {
                $litros7 += floatval($r['valor'] ?? $r['Valor'] ?? 0);
            }
        }

        // Recolectar todas las alertas/recomendaciones activas
        $alertas = [];
        foreach ($parcelas as $p) {
            $recs = $p['recomendaciones'] ?? AgronomiaService::calcularRecomendaciones($p, $registros);
            foreach ($recs as $rec) {
                if ($rec['nivel'] !== 'ok') {
                    $alertas[] = array_merge($rec, [
                        'parcelaId' => $p['IdParcela'],
                        'parcelaNombre' => $p['NombreParcela'],
                        'cultivo' => $p['NombreCultivo']
                    ]);
                }
            }
        }

        // Riegos potencialmente evitables
        $ahorroAgua = 0;
        $lluviasFuertes = array_filter($registros, function($r) {
            return ($r['tipo'] ?? $r['TipoCodigo'] ?? '') === 'lluvia' && floatval($r['valor'] ?? $r['Valor'] ?? 0) >= 20;
        });

        foreach ($registros as $r) {
            if (($r['tipo'] ?? $r['TipoCodigo'] ?? '') === 'riego') {
                $fRiego = $r['fecha'] ?? $r['Fecha'];
                $pid = $r['parcelaId'] ?? $r['IdParcela'] ?? null;
                $fid = $r['idFinca'] ?? $r['IdFinca'] ?? null;

                foreach ($lluviasFuertes as $ll) {
                    $fLluvia = $ll['fecha'] ?? $ll['Fecha'];
                    $pidLl = $ll['parcelaId'] ?? $ll['IdParcela'] ?? null;
                    $fidLl = $ll['idFinca'] ?? $ll['IdFinca'] ?? null;

                    $match = ($pid && $pid == $pidLl) || ($fid && $fid == $fidLl);
                    if ($match) {
                        $diff = AgronomiaService::diffDays($fLluvia, $fRiego);
                        if ($diff >= 0 && $diff <= 2) {
                            $ahorroAgua += floatval($r['valor'] ?? $r['Valor'] ?? 0);
                            break;
                        }
                    }
                }
            }
        }

        // Últimos 7 registros para el feed de actividad
        $actividad = array_slice($registros, 0, 7);

        return [
            'totalParcelas' => count($parcelas),
            'litrosRegados7Dias' => $litros7,
            'totalAlertas' => count($alertas),
            'ahorroPotencialLitros' => $ahorroAgua,
            'alertas' => $alertas,
            'actividadReciente' => $actividad,
            'driver' => $this->getDriverName(),
            'isSqlServer' => $this->isSqlServerConnected()
        ];
    }
}
