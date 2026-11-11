-- ========================================================
-- PROYECTO: Raíz Azul - Manejo eficiente del agua y cultivos
-- MOTOR: Microsoft SQL Server (2016 o superior / Azure SQL)
-- UNIVERSIDAD NACIONAL HÉROES SAN JOSÉ DE LAS MULAS
-- ========================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'RaizAzulDB')
BEGIN
    CREATE DATABASE RaizAzulDB;
END
GO

USE RaizAzulDB;
GO

-- 1. TABLA: Usuarios / Miembros del Equipo
IF OBJECT_ID('dbo.Usuarios', 'U') IS NULL
BEGIN
    CREATE TABLE Usuarios (
        IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
        Nombre NVARCHAR(100) NOT NULL,
        Telefono NVARCHAR(20) NULL,
        Correo NVARCHAR(120) NULL,
        Rol NVARCHAR(50) DEFAULT 'Productor',
        Activo BIT DEFAULT 1,
        FechaRegistro DATETIME2 DEFAULT SYSDATETIME()
    );
END
GO

-- 2. TABLA: Zonas Agrícolas
IF OBJECT_ID('dbo.Zonas', 'U') IS NULL
BEGIN
    CREATE TABLE Zonas (
        IdZona INT IDENTITY(1,1) PRIMARY KEY,
        NombreZona NVARCHAR(100) NOT NULL UNIQUE
    );
END
GO

-- 3. TABLA: Fincas
IF OBJECT_ID('dbo.Fincas', 'U') IS NULL
BEGIN
    CREATE TABLE Fincas (
        IdFinca INT IDENTITY(1,1) PRIMARY KEY,
        IdUsuarioPropietario INT NULL,
        NombreFinca NVARCHAR(100) NOT NULL,
        IdZona INT NOT NULL,
        FechaRegistro DATETIME2 DEFAULT SYSDATETIME(),
        CONSTRAINT FK_Fincas_Usuarios FOREIGN KEY (IdUsuarioPropietario) REFERENCES Usuarios(IdUsuario),
        CONSTRAINT FK_Fincas_Zonas FOREIGN KEY (IdZona) REFERENCES Zonas(IdZona)
    );
END
GO

-- 4. TABLA: Cultivos de Referencia (Parámetros Agronómicos)
IF OBJECT_ID('dbo.Cultivos', 'U') IS NULL
BEGIN
    CREATE TABLE Cultivos (
        IdCultivo INT IDENTITY(1,1) PRIMARY KEY,
        NombreCultivo NVARCHAR(80) NOT NULL UNIQUE,
        CicloDias INT NOT NULL,
        FrecuenciaRiegoDias INT NOT NULL,
        ConsumoAguaRefLitrosMz FLOAT NOT NULL
    );
END
GO

-- 5. TABLA: Ventanas de Fertilización por Cultivo
IF OBJECT_ID('dbo.CultivoFertilizaciones', 'U') IS NULL
BEGIN
    CREATE TABLE CultivoFertilizaciones (
        IdFertilizacion INT IDENTITY(1,1) PRIMARY KEY,
        IdCultivo INT NOT NULL,
        DiaCiclo INT NOT NULL,
        Descripcion NVARCHAR(150) NOT NULL,
        CONSTRAINT FK_CultivoFert_Cultivos FOREIGN KEY (IdCultivo) REFERENCES Cultivos(IdCultivo) ON DELETE CASCADE
    );
END
GO

-- 6. TABLA: Parcelas / Lotes
IF OBJECT_ID('dbo.Parcelas', 'U') IS NULL
BEGIN
    CREATE TABLE Parcelas (
        IdParcela INT IDENTITY(1,1) PRIMARY KEY,
        IdFinca INT NOT NULL,
        NombreParcela NVARCHAR(100) NOT NULL,
        IdCultivo INT NOT NULL,
        AreaManzanas DECIMAL(8,2) NOT NULL CHECK (AreaManzanas > 0),
        FechaSiembra DATE NOT NULL,
        Cosechada BIT DEFAULT 0,
        FechaCosecha DATE NULL,
        Activa BIT DEFAULT 1,
        FechaCreacion DATETIME2 DEFAULT SYSDATETIME(),
        CONSTRAINT FK_Parcelas_Fincas FOREIGN KEY (IdFinca) REFERENCES Fincas(IdFinca) ON DELETE CASCADE,
        CONSTRAINT FK_Parcelas_Cultivos FOREIGN KEY (IdCultivo) REFERENCES Cultivos(IdCultivo)
    );
