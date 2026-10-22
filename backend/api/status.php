<?php
// backend/api/status.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../models/DataStore.php';

$store = new DataStore();
$status = Database::getDriverStatus();

echo json_encode([
    'status' => 'online',
    'app' => 'Raíz Azul API',
    'version' => '1.0.0',
    'sql_server_connected' => $store->isSqlServerConnected(),
    'active_driver' => $store->getDriverName(),
    'php_environment' => $status,
    'instructions' => $store->isSqlServerConnected() 
        ? 'Conectado a Microsoft SQL Server correctamente.' 
        : 'Usando almacén local para desarrollo. Para conectar a SQL Server en PHP, asegúrate de habilitar extension=php_pdo_sqlsrv_83_nts_x64.dll o extension=pdo_sqlsrv en tu archivo php.ini y configurar tus credenciales en backend/config/database.php'
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
