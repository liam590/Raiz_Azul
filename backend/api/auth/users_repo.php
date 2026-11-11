<?php
require_once __DIR__ . '/../../config/database.php';

class AuthUserRepository {
    private $usersFile = null;
    private bool $fallback = false;
    private $conn = null;

    public function __construct() {
        $this->usersFile = __DIR__ . '/../../data_users.json';
        $database = new Database();
        $this->conn = $database->getConnection();
        if ($this->conn === null) {
            $this->fallback = true;
            $this->ensureFallbackUsers();
        }
    }

    private function ensureFallbackUsers(): void {
        if (!file_exists($this->usersFile)) {
            $hash = password_hash('crispin123', PASSWORD_BCRYPT);
            $data = [
                'usuarios' => [
                    [
                        'id' => 1,
                        'nombre' => 'Crispin',
                        'username' => 'Crispin',
                        'correo' => 'crispin@raizazul.local',
                        'rol' => 'Productor',
                        'id_finca' => 1,
                        'password_hash' => $hash,
                        'intentos_fallidos' => 0,
                        'bloqueado_hasta' => null,
                        'refresh_token_hash' => null,
                        'refresh_token_exp' => null
                    ],
                    [
                        'id' => 2,
                        'nombre' => 'Iris',
                        'username' => 'Iris',
                        'correo' => 'iris@raizazul.local',
                        'rol' => 'Productor',
                        'id_finca' => 1,
                        'password_hash' => $hash,
                        'intentos_fallidos' => 0,
                        'bloqueado_hasta' => null,
                        'refresh_token_hash' => null,
                        'refresh_token_exp' => null
                    ],
                    [
                        'id' => 3,
                        'nombre' => 'Cristin',
                        'username' => 'Cristin',
                        'correo' => 'cristin@raizazul.local',
                        'rol' => 'Productor',
                        'id_finca' => 1,
                        'password_hash' => $hash,
                        'intentos_fallidos' => 0,
                        'bloqueado_hasta' => null,
                        'refresh_token_hash' => null,
                        'refresh_token_exp' => null
                    ],
                    [
                        'id' => 4,
                        'nombre' => 'Liam',
                        'username' => 'Liam',
                        'correo' => 'liam@raizazul.local',
                        'rol' => 'Productor',
                        'id_finca' => 2,
                        'password_hash' => $hash,
                        'intentos_fallidos' => 0,
                        'bloqueado_hasta' => null,
                        'refresh_token_hash' => null,
                        'refresh_token_exp' => null
                    ]
                ]
            ];
            file_put_contents($this->usersFile, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        }
    }

    private function loadUsers(): array {
        if (!file_exists($this->usersFile)) {
            $this->ensureFallbackUsers();
        }
        $json = file_get_contents($this->usersFile);
        $data = json_decode($json, true);
        return $data['usuarios'] ?? [];
    }

    private function saveUsers(array $users): void {
        file_put_contents($this->usersFile, json_encode(['usuarios' => $users], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    }

    public function findByLogin(string $identificador): ?array {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('SELECT TOP 1 * FROM Usuarios WHERE (Username = ? OR Correo = ?) AND Activo = 1');
                $stmt->execute([$identificador, $identificador]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$row) return null;
                return [
                    'IdUsuario' => $row['IdUsuario'],
                    'Nombre' => $row['Nombre'],
                    'Username' => $row['Username'] ?? $row['Nombre'],
                    'Correo' => $row['Correo'] ?? null,
                    'Rol' => $row['Rol'] ?? 'Productor',
                    'IdFinca' => $row['IdFinca'] ?? null,
                    'PasswordHash' => $row['PasswordHash'] ?? null,
                    'IntentosFallidos' => $row['IntentosFallidos'] ?? 0,
                    'BloqueadoHasta' => $row['BloqueadoHasta'] ?? null,
                    'RefreshTokenHash' => $row['RefreshTokenHash'] ?? null,
                    'RefreshTokenExp' => $row['RefreshTokenExp'] ?? null
                ];
            } catch (Exception $e) {
                $this->fallback = true;
                $this->ensureFallbackUsers();
            }
        }
        $users = $this->loadUsers();
        $needle = strtolower($identificador);
        foreach ($users as $user) {
            if (strtolower($user['username'] ?? '') === $needle || strtolower($user['correo'] ?? '') === $needle) {
                return [
                    'IdUsuario' => $user['id'],
                    'Nombre' => $user['nombre'],
                    'Username' => $user['username'],
                    'Correo' => $user['correo'] ?? null,
                    'Rol' => $user['rol'] ?? 'Productor',
                    'IdFinca' => $user['id_finca'] ?? null,
                    'PasswordHash' => $user['password_hash'] ?? null,
                    'IntentosFallidos' => $user['intentos_fallidos'] ?? 0,
                    'BloqueadoHasta' => $user['bloqueado_hasta'] ?? null,
                    'RefreshTokenHash' => $user['refresh_token_hash'] ?? null,
                    'RefreshTokenExp' => $user['refresh_token_exp'] ?? null
                ];
            }
        }
        return null;
    }

    public function registerFailed(int $idUsuario, int $intentos): void {
        if (!$this->fallback) {
            try {
                if ($intentos >= 5) {
                    $bloqueadoHasta = date('Y-m-d H:i:s', time() + 900);
                    $stmt = $this->conn->prepare('UPDATE Usuarios SET IntentosFallidos = ?, BloqueadoHasta = ? WHERE IdUsuario = ?');
                    $stmt->execute([$intentos, $bloqueadoHasta, $idUsuario]);
                    return;
                }
                $stmt = $this->conn->prepare('UPDATE Usuarios SET IntentosFallidos = ? WHERE IdUsuario = ?');
                $stmt->execute([$intentos, $idUsuario]);
                return;
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? null) == $idUsuario) {
                $users[$index]['intentos_fallidos'] = $intentos;
                if ($intentos >= 5) {
                    $users[$index]['bloqueado_hasta'] = date('c', time() + 900);
                }
                break;
            }
        }
        $this->saveUsers($users);
    }

