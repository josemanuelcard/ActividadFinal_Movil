# To-Do List - Flutter App

Aplicación móvil Flutter para gestión de tareas con arquitectura limpia, integración con API REST, persistencia local con SQLite y sincronización offline-first.

## 📋 Características

- ✅ Crear, editar, marcar como completadas y eliminar tareas
- 🔍 Filtrar tareas (todas, pendientes, completadas)
- 💾 Persistencia local con SQLite (sqflite)
- 🌐 Sincronización offline-first con API REST
- 🔄 Cola de operaciones para sincronización cuando vuelve la conexión
- 📱 Indicador de conectividad en tiempo real
- ⚡ Sincronización manual y automática
- 🛡️ Manejo robusto de errores con mensajes claros
- 🚀 Actualización optimista para UI fluida

## 🏗️ Arquitectura

La aplicación sigue una **arquitectura limpia** con separación de capas:

```
lib/
├── models/              # Modelos de datos
│   ├── task.dart
│   └── queue_operation.dart
├── data/
│   ├── local/          # Capa de persistencia local
│   │   └── database_helper.dart
│   ├── remote/         # Capa de API remota
│   │   └── api_service.dart
│   ├── repositories/   # Repositorios (lógica de negocio de datos)
│   │   └── task_repository.dart
│   └── services/       # Servicios auxiliares
│       ├── connectivity_service.dart
│       └── sync_service.dart
├── providers/          # Gestión de estado (Provider)
│   └── task_provider.dart
├── screens/            # Pantallas
│   └── home_screen.dart
├── widgets/            # Widgets reutilizables
│   ├── task_item.dart
│   ├── add_task_dialog.dart
│   └── connectivity_indicator.dart
└── main.dart           # Punto de entrada
```

### Capas de la Arquitectura

1. **Models**: Modelos de datos puros (Task, QueueOperation)
2. **Data Layer**:
   - **Local**: Base de datos SQLite con sqflite
   - **Remote**: Cliente HTTP para API REST
   - **Repositories**: Implementan la estrategia offline-first
   - **Services**: Servicios de conectividad y sincronización
3. **Providers**: Gestión de estado con Provider
4. **UI Layer**: Pantallas y widgets

## 🛠️ Tecnologías Utilizadas

- **Flutter 3.x**
- **Provider** - Gestión de estado
- **sqflite** - Base de datos SQLite local
- **http** - Cliente HTTP para API REST
- **connectivity_plus** - Detección de conectividad
- **uuid** - Generación de IDs únicos
- **intl** - Formateo de fechas

## 📦 Instalación

### Prerrequisitos

- Flutter SDK 3.x o superior
- Dart SDK
- Android Studio / Xcode (para desarrollo móvil)
- Node.js y npm (para el servidor API mock)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd actividadfinal_movil
   ```

2. **Instalar dependencias de Flutter**
   ```bash
   flutter pub get
   ```

3. **Configurar el servidor API mock**
   ```bash
   cd api
   npm install
   npm start
   ```
   El servidor estará disponible en `http://localhost:3000`

4. **Configurar la URL de la API en la app**
   
   Edita `lib/main.dart` y ajusta la URL según tu entorno:
   - **Android Emulator**: `http://10.0.2.2:3000` (ya configurado)
   - **iOS Simulator**: `http://localhost:3000`
   - **Dispositivo físico**: Usa la IP de tu máquina (ej: `http://192.168.1.100:3000`)

5. **Crear y ejecutar en un emulador/dispositivo**
   
   ⚠️ **IMPORTANTE**: Esta app NO funciona en web. Debes usar un emulador Android o dispositivo iOS.

   **Crear emulador Android (Android Studio):**
   - Abre Android Studio
   - Ve a **Tools** > **Device Manager**
   - Haz clic en **Create Device**
   - Selecciona un dispositivo (recomendado: Pixel 5)
   - Selecciona una imagen del sistema (API 33 o superior)
   - Inicia el emulador

   **Verificar dispositivos disponibles:**
   ```bash
   flutter devices
   ```

6. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🗄️ Base de Datos Local

### Esquema de Tareas

```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL,
  deleted INTEGER NOT NULL DEFAULT 0
);
```

### Esquema de Cola de Operaciones

```sql
CREATE TABLE queue_operations (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL,              -- CREATE | UPDATE | DELETE
  payload TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT
);
```

## 🔄 Estrategia Offline-First

### Lecturas
1. La app muestra primero los datos locales (instantáneo)
2. Si hay conexión, sincroniza en segundo plano
3. Aplica estrategia **Last-Write-Wins** comparando `updatedAt`

### Escrituras
1. Guarda inmediatamente en la base de datos local (actualización optimista)
2. Actualiza la UI instantáneamente
3. Encola la operación para sincronización
4. Sincroniza en segundo plano sin bloquear la UI
5. Si falla, la operación queda en cola para más tarde

### Sincronización
- Se activa automáticamente cuando:
  - La app se abre
  - Se detecta cambio de conectividad
  - El usuario pulsa el botón de sincronización
- Usa **backoff exponencial** para reintentos
- Máximo 5 intentos por operación
- Soporta **Idempotency-Key** para evitar duplicaciones

## 🧪 Cómo Probar el Modo Offline

### Prueba 1: Crear tareas sin conexión
1. Desactiva WiFi/datos móviles en tu dispositivo
2. Crea varias tareas en la app
3. Verifica que aparecen inmediatamente (datos locales)
4. Activa la conexión
5. Las tareas se sincronizarán automáticamente

### Prueba 2: Editar tareas sin conexión
1. Desactiva la conexión
2. Edita una tarea existente
3. Marca otra como completada
4. Activa la conexión
5. Verifica que los cambios se sincronizan

