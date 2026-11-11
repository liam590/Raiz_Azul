<?php
// backend/api/registros.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../models/DataStore.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$store = new DataStore();

try {
    if ($method === 'GET') {
        $idParcela = isset($_GET['idParcela']) ? intval($_GET['idParcela']) : null;
        $idFinca = isset($_GET['idFinca']) ? intval($_GET['idFinca']) : null;
        $registros = $store->getRegistros($idParcela, $idFinca);

        echo json_encode([
            'status' => 'success',
            'data' => $registros
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ($method === 'POST') {
        $body = json_decode(file_get_contents('php://input'), true) ?? $_POST;

        $idFinca = isset($body['idFinca']) ? intval($body['idFinca']) : 1;
        $idParcela = !empty($body['parcelaId']) ? $body['parcelaId'] : (!empty($body['idParcela']) ? $body['idParcela'] : null);

        // Los registros de "toda la finca" llegan como "finca:Nombre"; en SQL
        // se guardan sin parcela y se identifican por IdFinca.
        if (is_string($idParcela) && strpos($idParcela, 'finca:') === 0) {
            $idParcela = null;
        }

        $tipo = trim($body['tipo'] ?? 'riego');
        $fecha = trim($body['fecha'] ?? date('Y-m-d'));
        $valor = floatval($body['valor'] ?? 0);
        $detalle = trim($body['detalle'] ?? '');
        $nota = trim($body['nota'] ?? '');
        $nombreAutor = trim($body['autor'] ?? 'Productor');

        $metodoRiego = $tipo === 'riego' ? trim($body['metodoRiego'] ?? '') : '';
        $duracionMinutos = null;
        if ($tipo === 'riego' && isset($body['duracionMinutos']) && $body['duracionMinutos'] !== '') {
            $duracionMinutos = intval($body['duracionMinutos']);
            if ($duracionMinutos <= 0) $duracionMinutos = null;
        }
        $grupoRiego = $tipo === 'riego' ? trim($body['grupoRiego'] ?? '') : '';

        // El formulario puede enviar varias fechas para un mismo riego.
        $fechas = $body['fechas'] ?? null;
        if (!is_array($fechas) || empty($fechas)) {
            $fechas = [$fecha];
        }
        $fechas = array_values(array_unique(array_filter(
            array_map(fn($f) => trim((string)$f), $fechas),
            fn($f) => $f !== ''
        )));
        sort($fechas);

        if (empty($fechas)) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Indica al menos una fecha']);
            exit();
        }

        foreach ($fechas as $f) {
            $dt = DateTime::createFromFormat('Y-m-d', $f);
            if (!$dt || $dt->format('Y-m-d') !== $f) {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => "Fecha inválida: {$f}"]);
                exit();
            }
        }

        if ($tipo !== 'labor' && $valor <= 0) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'El valor debe ser mayor a cero']);
            exit();
        }

        $ids = [];
        foreach ($fechas as $f) {
            $ids[] = $store->agregarRegistro(
                $idFinca,
                $idParcela,
                $tipo,
                $f,
                $valor,
                $detalle,
                $nota,
                $nombreAutor,
                $metodoRiego ?: null,
                $duracionMinutos,
                $grupoRiego ?: null
            );
        }

        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'message' => count($ids) > 1
                ? 'Se guardaron ' . count($ids) . ' registros' . ($tipo === 'riego' ? ' de riego' : '')
                : 'Registro guardado exitosamente',
            'id' => $ids[0] ?? null,
            'ids' => $ids
        ]);
        exit();
    }

    if ($method === 'DELETE') {
        $id = isset($_GET['id']) ? intval($_GET['id']) : null;
        if (!$id) {
            $body = json_decode(file_get_contents('php://input'), true);
            $id = $body['id'] ?? null;
        }

        if (!$id) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'ID de registro no especificado']);
            exit();
        }

        $store->eliminarRegistro($id);
        echo json_encode(['status' => 'success', 'message' => 'Registro eliminado']);
        exit();
    }

    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