    public function registerSuccess(int $idUsuario): void {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('UPDATE Usuarios SET IntentosFallidos = 0, BloqueadoHasta = NULL, UltimoLogin = GETDATE() WHERE IdUsuario = ?');
                $stmt->execute([$idUsuario]);
                return;
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? null) == $idUsuario) {
                $users[$index]['intentos_fallidos'] = 0;
                $users[$index]['bloqueado_hasta'] = null;
                break;
            }
        }
        $this->saveUsers($users);
    }

    public function saveRefreshToken(int $idUsuario, string $hash, string $exp): void {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('UPDATE Usuarios SET RefreshTokenHash = ?, RefreshTokenExp = ? WHERE IdUsuario = ?');
                $stmt->execute([$hash, $exp, $idUsuario]);
                return;
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? null) == $idUsuario) {
                $users[$index]['refresh_token_hash'] = $hash;
                $users[$index]['refresh_token_exp'] = $exp;
                break;
            }
        }
        $this->saveUsers($users);
    }

    public function findByRefreshHash(string $hash): ?array {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('SELECT * FROM Usuarios WHERE RefreshTokenHash = ? AND (RefreshTokenExp IS NULL OR RefreshTokenExp > GETDATE()) AND Activo = 1');
                $stmt->execute([$hash]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$row) return null;
                return [
                    'IdUsuario' => $row['IdUsuario'],
                    'Nombre' => $row['Nombre'],
                    'Username' => $row['Username'] ?? $row['Nombre'],
                    'Correo' => $row['Correo'] ?? null,
                    'Rol' => $row['Rol'] ?? 'Productor',
                    'IdFinca' => $row['IdFinca'] ?? null
                ];
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $user) {
            if (($user['refresh_token_hash'] ?? null) === $hash) {
                $exp = $user['refresh_token_exp'] ?? null;
                if ($exp) {
                    $expTs = strtotime($exp);
                    if ($expTs && $expTs <= time()) {
                        continue;
                    }
                }
                return [
                    'IdUsuario' => $user['id'],
                    'Nombre' => $user['nombre'],
                    'Username' => $user['username'],
                    'Correo' => $user['correo'] ?? null,
                    'Rol' => $user['rol'] ?? 'Productor',
                    'IdFinca' => $user['id_finca'] ?? null
                ];
            }
        }
        return null;
    }

    public function clearRefreshTokenByHash(string $hash): void {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('UPDATE Usuarios SET RefreshTokenHash = NULL, RefreshTokenExp = NULL WHERE RefreshTokenHash = ?');
                $stmt->execute([$hash]);
                return;
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $index => $user) {
            if (($user['refresh_token_hash'] ?? null) === $hash) {
                $users[$index]['refresh_token_hash'] = null;
                $users[$index]['refresh_token_exp'] = null;
                break;
            }
        }
        $this->saveUsers($users);
    }

    public function findById(int $idUsuario): ?array {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('SELECT * FROM Usuarios WHERE IdUsuario = ? AND Activo = 1');
                $stmt->execute([$idUsuario]);
                $row = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$row) return null;
                return [
                    'IdUsuario' => $row['IdUsuario'],
                    'Nombre' => $row['Nombre'],
                    'Username' => $row['Username'] ?? $row['Nombre'],
                    'Correo' => $row['Correo'] ?? null,
                    'Rol' => $row['Rol'] ?? 'Productor',
                    'IdFinca' => $row['IdFinca'] ?? null,
                    'PasswordHash' => $row['PasswordHash'] ?? null,
                    'IntentosFallidos' => $row['IntentosFallidos'] ?? 0,
                    'BloqueadoHasta' => $row['BloqueadoHasta'] ?? null,
                    'RefreshTokenHash' => $row['RefreshTokenHash'] ?? null,
                    'RefreshTokenExp' => $row['RefreshTokenExp'] ?? null
                ];
            } catch (Exception $e) {
                $this->fallback = true;
                $this->ensureFallbackUsers();
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $user) {
            if (($user['id'] ?? null) == $idUsuario) {
                return [
                    'IdUsuario' => $user['id'],
                    'Nombre' => $user['nombre'],
                    'Username' => $user['username'],
                    'Correo' => $user['correo'] ?? null,
                    'Rol' => $user['rol'] ?? 'Productor',
                    'IdFinca' => $user['id_finca'] ?? null,
                    'PasswordHash' => $user['password_hash'] ?? null,
                    'IntentosFallidos' => $user['intentos_fallidos'] ?? 0,
                    'BloqueadoHasta' => $user['bloqueado_hasta'] ?? null,
                    'RefreshTokenHash' => $user['refresh_token_hash'] ?? null,
                    'RefreshTokenExp' => $user['refresh_token_exp'] ?? null
                ];
            }
        }
        return null;
    }

    public function updatePassword(int $idUsuario, string $newHash): void {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('UPDATE Usuarios SET PasswordHash = ? WHERE IdUsuario = ?');
                $stmt->execute([$newHash, $idUsuario]);
                return;
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? null) == $idUsuario) {
                $users[$index]['password_hash'] = $newHash;
                break;
            }
        }
        $this->saveUsers($users);
    }

    public function clearRefreshTokenByUser(int $idUsuario): void {
        if (!$this->fallback) {
            try {
                $stmt = $this->conn->prepare('UPDATE Usuarios SET RefreshTokenHash = NULL, RefreshTokenExp = NULL WHERE IdUsuario = ?');
                $stmt->execute([$idUsuario]);
                return;
            } catch (Exception $e) {
                $this->fallback = true;
            }
        }
        $users = $this->loadUsers();
        foreach ($users as $index => $user) {
            if (($user['id'] ?? null) == $idUsuario) {
                $users[$index]['refresh_token_hash'] = null;
                $users[$index]['refresh_token_exp'] = null;
                break;
            }
        }
        $this->saveUsers($users);
    }
}
