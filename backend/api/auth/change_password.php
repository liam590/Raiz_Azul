<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt_helper.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/users_repo.php';

// Validar JWT
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
    jsonResponse(false, 'Token de acceso requerido', null, 401);
}

$token = $matches[1];
$payload = JwtHelper::validateAccessToken($token);
if (!$payload) {
    jsonResponse(false, 'Token inválido o expirado', null, 401);
}

$idUsuario = $payload['sub'] ?? null;
if (!$idUsuario) {
    jsonResponse(false, 'Token inválido', null, 401);
}

$input = json_decode(file_get_contents('php://input'), true);
$currentPassword = $input['currentPassword'] ?? '';
$newPassword = $input['newPassword'] ?? '';

if ($currentPassword === '' || $newPassword === '') {
    jsonResponse(false, 'Contraseña actual y nueva son requeridas', null, 400);
}

if (strlen($newPassword) < 6) {
    jsonResponse(false, 'La nueva contraseña debe tener al menos 6 caracteres', null, 400);
}

$repo = new AuthUserRepository();
$user = $repo->findById((int)$idUsuario);

if (!$user) {
    jsonResponse(false, 'Usuario no encontrado', null, 404);
}

if (empty($user['PasswordHash']) || !password_verify($currentPassword, $user['PasswordHash'])) {
    jsonResponse(false, 'Contraseña actual incorrecta', null, 401);
}

$newHash = password_hash($newPassword, PASSWORD_BCRYPT);
$repo->updatePassword((int)$idUsuario, $newHash);

// Invalidar refresh token actual para forzar re-login
$repo->clearRefreshTokenByUser((int)$idUsuario);

jsonResponse(true, 'Contraseña cambiada correctamente', null, 200);