END
GO

-- 7. TABLA: Tipos de Registro de Campo
IF OBJECT_ID('dbo.TiposRegistro', 'U') IS NULL
BEGIN
    CREATE TABLE TiposRegistro (
        IdTipoRegistro INT IDENTITY(1,1) PRIMARY KEY,
        Codigo NVARCHAR(20) NOT NULL UNIQUE,
        Nombre NVARCHAR(50) NOT NULL
    );
END
GO

-- 8. TABLAS DE CATÁLOGO: Insumos y Labores
IF OBJECT_ID('dbo.Insumos', 'U') IS NULL
BEGIN
    CREATE TABLE Insumos (
        IdInsumo INT IDENTITY(1,1) PRIMARY KEY,
        NombreInsumo NVARCHAR(100) NOT NULL UNIQUE
    );
END
GO

IF OBJECT_ID('dbo.Labores', 'U') IS NULL
BEGIN
    CREATE TABLE Labores (
        IdLabor INT IDENTITY(1,1) PRIMARY KEY,
        NombreLabor NVARCHAR(100) NOT NULL UNIQUE
    );
END
GO

-- 9. TABLA: Bitácora de Registros de Campo
IF OBJECT_ID('dbo.RegistrosCampo', 'U') IS NULL
BEGIN
    CREATE TABLE RegistrosCampo (
        IdRegistro BIGINT IDENTITY(1,1) PRIMARY KEY,
        IdFinca INT NOT NULL,
        IdParcela INT NULL,
        IdTipoRegistro INT NOT NULL,
        Fecha DATE NOT NULL,
        Valor DECIMAL(12,2) DEFAULT 0,
        Detalle NVARCHAR(120) NULL,
        Nota NVARCHAR(250) NULL,
        MetodoRiego NVARCHAR(40) NULL,
        DuracionMinutos INT NULL,
        GrupoRiego NVARCHAR(40) NULL,
        IdUsuario INT NULL,
        NombreAutor NVARCHAR(100) NOT NULL,
        FechaHoraCreacion DATETIME2 DEFAULT SYSDATETIME(),
        CONSTRAINT FK_Reg_Fincas FOREIGN KEY (IdFinca) REFERENCES Fincas(IdFinca),
        CONSTRAINT FK_Reg_Parcelas FOREIGN KEY (IdParcela) REFERENCES Parcelas(IdParcela) ON DELETE SET NULL,
        CONSTRAINT FK_Reg_Tipos FOREIGN KEY (IdTipoRegistro) REFERENCES TiposRegistro(IdTipoRegistro),
        CONSTRAINT FK_Reg_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
    );
END
GO

-- Migración: riego en varias fechas, método y duración
-- (idempotente para bases de datos ya creadas)
IF COL_LENGTH('dbo.RegistrosCampo', 'MetodoRiego') IS NULL
    ALTER TABLE RegistrosCampo ADD MetodoRiego NVARCHAR(40) NULL;
GO

IF COL_LENGTH('dbo.RegistrosCampo', 'DuracionMinutos') IS NULL
    ALTER TABLE RegistrosCampo ADD DuracionMinutos INT NULL;
GO

IF COL_LENGTH('dbo.RegistrosCampo', 'GrupoRiego') IS NULL
    ALTER TABLE RegistrosCampo ADD GrupoRiego NVARCHAR(40) NULL;
GO

-- Índices de consulta rápida
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Registros_Parcela_Fecha')
    CREATE INDEX IX_Registros_Parcela_Fecha ON RegistrosCampo(IdParcela, Fecha);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Registros_Finca_Fecha')
    CREATE INDEX IX_Registros_Finca_Fecha ON RegistrosCampo(IdFinca, Fecha);
