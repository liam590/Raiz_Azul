<?php
require_once __DIR__ . '/../config/auth.php';

class JwtHelper {
    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        $remainder = strlen($data) % 4;
        if ($remainder) {
            $data .= str_repeat('=', 4 - $remainder);
        }
        return base64_decode(strtr($data, '-_', '+/'));
    }

    public static function createAccessToken($user): string {
        $header = ['typ' => 'JWT', 'alg' => 'HS256'];
        $now = time();
        $payload = [
            'iss' => JWT_ISSUER,
            'aud' => JWT_AUDIENCE,
            'iat' => $now,
            'nbf' => $now,
            'exp' => $now + ACCESS_TOKEN_TTL,
            'sub' => $user['IdUsuario'] ?? $user['id'] ?? null,
            'username' => $user['Username'] ?? $user['username'] ?? null,
            'nombre' => $user['Nombre'] ?? $user['nombre_completo'] ?? $user['nombre'] ?? null,
            'rol' => $user['Rol'] ?? $user['rol'] ?? 'Productor',
            'id_finca' => $user['IdFinca'] ?? $user['id_finca'] ?? null
        ];
        $segments = [];
        $segments[] = self::base64UrlEncode(json_encode($header, JSON_UNESCAPED_UNICODE));
        $segments[] = self::base64UrlEncode(json_encode($payload, JSON_UNESCAPED_UNICODE));
        $signingInput = implode('.', $segments);
        $signature = hash_hmac('sha256', $signingInput, JWT_SECRET, true);
        $segments[] = self::base64UrlEncode($signature);
        return implode('.', $segments);
    }

    public static function createRefreshToken(): string {
        return bin2hex(random_bytes(64));
    }

    public static function validateAccessToken(string $token): ?array {
        $segments = explode('.', $token);
        if (count($segments) !== 3) {
            return null;
        }
        list($encodedHeader, $encodedPayload, $encodedSignature) = $segments;
        $header = json_decode(self::base64UrlDecode($encodedHeader), true);
        if (!$header || ($header['alg'] ?? '') !== 'HS256') {
            return null;
        }
        $signingInput = $encodedHeader . '.' . $encodedPayload;
        $expected = self::base64UrlEncode(hash_hmac('sha256', $signingInput, JWT_SECRET, true));
        if (!hash_equals($expected, $encodedSignature)) {
            return null;
        }
        $payload = json_decode(self::base64UrlDecode($encodedPayload), true);
        if (!$payload) {
            return null;
        }
        $now = time();
        if (isset($payload['exp']) && $payload['exp'] < $now) {
            return null;
        }
        if (isset($payload['nbf']) && $payload['nbf'] > $now) {
            return null;
        }
        if (isset($payload['iss']) && $payload['iss'] !== JWT_ISSUER) {
            return null;
        }
        if (isset($payload['aud']) && $payload['aud'] !== JWT_AUDIENCE) {
            return null;
        }
        return $payload;
    }
}
