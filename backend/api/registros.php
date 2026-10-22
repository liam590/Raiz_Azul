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
        $tipo = trim($body['tipo'] ?? 'riego');
        $fecha = trim($body['fecha'] ?? date('Y-m-d'));
        $valor = floatval($body['valor'] ?? 0);
        $detalle = trim($body['detalle'] ?? '');
        $nota = trim($body['nota'] ?? '');
        $nombreAutor = trim($body['autor'] ?? 'Productor');

        if ($tipo !== 'labor' && $valor <= 0) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'El valor debe ser mayor a cero']);
            exit();
        }

        $id = $store->agregarRegistro($idFinca, $idParcela, $tipo, $fecha, $valor, $detalle, $nota, $nombreAutor);

        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'message' => 'Registro guardado exitosamente',
            'id' => $id
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