GO

-- ========================================================
-- SEEDS / DATOS INICIALES
-- ========================================================
IF NOT EXISTS (SELECT 1 FROM Zonas)
BEGIN
    INSERT INTO Zonas (NombreZona) VALUES 
    ('Matagalpa'), ('Jinotega'), ('Chontales'), ('Boaco'), ('Estelí'), ('Nueva Segovia'), ('Otra');
END
GO

IF NOT EXISTS (SELECT 1 FROM TiposRegistro)
BEGIN
    INSERT INTO TiposRegistro (Codigo, Nombre) VALUES 
    ('riego', 'Riego'),
    ('lluvia', 'Lluvia'),
    ('insumo', 'Insumo'),
    ('labor', 'Labor'),
    ('cosecha', 'Cosecha');
END
GO

IF NOT EXISTS (SELECT 1 FROM Cultivos)
BEGIN
    INSERT INTO Cultivos (NombreCultivo, CicloDias, FrecuenciaRiegoDias, ConsumoAguaRefLitrosMz) VALUES 
    ('Tomate', 100, 3, 4500),
    ('Chile', 110, 3, 4000),
    ('Repollo', 90, 3, 4000),
    ('Maíz', 120, 6, 6000),
    ('Frijol', 75, 6, 4000);

    INSERT INTO CultivoFertilizaciones (IdCultivo, DiaCiclo, Descripcion)
    SELECT IdCultivo, 15, '1.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Tomate' UNION ALL
    SELECT IdCultivo, 35, '2.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Tomate' UNION ALL
    SELECT IdCultivo, 55, '3.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Tomate' UNION ALL
    SELECT IdCultivo, 15, '1.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Chile' UNION ALL
    SELECT IdCultivo, 40, '2.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Chile' UNION ALL
    SELECT IdCultivo, 14, '1.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Repollo' UNION ALL
    SELECT IdCultivo, 35, '2.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Repollo' UNION ALL
    SELECT IdCultivo, 15, '1.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Maíz' UNION ALL
    SELECT IdCultivo, 35, '2.ª fertilización' FROM Cultivos WHERE NombreCultivo = 'Maíz' UNION ALL
    SELECT IdCultivo, 12, 'Fertilización de arranque' FROM Cultivos WHERE NombreCultivo = 'Frijol' UNION ALL
    SELECT IdCultivo, 30, 'Refuerzo de fertilización' FROM Cultivos WHERE NombreCultivo = 'Frijol';
END
GO

IF NOT EXISTS (SELECT 1 FROM Insumos)
BEGIN
    INSERT INTO Insumos (NombreInsumo) VALUES 
    ('Urea 46%'), ('Fórmula 12-30-10'), ('Fórmula 15-15-15'), ('Abono orgánico'), ('Fungicida'), ('Insecticida');
END
GO

IF NOT EXISTS (SELECT 1 FROM Labores)
BEGIN
    INSERT INTO Labores (NombreLabor) VALUES 
    ('Deshierbe'), ('Aporque'), ('Poda'), ('Control de plagas'), ('Control de enfermedades'), ('Cosecha'), ('Otra');
END
GO

IF NOT EXISTS (SELECT 1 FROM Usuarios)
BEGIN
    INSERT INTO Usuarios (Nombre, Rol) VALUES ('Iris', 'Productor'), ('Cristin', 'Productor'), ('Liam', 'Productor');
END
GO

-- Fincas de prueba según prototipo
IF NOT EXISTS (SELECT 1 FROM Fincas)
BEGIN
    DECLARE @IdZonaMatagalpa INT = (SELECT TOP 1 IdZona FROM Zonas WHERE NombreZona = 'Matagalpa');
    DECLARE @IdZonaJinotega INT = (SELECT TOP 1 IdZona FROM Zonas WHERE NombreZona = 'Jinotega');
    DECLARE @IdUser INT = (SELECT TOP 1 IdUsuario FROM Usuarios);

    INSERT INTO Fincas (NombreFinca, IdZona, IdUsuarioPropietario) VALUES 
    ('La Esperanza', @IdZonaMatagalpa, @IdUser),
    ('El Mirador', @IdZonaJinotega, @IdUser);