### Prueba 3: Eliminar tareas sin conexión
1. Desactiva la conexión
2. Elimina una tarea
3. Activa la conexión
4. Verifica que la eliminación se sincroniza

### Prueba 4: Sincronización manual
1. Desactiva la conexión
2. Realiza varias operaciones
3. Activa la conexión
4. Pulsa el botón de sincronización (icono de refresh)
5. Verifica que todas las operaciones se sincronizan

### Prueba 5: Resolución de conflictos (Last-Write-Wins)
1. Crea una tarea en la app
2. Edita la misma tarea en el servidor (directamente en la API)
3. Sincroniza la app
4. La versión con `updatedAt` más reciente prevalece

## 📱 Generación de APK

### APK de DEBUG (Recomendado para Pruebas) ✅

**Características:**
- ✅ Fácil de generar (no requiere configuración de firma)
- ✅ Incluye información de depuración
- ✅ Más rápido de compilar
- ✅ Perfecto para pruebas internas

**Cómo generar:**
```bash
# Opción 1: Usar el script (Windows)
build_apk_debug.bat

# Opción 2: Comando directo
flutter clean
flutter pub get
flutter build apk --debug
```

**Ubicación:** `build/app/outputs/flutter-apk/app-debug.apk`

### APK de RELEASE (Para Distribución)

**Características:**
- ✅ Optimizado para producción
- ✅ Tamaño más pequeño
- ⚠️ Requiere firma (Flutter usa una firma de debug por defecto)

**Cómo generar:**
```bash
# Opción 1: Usar el script (Windows)
build_apk.bat

# Opción 2: Comando directo
flutter clean
flutter pub get
flutter build apk --release
```

**Ubicación:** `build/app/outputs/flutter-apk/app-release.apk`

### Instalación del APK

**En un dispositivo Android:**
1. Habilita "Fuentes desconocidas" en Configuración > Seguridad
2. Transfiere el APK al dispositivo (USB, correo, etc.)
3. Abre el archivo APK y toca "Instalar"

**En un emulador:**
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 🔌 API Endpoints

La aplicación espera los siguientes endpoints:

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/tasks` | Obtener todas las tareas |
| GET | `/tasks/:id` | Obtener una tarea por ID |
| POST | `/tasks` | Crear una nueva tarea |
| PUT | `/tasks/:id` | Actualizar una tarea |
| DELETE | `/tasks/:id` | Eliminar una tarea |

### Formato JSON

```json
{
  "id": "string",
  "title": "string",
  "completed": boolean,
  "updatedAt": "ISO8601 string"
}
```

### Headers

- `Content-Type: application/json`
- `Idempotency-Key: string` (opcional, para evitar duplicaciones)

## 📝 Estructura de Carpetas

```
actividadfinal_movil/
├── lib/
│   ├── models/                    # Modelos de datos
│   │   ├── task.dart
│   │   └── queue_operation.dart
│   ├── data/
│   │   ├── local/
│   │   │   └── database_helper.dart    # Gestión de SQLite
│   │   ├── remote/
│   │   │   └── api_service.dart        # Cliente HTTP
│   │   ├── repositories/
│   │   │   └── task_repository.dart    # Lógica offline-first
│   │   └── services/
│   │       ├── connectivity_service.dart
│   │       └── sync_service.dart
│   ├── providers/
│   │   └── task_provider.dart          # Estado con Provider
│   ├── screens/
│   │   └── home_screen.dart            # Pantalla principal
│   ├── widgets/
│   │   ├── task_item.dart
│   │   ├── add_task_dialog.dart
│   │   └── connectivity_indicator.dart
│   └── main.dart
├── api/                            # Servidor API mock
│   ├── server.js
│   ├── package.json
│   └── README.md
├── android/
├── ios/
├── build_apk_debug.bat             # Script para generar APK debug
├── build_apk.bat                   # Script para generar APK release
├── pubspec.yaml
└── README.md
```

## 🐛 Manejo de Errores

La aplicación maneja los siguientes tipos de errores:

- **Timeouts**: Peticiones que exceden 10 segundos
- **4xx (Cliente)**: Errores de validación o recursos no encontrados
- **5xx (Servidor)**: Errores del servidor
- **Sin conexión**: Operaciones encoladas para sincronización posterior
- **Errores de base de datos**: Mensajes descriptivos al usuario

Los errores se muestran en la UI con mensajes claros y opción de cerrar.

## 🔐 Buenas Prácticas Implementadas

- ✅ Separación de responsabilidades (Clean Architecture)
- ✅ Gestión de estado centralizada (Provider)
- ✅ Manejo robusto de errores
- ✅ Documentación en código
- ✅ Código modular y reutilizable
- ✅ Offline-first para mejor UX
- ✅ Actualización optimista para UI fluida
- ✅ Idempotencia en operaciones
- ✅ Backoff exponencial en reintentos

## 📄 Entregables

- ✅ APK de debug para pruebas (`app-debug.apk`)
- ✅ README completo con documentación
- ✅ Arquitectura limpia implementada
- ✅ Sincronización offline-first funcional
- ✅ Manejo de errores robusto

## 📞 Soporte

Para problemas o preguntas:
1. Revisa los logs de la aplicación (`flutter logs`)
2. Verifica que el servidor API esté corriendo
3. Asegúrate de ejecutar en Android/iOS (no web)
4. Revisa la consola de Flutter para errores de sincronización

---

**Nota**: Asegúrate de que el servidor API esté corriendo antes de usar la aplicación con sincronización en línea. La aplicación NO funciona en web, solo en dispositivos Android/iOS o emuladores.
