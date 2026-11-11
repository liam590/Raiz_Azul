<?php
// backend/api/reportes.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../models/DataStore.php';
require_once __DIR__ . '/../services/AgronomiaService.php';

try {
    $store = new DataStore();
    $parcelas = $store->getParcelas();
    $registros = $store->getRegistros();

    // -------------------------------------------------------------
    // Parámetros de filtro / agrupación
    // -------------------------------------------------------------
    $fechaDesde = isset($_GET['fechaDesde']) ? trim($_GET['fechaDesde']) : '';
    $fechaHasta = isset($_GET['fechaHasta']) ? trim($_GET['fechaHasta']) : '';
    $agruparPor = strtolower(isset($_GET['agruparPor']) ? trim($_GET['agruparPor']) : 'parcela');

    // Validar formato de fechas (Y-m-d); si es inválida se ignora
    $validDate = function ($d) {
        if ($d === '') return null;
        $dt = DateTime::createFromFormat('Y-m-d', $d);
        return ($dt && $dt->format('Y-m-d') === $d) ? $d : null;
    };
    $fechaDesde = $validDate($fechaDesde);
    $fechaHasta = $validDate($fechaHasta);

    $agrupacionesValidas = ['parcela', 'finca', 'cultivo', 'zona'];
    if (!in_array($agruparPor, $agrupacionesValidas, true)) {
        $agruparPor = 'parcela';
    }

    $reporteParcelas = [];
    $totalAguaRiego = 0;
    $totalLluviaAcum = 0;

    foreach ($parcelas as $p) {
        $pid = $p['IdParcela'];
        $finca = $p['NombreFinca'];
        $area = floatval($p['AreaManzanas']);
        $siembra = $p['FechaSiembra'];

        // Límite inferior del ciclo, salvo que el usuario indique un rango
        $desde = $fechaDesde ?? $siembra;
        $hasta = $fechaHasta; // null = sin límite superior

        // Registros correspondientes al rango/ciclo
        $riegos = 0;
        $litros = 0;
        $insumos = 0;
        $labores = 0;

        foreach ($registros as $r) {
            $rPid = $r['parcelaId'] ?? $r['IdParcela'] ?? null;
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $f = $r['fecha'] ?? $r['Fecha'];
            $val = floatval($r['valor'] ?? $r['Valor'] ?? 0);

            if ($rPid != $pid) continue;
            if ($f < $desde) continue;
            if ($hasta !== null && $f > $hasta) continue;

            if ($tipo === 'riego') {
                $riegos++;
                $litros += $val;
            } elseif ($tipo === 'insumo') {
                $insumos += $val;
            } elseif ($tipo === 'labor') {
                $labores++;
            }
        }

        // Lluvias de la parcela o de la finca general
        $lluviaMm = 0;
        foreach ($registros as $r) {
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $rPid = $r['parcelaId'] ?? $r['IdParcela'] ?? null;
            $f = $r['fecha'] ?? $r['Fecha'];
            $val = floatval($r['valor'] ?? $r['Valor'] ?? 0);

            if ($tipo !== 'lluvia') continue;
            if ($f < $desde) continue;
            if ($hasta !== null && $f > $hasta) continue;
            if ($rPid == $pid || $rPid === "finca:{$finca}") {
                $lluviaMm += $val;
            }
        }

        $litrosPorMz = $area > 0 ? round($litros / $area, 1) : 0;
        $totalAguaRiego += $litros;
        $totalLluviaAcum += $lluviaMm;

        $reporteParcelas[] = [
            'id' => $pid,
            'nombre' => $p['NombreParcela'],
            'cultivo' => $p['NombreCultivo'],
            'finca' => $p['NombreFinca'],
            'zona' => $p['NombreZona'],
            'areaManzanas' => $area,
            'fechaSiembra' => $siembra,
            'numRiegos' => $riegos,
            'litrosRiego' => $litros,
            'litrosPorManzana' => $litrosPorMz,
            'lluviaAcumuladaMm' => $lluviaMm,
            'insumosLb' => $insumos,
            'totalLabores' => $labores
        ];
    }

    // Ordenar parcelas por consumo de agua por manzana descendente
    usort($reporteParcelas, fn($a, $b) => $b['litrosPorManzana'] <=> $a['litrosPorManzana']);

    // -------------------------------------------------------------
    // Agrupación dinámica
    // -------------------------------------------------------------
    $campoGrupo = [
        'parcela' => 'nombre',
        'finca'   => 'finca',
        'cultivo' => 'cultivo',
        'zona'    => 'zona',
    ][$agruparPor];

    $grupos = [];
    foreach ($reporteParcelas as $row) {
        $clave = $row[$campoGrupo] !== '' ? $row[$campoGrupo] : 'Sin asignar';
        if (!isset($grupos[$clave])) {
            $grupos[$clave] = [
                'nombre' => $clave,
                'parcelas' => 0,
                'areaManzanas' => 0,
                'numRiegos' => 0,
                'litrosRiego' => 0,
                'lluviaAcumuladaMm' => 0,
                'insumosLb' => 0,
                'totalLabores' => 0,
            ];
        }
        $g = &$grupos[$clave];
        $g['parcelas']++;
        $g['areaManzanas'] += $row['areaManzanas'];
        $g['numRiegos'] += $row['numRiegos'];
        $g['litrosRiego'] += $row['litrosRiego'];
        $g['lluviaAcumuladaMm'] += $row['lluviaAcumuladaMm'];
        $g['insumosLb'] += $row['insumosLb'];
        $g['totalLabores'] += $row['totalLabores'];
        unset($g);
    }

    // Calcular L/mz por grupo y redondear lluvia promedio del grupo
    $gruposOut = [];
    foreach ($grupos as $g) {
        $areaG = $g['areaManzanas'];
        $g['areaManzanas'] = round($areaG, 2);
        $g['litrosPorManzana'] = $areaG > 0 ? round($g['litrosRiego'] / $areaG, 1) : 0;
        $g['litrosRiego'] = round($g['litrosRiego'], 1);
        $g['lluviaPromedioMm'] = $g['parcelas'] > 0 ? round($g['lluviaAcumuladaMm'] / $g['parcelas'], 1) : 0;
        $g['lluviaAcumuladaMm'] = round($g['lluviaAcumuladaMm'], 1);
        $g['insumosLb'] = round($g['insumosLb'], 1);
        $gruposOut[] = $g;
    }
    usort($gruposOut, fn($a, $b) => $b['litrosPorManzana'] <=> $a['litrosPorManzana']);

    // Calcular ahorro potencial (riego evitable)
    $dashboard = $store->getDashboard();
    $ahorro = $dashboard['ahorroPotencialLitros'] ?? 0;
    $promedioLluvia = count($parcelas) > 0 ? round($totalLluviaAcum / count($parcelas), 1) : 0;

    echo json_encode([
        'status' => 'success',
        'data' => [
            'filtros' => [
                'fechaDesde' => $fechaDesde,
                'fechaHasta' => $fechaHasta,
                'agruparPor' => $agruparPor,
            ],
            'totalAguaRiego' => $totalAguaRiego,
            'lluviaPromedioMm' => $promedioLluvia,
            'ahorroPotencialLitros' => $ahorro,
            'parcelas' => $reporteParcelas,
            'grupos' => $gruposOut
        ]
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