END
GO

-- Parcelas de prueba según prototipo
IF NOT EXISTS (SELECT 1 FROM Parcelas)
BEGIN
    DECLARE @IdFincaEsp INT = (SELECT TOP 1 IdFinca FROM Fincas WHERE NombreFinca = 'La Esperanza');
    DECLARE @IdFincaMir INT = (SELECT TOP 1 IdFinca FROM Fincas WHERE NombreFinca = 'El Mirador');
    DECLARE @IdTomate INT = (SELECT TOP 1 IdCultivo FROM Cultivos WHERE NombreCultivo = 'Tomate');
    DECLARE @IdFrijol INT = (SELECT TOP 1 IdCultivo FROM Cultivos WHERE NombreCultivo = 'Frijol');
    DECLARE @IdMaiz INT = (SELECT TOP 1 IdCultivo FROM Cultivos WHERE NombreCultivo = 'Maíz');
    DECLARE @IdRepollo INT = (SELECT TOP 1 IdCultivo FROM Cultivos WHERE NombreCultivo = 'Repollo');

    INSERT INTO Parcelas (IdFinca, NombreParcela, IdCultivo, AreaManzanas, FechaSiembra) VALUES 
    (@IdFincaEsp, 'Lote Alto', @IdTomate, 1.5, DATEADD(DAY, -52, CAST(GETDATE() AS DATE))),
    (@IdFincaEsp, 'Vega del Río', @IdFrijol, 2.0, DATEADD(DAY, -38, CAST(GETDATE() AS DATE))),
    (@IdFincaMir, 'Terraza Norte', @IdMaiz, 3.0, DATEADD(DAY, -96, CAST(GETDATE() AS DATE))),
    (@IdFincaMir, 'Ladera Sur', @IdRepollo, 1.0, DATEADD(DAY, -84, CAST(GETDATE() AS DATE)));
END
GO

-- ========================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ========================================================
CREATE OR ALTER PROCEDURE sp_RegistrarParcela
    @IdFinca INT,
    @NombreParcela NVARCHAR(100),
    @IdCultivo INT,
    @AreaManzanas DECIMAL(8,2),
    @FechaSiembra DATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Parcelas (IdFinca, NombreParcela, IdCultivo, AreaManzanas, FechaSiembra)
    VALUES (@IdFinca, @NombreParcela, @IdCultivo, @AreaManzanas, @FechaSiembra);

    SELECT SCOPE_IDENTITY() AS IdParcelaGenerada;
END;
GO

CREATE OR ALTER PROCEDURE sp_GuardarRegistroCampo
    @IdFinca INT,
    @IdParcela INT = NULL,
    @CodigoTipo NVARCHAR(20),
    @Fecha DATE,
    @Valor DECIMAL(12,2) = 0,
    @Detalle NVARCHAR(120) = NULL,
    @Nota NVARCHAR(250) = NULL,
    @IdUsuario INT = NULL,
    @NombreAutor NVARCHAR(100),
    @MetodoRiego NVARCHAR(40) = NULL,
    @DuracionMinutos INT = NULL,
    @GrupoRiego NVARCHAR(40) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdTipoRegistro INT;
    SELECT @IdTipoRegistro = IdTipoRegistro FROM TiposRegistro WHERE Codigo = @CodigoTipo;

    IF @IdTipoRegistro IS NULL
    BEGIN
        RAISERROR('Tipo de registro no válido.', 16, 1);
        RETURN;
    END

    IF @CodigoTipo = 'labor' AND @Detalle = 'Cosecha' AND @IdParcela IS NOT NULL
    BEGIN
        UPDATE Parcelas 
        SET Cosechada = 1, FechaCosecha = @Fecha 
        WHERE IdParcela = @IdParcela;
    END

    INSERT INTO RegistrosCampo (
        IdFinca, IdParcela, IdTipoRegistro, Fecha, Valor, Detalle, Nota,
        MetodoRiego, DuracionMinutos, GrupoRiego, IdUsuario, NombreAutor
    )
    VALUES (
        @IdFinca, @IdParcela, @IdTipoRegistro, @Fecha, @Valor, @Detalle, @Nota,
        @MetodoRiego, @DuracionMinutos, @GrupoRiego, @IdUsuario, @NombreAutor
    );

    SELECT SCOPE_IDENTITY() AS IdRegistroGenerado;
