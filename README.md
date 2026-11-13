# 💧 Raíz Azul - Aplicación Móvil Agrícola

**Universidad Nacional Héroes San José de las Mulas**  
*Uso eficiente del agua y manejo responsable de cultivos para pequeños y medianos productores (Piloto: Matagalpa, Jinotega, Chontales).*

---

## 📁 Estructura del Proyecto

```text
raiz_azul/
├── database/
│   └── schema_raiz_azul.sql     # Script SQL Server (Tablas, Constraints, Seeds y SPs)
├── backend/
│   ├── config/                  # Conexión a SQL Server (PDO) y CORS
│   ├── services/                # Lógica agronómica (etapas, riegos, riesgos, fertilizaciones)
│   ├── models/                  # Capa de datos con fallback para pruebas inmediatas
│   ├── api/                     # Endpoints REST (Dashboard, Parcelas, Registros, Calendario, Reportes)
│   └── router.php               # Enrutador para servidor de desarrollo PHP
└── mobile_app/                  # Aplicación Móvil en Flutter (Dart)
    └── lib/
        ├── core/                # Tema oficial, constantes y servicio HTTP
        ├── models/              # Modelos Dart (Parcela, Registro, Alerta, Evento)
        ├── screens/             # Pantallas (Inicio, Parcelas, Calendario, Reportes)
        └── widgets/             # Modales (Registrar, Nueva Parcela, Detalle, Perfil)
```

---

## 🚀 Guía de Inicio Rápido

### 1. Base de Datos (SQL Server)
1. Abre **SQL Server Management Studio (SSMS)** o **Azure Data Studio**.
2. Conéctate a tu servidor local de SQL Server.
3. Abre y ejecuta el archivo:
   ```text
   database/schema_raiz_azul.sql
   ```
4. Se creará la base de datos `RaizAzul` con los catálogos de cultivos (Tomate, Chile, Repollo, Maíz, Frijol), zonas de Nicaragua, parcelas de ejemplo y los Procedimientos Almacenados. El script es idempotente: puedes ejecutarlo de nuevo para aplicar migraciones sin borrar datos.
5. Edita tus credenciales en `backend/config/database.php` (host, puerto, usuario y contraseña de SQL Server).
6. Usuarios de prueba para el login (contraseña `crispin123`): `Crispin`, `Iris`, `Cristin` y `Liam`.

> **Nota:** Si usas el MCP de SQL Server en OpenCode, copia `opencode.example.json` a `opencode.json` y coloca tus credenciales. Ese archivo está en `.gitignore` para no subir contraseñas.

---

### 2. Backend (API en PHP)
Para poner en marcha la API en tu máquina, abre una terminal en la carpeta `backend` y corre el servidor integrado de PHP:

```bash
cd backend
php -S localhost:8000 router.php
```

Puedes verificar el estado abriendo en tu navegador:
`http://localhost:8000/api/status.php`

> **Nota:** La API incluye un sistema inteligente de fallback con datos locales iniciales. Si aún estás configurando el controlador `pdo_sqlsrv` en tu PHP, la API funcionará de inmediato para que puedas probar la app en Flutter sin bloqueos.

---

### 3. Aplicación Móvil (Flutter)
Para ejecutar la app en tu dispositivo Android, emulador o en Windows Desktop:

```bash
cd mobile_app
flutter run
```

---

## 🌿 Características Implementadas
- **Dashboard "Hoy":** Resumen del ciclo, litros regados en los últimos 7 días y conteo de alertas activas.
- **Lógica Agronómica Inteligente:**
  - Cálculo automático de etapas fenológicas (Establecimiento, Desarrollo, Floración y llenado, Maduración, Cosecha).
  - Alerta de riesgo de escorrentía si llueve $\ge 40\text{ mm}$ tras fertilizar.
  - Alerta de posponer riego si cayeron $\ge 20\text{ mm}$ de lluvia en 3 días.
  - Detección de ventanas de fertilización por cultivo.
- **Gestión de Parcelas:** Creación, avance visual del ciclo, estimación de fecha de cosecha y detalle de labores.
- **Botón Rápido de Registro (+):** Formulario para anotar Riego (L), Lluvia (mm), Insumos (lb) y Labores de campo.
- **Riego en Varias Fechas:** Un mismo riego puede registrarse en varios días, indicando método (goteo, aspersión, gravedad, manual u otro) y duración en minutos por día. Se crea un registro por fecha para mantener reportes, calendario y alertas.
- **Calendario Agrícola:** Visualización mensual con indicadores por tipo de labor y proyección de eventos futuros estimados.
- **Reportes de Uso Eficiente:** Comparativa de agua por manzana ($L/\text{mz}$) y cálculo de litros de agua ahorrados.
