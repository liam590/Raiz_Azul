<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt_helper.php';
require_once __DIR__ . '/users_repo.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Método no permitido', null, 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$refreshToken = $input['refreshToken'] ?? '';

if (!$refreshToken) {
    jsonResponse(false, 'Refresh token requerido', null, 401);
}

$repo = new AuthUserRepository();
$hash = hash('sha256', $refreshToken);
$user = $repo->findByRefreshHash($hash);

if (!$user) {
    jsonResponse(false, 'Refresh token inválido o expirado', null, 401);
}

$newRefresh = JwtHelper::createRefreshToken();
$newHash = hash('sha256', $newRefresh);
$newExp = date('Y-m-d H:i:s', time() + REFRESH_TOKEN_TTL);

$repo->saveRefreshToken((int)$user['IdUsuario'], $newHash, $newExp);

$access = JwtHelper::createAccessToken($user);

jsonResponse(true, 'Token renovado', [
    'accessToken' => $access,
    'refreshToken' => $newRefresh,
    'expiresIn' => ACCESS_TOKEN_TTL
], 200);
