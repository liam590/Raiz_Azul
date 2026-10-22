@echo off
title Servidor Backend - Raiz Azul
echo ========================================================
echo   Iniciando API Backend PHP para Raiz Azul
echo   Puerto: 8000
echo   URL: http://localhost:8000
echo ========================================================
echo.
cd /d "%~dp0backend"
php -S 0.0.0.0:8000 router.php
pause
