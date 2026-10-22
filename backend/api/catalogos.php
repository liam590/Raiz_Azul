<?php
// backend/api/catalogos.php

require_once __DIR__ . '/../config/cors.php';
require_once __DIR__ . '/../services/AgronomiaService.php';

$cultivos = array_keys(AgronomiaService::$CROPS);
$zonas = ['Matagalpa', 'Jinotega', 'Chontales', 'Boaco', 'Estelí', 'Nueva Segovia', 'Otra'];
$labores = ['Deshierbe', 'Aporque', 'Poda', 'Control de plagas', 'Control de enfermedades', 'Cosecha', 'Otra'];
$insumos = ['Urea 46%', 'Fórmula 12-30-10', 'Fórmula 15-15-15', 'Abono orgánico', 'Fungicida', 'Insecticida'];

echo json_encode([
    'status' => 'success',
    'data' => [
        'cultivos' => $cultivos,
        'cultivosDetalle' => AgronomiaService::$CROPS,
        'zonas' => $zonas,
        'labores' => $labores,
        'insumos' => $insumos
    ]
], JSON_UNESCAPED_UNICODE);