END;
GO

CREATE OR ALTER PROCEDURE sp_ListarParcelas
    @IdFinca INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.IdParcela,
        p.NombreParcela,
        p.IdFinca,
        f.NombreFinca,
        z.NombreZona,
        p.IdCultivo,
        c.NombreCultivo,
        p.AreaManzanas,
        p.FechaSiembra,
        p.Cosechada,
        p.FechaCosecha,
        c.CicloDias,
        c.FrecuenciaRiegoDias,
        DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) AS DiasDesdeSiembra,
        DATEADD(DAY, c.CicloDias, p.FechaSiembra) AS FechaEstimadaCosecha,
        CASE 
            WHEN DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) < 0 THEN 0
            WHEN DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) >= c.CicloDias THEN 100
            ELSE ROUND((CAST(DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) AS FLOAT) / c.CicloDias) * 100, 1)
        END AS PorcentajeCiclo,
        CASE 
            WHEN (CAST(DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) AS FLOAT) / c.CicloDias) < 0.15 THEN 'Establecimiento'
            WHEN (CAST(DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) AS FLOAT) / c.CicloDias) < 0.50 THEN 'Desarrollo'
            WHEN (CAST(DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) AS FLOAT) / c.CicloDias) < 0.80 THEN 'Floración y llenado'
            WHEN (CAST(DATEDIFF(DAY, p.FechaSiembra, CAST(GETDATE() AS DATE)) AS FLOAT) / c.CicloDias) < 1.00 THEN 'Maduración'
            ELSE 'Punto de cosecha'
        END AS EtapaActual
    FROM Parcelas p
    INNER JOIN Fincas f ON p.IdFinca = f.IdFinca
    INNER JOIN Zonas z ON f.IdZona = z.IdZona
    INNER JOIN Cultivos c ON p.IdCultivo = c.IdCultivo
    WHERE p.Activa = 1
      AND (@IdFinca IS NULL OR p.IdFinca = @IdFinca)
    ORDER BY p.IdParcela DESC;
END;
GO

CREATE OR ALTER PROCEDURE sp_ObtenerDashboard
    @IdFinca INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);
    DECLARE @Hace7Dias DATE = DATEADD(DAY, -7, @Hoy);

    SELECT 
        (SELECT COUNT(1) FROM Parcelas WHERE Activa = 1 AND (@IdFinca IS NULL OR IdFinca = @IdFinca)) AS TotalParcelas,
        ISNULL((
            SELECT SUM(r.Valor) 
            FROM RegistrosCampo r
            INNER JOIN TiposRegistro t ON r.IdTipoRegistro = t.IdTipoRegistro
            WHERE t.Codigo = 'riego' 
              AND r.Fecha BETWEEN @Hace7Dias AND @Hoy
              AND (@IdFinca IS NULL OR r.IdFinca = @IdFinca)
        ), 0) AS LitrosRegadosUltimos7Dias;

    SELECT TOP 15
        r.IdRegistro,
        r.IdFinca,
        r.IdParcela,
        t.Codigo AS TipoCodigo,
        t.Nombre AS TipoNombre,
        r.Fecha,
        r.Valor,
        r.Detalle,
        r.Nota,
        r.NombreAutor,
        ISNULL(p.NombreParcela, CONCAT('Toda la finca ', f.NombreFinca)) AS Destino
    FROM RegistrosCampo r
    INNER JOIN TiposRegistro t ON r.IdTipoRegistro = t.IdTipoRegistro
    INNER JOIN Fincas f ON r.IdFinca = f.IdFinca
    LEFT JOIN Parcelas p ON r.IdParcela = p.IdParcela
    WHERE (@IdFinca IS NULL OR r.IdFinca = @IdFinca)
    ORDER BY r.Fecha DESC, r.IdRegistro DESC;
END;
GO
