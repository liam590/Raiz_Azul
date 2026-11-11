<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/users_repo.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Método no permitido', null, 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$refreshToken = $input['refreshToken'] ?? '';

if ($refreshToken) {
    $repo = new AuthUserRepository();
    $repo->clearRefreshTokenByHash(hash('sha256', $refreshToken));
}

jsonResponse(true, 'Sesión cerrada correctamente', null, 200);
