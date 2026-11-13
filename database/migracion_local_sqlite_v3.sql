-- ========================================================
-- PROYECTO: Raíz Azul
-- MOTOR: SQLite (base LOCAL de la app de escritorio)
-- ARCHIVO: %APPDATA%\com.raizazul\raiz_azul\raiz_azul.db
-- MIGRACIÓN: v2 -> v3
-- ========================================================
-- NO ejecutar con sqlcmd: esto no es SQL Server.
-- La app aplica esta migración sola al abrir (LocalDatabase._onUpgrade).
-- Este script sirve para replicarla a mano en otra máquina.
--
-- Ejecutar UNA sola vez (cmd.exe):
--   sqlite3 "%APPDATA%\com.raizazul\raiz_azul\raiz_azul.db" < database\migracion_local_sqlite_v3.sql
-- O en PowerShell:
--   Get-Content database\migracion_local_sqlite_v3.sql | sqlite3 "$env:APPDATA\com.raizazul\raiz_azul\raiz_azul.db"
--
-- Si la base ya está en v3, el ALTER fallará con
-- "duplicate column name: destino" y no hay nada que hacer.
-- Verifica antes con:  PRAGMA user_version;
-- ========================================================

BEGIN TRANSACTION;

-- 1) El servidor envía el destino del registro ('Parcela' | 'Finca').
ALTER TABLE registros ADD COLUMN destino TEXT;

-- 2) Marcar la versión del esquema local.
PRAGMA user_version = 3;

COMMIT;

-- ========================================================
-- VERIFICACIÓN (debe devolver 1 y 3)
-- ========================================================
SELECT COUNT(*) AS tiene_destino
FROM pragma_table_info('registros')
WHERE name = 'destino';

PRAGMA user_version;
