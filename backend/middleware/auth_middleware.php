<?php
require_once __DIR__ . '/../helpers/jwt_helper.php';
require_once __DIR__ . '/../helpers/response.php';

function requireAuth() {
    $headers = [];
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        if ($headers) {
            $headers = array_change_key_case($headers, CASE_LOWER);
        }
    }
    if (empty($headers)) {
        foreach ($_SERVER as $key => $value) {
            if (strpos($key, 'HTTP_') === 0) {
                $name = strtolower(str_replace('_', '-', substr($key, 5)));
                $headers[$name] = $value;
            }
        }
    }

    $authorization = $headers['authorization'] ?? '';
    $matches = [];
    if (!preg_match('/Bearer\s+(\S+)/i', $authorization, $matches)) {
        jsonResponse(false, 'Token no proporcionado', null, 401);
    }

    $token = $matches[1];
    $payload = JwtHelper::validateAccessToken($token);

    if (!$payload) {
        jsonResponse(false, 'Token inválido o expirado', null, 401);
    }

    return $payload;
}
