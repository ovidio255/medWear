# MedWear - Recordatorio de Medicamentos

## 📱 Descripción

MedWear es una aplicación móvil para Android que te ayuda a recordar la toma de tus medicamentos. La app envía notificaciones programadas y te permite registrar cuando tomas tus medicamentos o posponerlos.

## ✨ Características

### Funcionalidades Principales

- ✅ **Registrar medicamentos** con:
  - Nombre del medicamento
  - Dosis
  - Múltiples horarios al día
  - Días de la semana específicos
  - Fecha de inicio y fin del tratamiento

- 🔔 **Notificaciones programadas**:
  - Recordatorios en los horarios configurados
  - Vibración y sonido
  - Posponer toma por 10 minutos

- 📊 **Historial de tomas**:
  - Ver registro de medicamentos tomados
  - Ver medicamentos pospuestos u omitidos
  - Estadísticas de adherencia (últimos 7 días)

- 💾 **Almacenamiento en Firebase**:
  - Sincronización automática en la nube
  - Acceso desde cualquier dispositivo
  - Backup automático de datos

## 🚀 Instalación y Configuración

### Requisitos Previos

- Flutter SDK (3.9.2 o superior)
- Android Studio o VS Code
- Cuenta de Firebase
- Dispositivo Android o emulador (Android 7.0 / API 24 o superior)

### Configuración de Firebase

1. **Ya tienes el proyecto Firebase configurado** con el archivo `google-services.json` en:
   ```
   android/app/google-services.json
   ```

2. **Configurar Firestore** (en Firebase Console):
   - Ve a Firebase Console (https://console.firebase.google.com)
   - Selecciona tu proyecto "medwear-ce6e1"
   - Ve a "Firestore Database"
   - Crea la base de datos en modo de producción
   - Configura las reglas de seguridad:

   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Permitir lectura/escritura para usuarios autenticados
       match /medicamentos/{document=**} {
         allow read, write: if true;
       }
       match /tomas/{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

   **Nota**: Estas reglas permiten acceso público. Para producción, deberías implementar autenticación.

### Instalar Dependencias

```bash
cd medwear
flutter pub get
```

### Ejecutar la Aplicación

```bash
# En emulador o dispositivo conectado
flutter run

# Para release
flutter run --release
```

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada
├── app.dart                            # Configuración de la app
├── config/
│   ├── app_constants.dart
│   └── enviroment.dart
├── controllers/
│   ├── auth_controller.dart
│   └── medicamento_controller.dart     # Lógica de negocio
├── models/
│   ├── medicamento_model.dart          # Modelo de medicamento
│   ├── toma_model.dart                 # Modelo de toma
│   └── user_model.dart
├── pages/
│   ├── home_page.dart                  # Pantalla principal
│   ├── agregar_medicamento_page.dart   # Formulario agregar medicamento
│   ├── historial_page.dart             # Historial de tomas
│   ├── login_page.dart
│   └── register_page.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── firebase_service.dart           # Servicio de Firebase
│   └── notification_service.dart       # Servicio de notificaciones
├── theme/
│   ├── app_colors.dart
│   └── app_theme.dart
├── utils/
│   ├── helpers.dart
│   └── validators.dart
└── widgets/
    ├── custom_button.dart
    └── custom_input.dart
```

## 🎯 Uso de la Aplicación

### Agregar un Medicamento

1. En la pantalla principal, presiona el botón **"+ Agregar"**
2. Completa el formulario:
   - **Nombre**: Nombre del medicamento
   - **Dosis**: Cantidad (ej: "500mg" o "1 tableta")
   - **Horarios**: Presiona + para agregar horarios (ej: 08:00, 14:00, 20:00)
   - **Días**: Selecciona los días de la semana
   - **Fecha inicio**: Cuándo empezar el tratamiento
   - **Fecha fin**: (Opcional) Cuándo terminar
3. Presiona **"Guardar Medicamento"**

### Marcar una Toma

Desde la pantalla principal:
- **Botón "Tomado" (verde)**: Marca el medicamento como tomado
- **Botón "Posponer"**: Pospone 10 minutos y recibirás otro recordatorio

### Ver Historial

1. Presiona el ícono de **historial** (⏱️) en la barra superior
2. Verás:
   - Estadísticas de adherencia de los últimos 7 días
   - Lista de todas las tomas organizadas por fecha
   - Estados: Tomado (verde), Pospuesto (naranja), Omitido (rojo)

### Probar Notificaciones

Presiona el ícono de **campana** (🔔) en la barra superior para enviar una notificación de prueba.

## 🔧 Configuración Técnica

### Dependencias Principales

```yaml
dependencies:
  firebase_core: ^3.0.0              # Firebase core
  cloud_firestore: ^5.0.0            # Base de datos
  flutter_local_notifications: ^17.0.0  # Notificaciones
  timezone: ^0.9.2                   # Zonas horarias
  get: ^4.6.6                        # Estado y navegación
  intl: ^0.19.0                      # Internacionalización
```

### Permisos Android (ya configurados)

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

## 🐛 Solución de Problemas

### Las notificaciones no funcionan

1. Verifica que los permisos estén habilitados en la configuración del dispositivo
2. Android 13+ requiere permiso explícito para notificaciones
3. Reinicia la app después de otorgar permisos

### Error al conectar con Firebase

1. Verifica que el archivo `google-services.json` esté en `android/app/`
2. El `applicationId` debe coincidir: `com.medwear.app`
3. Ejecuta `flutter clean` y luego `flutter pub get`

### Error de compilación

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## 📱 Firebase Firestore - Estructura de Datos

### Colección: `medicamentos`

```javascript
{
  nombre: "Paracetamol",
  dosis: "500mg",
  horarios: ["08:00", "14:00", "20:00"],
  diasSemana: [1, 2, 3, 4, 5, 6, 7],  // 1=Lunes, 7=Domingo
  fechaInicio: Timestamp,
  fechaFin: Timestamp (opcional),
  activo: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Colección: `tomas`

```javascript
{
  medicamentoId: "abc123",
  medicamentoNombre: "Paracetamol",
  dosis: "500mg",
  fechaHoraProgramada: Timestamp,
  fechaHoraReal: Timestamp,
  estado: "tomado" | "pospuesto" | "omitido",
  notas: "Opcional",
  createdAt: Timestamp
}
```

## 🔐 Seguridad

**IMPORTANTE**: Las reglas actuales de Firestore permiten acceso público. Para producción:

1. Implementa autenticación de Firebase
2. Actualiza las reglas de Firestore:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /medicamentos/{document=**} {
      allow read, write: if request.auth != null;
    }
    match /tomas/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🚀 Próximas Características

- [ ] Autenticación de usuarios
- [ ] Sincronización con Wear OS
- [ ] Exportar historial a PDF
- [ ] Recordatorios de recarga de medicamentos
- [ ] Widget de la pantalla principal
- [ ] Tema oscuro

## 📄 Licencia

Este proyecto es de código abierto para fines educativos.

## 👨‍💻 Desarrollo

Proyecto desarrollado con Flutter y Firebase.

---

**¡Nunca olvides tomar tus medicamentos!** 💊⏰
