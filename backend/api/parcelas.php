<?php
// backend/api/parcelas.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../models/DataStore.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$store = new DataStore();

try {
    if ($method === 'GET') {
        $idFinca = isset($_GET['idFinca']) ? intval($_GET['idFinca']) : null;
        $parcelas = $store->getParcelas($idFinca);
        
        echo json_encode([
            'status' => 'success',
            'data' => $parcelas
        ], JSON_UNESCAPED_UNICODE);
        exit();
    }

    if ($method === 'POST') {
        $body = json_decode(file_get_contents('php://input'), true) ?? $_POST;
        
        $nombre = trim($body['nombre'] ?? '');
        $finca = trim($body['finca'] ?? '');
        $zona = trim($body['zona'] ?? 'Matagalpa');
        $cultivo = trim($body['cultivo'] ?? 'Tomate');
        $area = floatval($body['area'] ?? 0);
        $siembra = trim($body['siembra'] ?? date('Y-m-d'));

        if (empty($nombre) || empty($finca) || $area <= 0) {
            http_response_code(400);
            echo json_encode([
                'status' => 'error',
                'message' => 'Faltan campos obligatorios (nombre, finca, área válida)'
            ]);
            exit();
        }

        $id = $store->agregarParcela($nombre, $finca, $zona, $cultivo, $area, $siembra);

        http_response_code(201);
        echo json_encode([
            'status' => 'success',
            'message' => 'Parcela creada exitosamente',
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
            echo json_encode(['status' => 'error', 'message' => 'ID de parcela no especificado']);
            exit();
        }

        $store->eliminarParcela($id);
        echo json_encode(['status' => 'success', 'message' => 'Parcela eliminada']);
        exit();
    }

    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido']);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
