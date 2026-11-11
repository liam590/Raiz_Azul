<?php
require_once __DIR__ . '/../../config/cors.php';
require_once __DIR__ . '/../../helpers/response.php';
require_once __DIR__ . '/../../helpers/jwt_helper.php';
require_once __DIR__ . '/../../config/auth.php';
require_once __DIR__ . '/users_repo.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonResponse(false, 'Método no permitido', null, 405);
}

$input = json_decode(file_get_contents('php://input'), true);
$identificador = trim($input['identificador'] ?? $input['username'] ?? $input['correo'] ?? '');
$password = $input['password'] ?? '';
$remember = $input['remember'] ?? true;

if ($identificador === '' || $password === '') {
    jsonResponse(false, 'Ingresa tu usuario o correo y contraseña', null, 400);
}

$repo = new AuthUserRepository();
$user = $repo->findByLogin($identificador);

if (!$user) {
    jsonResponse(false, 'Usuario o contraseña incorrectos', null, 401);
}

if (!empty($user['BloqueadoHasta'])) {
    $bloq = strtotime($user['BloqueadoHasta']);
    if ($bloq && $bloq > time()) {
        jsonResponse(false, 'Cuenta temporalmente bloqueada. Intenta más tarde.', null, 423);
    }
}

if (empty($user['PasswordHash']) || !password_verify($password, $user['PasswordHash'])) {
    $intentos = (($user['IntentosFallidos'] ?? 0)) + 1;
    $repo->registerFailed((int)$user['IdUsuario'], $intentos);
    if ($intentos >= 5) {
        jsonResponse(false, 'Demasiados intentos fallidos. Cuenta bloqueada por 15 minutos.', null, 429);
    }
    jsonResponse(false, 'Usuario o contraseña incorrectos', null, 401);
}

$repo->registerSuccess((int)$user['IdUsuario']);

$accessToken = JwtHelper::createAccessToken($user);
$refreshToken = JwtHelper::createRefreshToken();
$refreshHash = hash('sha256', $refreshToken);

// Si remember=true -> 7 días, si false -> 1 día (86400 seg)
$refreshTtl = $remember ? REFRESH_TOKEN_TTL : 86400;
$refreshExp = date('Y-m-d H:i:s', time() + $refreshTtl);
$repo->saveRefreshToken((int)$user['IdUsuario'], $refreshHash, $refreshExp);

jsonResponse(true, 'Inicio de sesión exitoso', [
    'accessToken' => $accessToken,
    'refreshToken' => $refreshToken,
    'expiresIn' => ACCESS_TOKEN_TTL,
    'remember' => $remember,
    'user' => [
        'id' => $user['IdUsuario'],
        'nombre_completo' => $user['Nombre'],
        'username' => $user['Username'],
        'correo' => $user['Correo'],
        'rol' => $user['Rol'],
        'id_finca' => $user['IdFinca']
    ]
], 200);
