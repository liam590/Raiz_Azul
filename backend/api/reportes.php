<?php
// backend/api/reportes.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../models/DataStore.php';
require_once __DIR__ . '/../services/AgronomiaService.php';

try {
    $store = new DataStore();
    $parcelas = $store->getParcelas();
    $registros = $store->getRegistros();

    $reporteParcelas = [];
    $totalAguaRiego = 0;
    $totalLluviaAcum = 0;

    foreach ($parcelas as $p) {
        $pid = $p['IdParcela'];
        $finca = $p['NombreFinca'];
        $area = floatval($p['AreaManzanas']);
        $siembra = $p['FechaSiembra'];

        // Registros correspondientes al ciclo (desde siembra)
        $riegos = 0;
        $litros = 0;
        $insumos = 0;
        $labores = 0;

        foreach ($registros as $r) {
            $rPid = $r['parcelaId'] ?? $r['IdParcela'] ?? null;
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $f = $r['fecha'] ?? $r['Fecha'];
            $val = floatval($r['valor'] ?? $r['Valor'] ?? 0);

            if ($rPid == $pid && $f >= $siembra) {
                if ($tipo === 'riego') {
                    $riegos++;
                    $litros += $val;
                } elseif ($tipo === 'insumo') {
                    $insumos += $val;
                } elseif ($tipo === 'labor') {
                    $labores++;
                }
            }
        }

        // Lluvias de la parcela o de la finca general
        $lluviaMm = 0;
        foreach ($registros as $r) {
            $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? '';
            $rPid = $r['parcelaId'] ?? $r['IdParcela'] ?? null;
            $f = $r['fecha'] ?? $r['Fecha'];
            $val = floatval($r['valor'] ?? $r['Valor'] ?? 0);

            if ($tipo === 'lluvia' && $f >= $siembra && ($rPid == $pid || $rPid === "finca:{$finca}")) {
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

    // Calcular ahorro potencial (riego evitable)
    $dashboard = $store->getDashboard();
    $ahorro = $dashboard['ahorroPotencialLitros'] ?? 0;
    $promedioLluvia = count($parcelas) > 0 ? round($totalLluviaAcum / count($parcelas), 1) : 0;

    echo json_encode([
        'status' => 'success',
        'data' => [
            'totalAguaRiego' => $totalAguaRiego,
            'lluviaPromedioMm' => $promedioLluvia,
            'ahorroPotencialLitros' => $ahorro,
            'parcelas' => $reporteParcelas
        ]
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
