<?php
// backend/api/calendario.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../models/DataStore.php';
require_once __DIR__ . '/../services/AgronomiaService.php';

try {
    $store = new DataStore();
    $parcelas = $store->getParcelas();
    $registros = $store->getRegistros();
    $hoy = date('Y-m-d');

    $eventos = [];

    // 1. Eventos reales registrados
    foreach ($registros as $r) {
        $tipo = $r['tipo'] ?? $r['TipoCodigo'] ?? 'labor';
        $f = $r['fecha'] ?? $r['Fecha'];
        $val = floatval($r['valor'] ?? $r['Valor'] ?? 0);
        $det = $r['detalle'] ?? $r['Detalle'] ?? '';

        $desc = '';
        if ($tipo === 'riego') $desc = "Riego · " . number_format($val, 0) . " L";
        elseif ($tipo === 'lluvia') $desc = "Lluvia · " . number_format($val, 1) . " mm";
        elseif ($tipo === 'insumo') $desc = ($det ?: 'Insumo') . " · " . number_format($val, 1) . " lb";
        else $desc = $det ?: 'Labor';

        $eventos[] = [
            'fecha' => $f,
            'tipo' => $tipo,
            'parcelaId' => $r['parcelaId'] ?? $r['IdParcela'] ?? null,
            'titulo' => $desc,
            'real' => true,
            'autor' => $r['autor'] ?? $r['NombreAutor'] ?? ''
        ];
    }

    // 2. Eventos estimados basados en reglas agronómicas
    foreach ($parcelas as $p) {
        $cultivo = $p['NombreCultivo'];
        $c = AgronomiaService::$CROPS[$cultivo] ?? AgronomiaService::$CROPS['Maíz'];
        $siembra = $p['FechaSiembra'];
        $pid = $p['IdParcela'];
        $pNom = $p['NombreParcela'];

        // Siembra
        $eventos[] = [
            'fecha' => $siembra,
            'tipo' => 'siembra',
            'parcelaId' => $pid,
            'titulo' => "Siembra de " . strtolower($cultivo) . " ({$pNom})",
            'real' => true
        ];

        if (!empty($p['Cosechada'])) continue;

        // Cosecha estimada
        $fCosecha = AgronomiaService::addDays($siembra, $c['ciclo']);
        $eventos[] = [
            'fecha' => $fCosecha,
            'tipo' => 'cosecha',
            'parcelaId' => $pid,
            'titulo' => "Cosecha estimada de " . strtolower($cultivo) . " ({$pNom})",
            'real' => false
        ];

        // Ventanas de fertilización proyectadas
        foreach ($c['fert'] as $fert) {
            $fFert = AgronomiaService::addDays($siembra, $fert[0]);
            $eventos[] = [
                'fecha' => $fFert,
                'tipo' => 'insumo',
                'parcelaId' => $pid,
                'titulo' => "{$fert[1]} sugerida ({$pNom})",
                'real' => false
            ];
        }

        // Próximo riego estimado
        $riegosParcela = array_filter($registros, function($r) use ($pid) {
            return ($r['parcelaId'] ?? $r['IdParcela'] ?? null) == $pid && ($r['tipo'] ?? $r['TipoCodigo'] ?? '') === 'riego';
        });
        usort($riegosParcela, fn($a, $b) => strcmp($b['fecha'] ?? $b['Fecha'], $a['fecha'] ?? $a['Fecha']));
        
        $proxRiego = !empty($riegosParcela) 
            ? AgronomiaService::addDays($riegosParcela[0]['fecha'] ?? $riegosParcela[0]['Fecha'], $c['riego'])
            : $hoy;

        if ($proxRiego < $hoy) $proxRiego = $hoy;

        $eventos[] = [
            'fecha' => $proxRiego,
            'tipo' => 'riego',
            'parcelaId' => $pid,
            'titulo' => "Revisar riego ({$pNom})",
            'real' => false
        ];
    }

    echo json_encode([
        'status' => 'success',
        'data' => $eventos
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
