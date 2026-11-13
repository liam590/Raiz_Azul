<?php
// backend/config/database.php

class Database {
    private $host = "localhost";
    private $db_name = "RaizAzul";
    private $username = "sa";
    private $password = "TuPassword123*"; // Configurar con tus credenciales
    private $port = "1433";
    
    public $conn = null;
    public $driverUsed = "none";
    public $fallbackActive = false;

    public function getConnection() {
        $this->conn = null;

        // 1. Intentar con PDO_SQLSRV
        if (extension_loaded('pdo_sqlsrv')) {
            try {
                $dsn = "sqlsrv:Server={$this->host},{$this->port};Database={$this->db_name};TrustServerCertificate=true";
                $this->conn = new PDO($dsn, $this->username, $this->password, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
                ]);
                $this->driverUsed = "pdo_sqlsrv";
                return $this->conn;
            } catch (PDOException $e) {
                error_log("Fallo conexion pdo_sqlsrv: " . $e->getMessage());
            }
        }

        // 2. Intentar con ODBC si está disponible
        if (extension_loaded('pdo_odbc')) {
            try {
                $dsn = "odbc:Driver={ODBC Driver 17 for SQL Server};Server={$this->host},{$this->port};Database={$this->db_name};Uid={$this->username};Pwd={$this->password};";
                $this->conn = new PDO($dsn, $this->username, $this->password, [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
                ]);
                $this->driverUsed = "pdo_odbc";
                return $this->conn;
            } catch (PDOException $e) {
                error_log("Fallo conexion pdo_odbc: " . $e->getMessage());
            }
        }

        // 3. Fallback Local (Almacén JSON) para desarrollo inmediato si el driver de SQL Server aún no está configurado en php.ini
        $this->fallbackActive = true;
        $this->driverUsed = "local_json_fallback";
        return null;
    }

    public static function getDriverStatus() {
        return [
            'pdo_sqlsrv' => extension_loaded('pdo_sqlsrv'),
            'sqlsrv' => extension_loaded('sqlsrv'),
            'pdo_odbc' => extension_loaded('pdo_odbc'),
            'pdo' => extension_loaded('pdo'),
            'php_version' => PHP_VERSION,
            'os' => PHP_OS
        ];
    }
}
