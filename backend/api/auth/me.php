<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../middleware/auth_middleware.php';
require_once __DIR__ . '/../../helpers/response.php';

$payload = requireAuth();
jsonResponse(true, 'Usuario autenticado', [
    'user' => [
        'id' => $payload['sub'],
        'username' => $payload['username'],
        'nombre_completo' => $payload['nombre'],
        'rol' => $payload['rol'],
        'id_finca' => $payload['id_finca'] ?? null
    ]
], 200);
