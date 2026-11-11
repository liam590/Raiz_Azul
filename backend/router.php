<?php
// backend/router.php
// Enrutador para el servidor de desarrollo integrado de PHP

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// Si el archivo físico existe, servirlo directamente
if ($uri !== '/' && file_exists(__DIR__ . $uri)) {
    return false;
}

// Rutas API amigables
$routes = [
    '/api/status' => '/api/status.php',
    '/api/dashboard' => '/api/dashboard.php',
    '/api/parcelas' => '/api/parcelas.php',
    '/api/registros' => '/api/registros.php',
    '/api/calendario' => '/api/calendario.php',
    '/api/reportes' => '/api/reportes.php',
    '/api/catalogos' => '/api/catalogos.php',
    // Auth
    '/api/auth/login' => '/api/auth/login.php',
    '/api/auth/me' => '/api/auth/me.php',
    '/api/auth/refresh' => '/api/auth/refresh.php',
    '/api/auth/logout' => '/api/auth/logout.php'
];

if (isset($routes[$uri])) {
    require __DIR__ . $routes[$uri];
    exit;
}

// Intentar cargar en api/auth/
$authFile = __DIR__ . '/api/auth/' . basename($uri) . '.php';
if (file_exists($authFile)) {
    require $authFile;
    exit;
}

// Por defecto, intentar cargar el archivo en api/ si coincide
$apiFile = __DIR__ . '/api/' . basename($uri) . '.php';
if (file_exists($apiFile)) {
    require $apiFile;
    exit;
}

http_response_code(404);
echo json_encode(['status' => 'error', 'message' => 'Ruta no encontrada']);
