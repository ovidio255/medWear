# 🕐 MedWear - Guía de Implementación Wear OS

## Descripción General

Este documento describe cómo integrar la aplicación MedWear con dispositivos Wear OS (reloj inteligente) para proporcionar recordatorios de medicamentos directamente en el reloj.

---

## 📋 Características Implementadas

### 1. **Recibir Recordatorios**
- ✅ Notificaciones en el reloj cuando toca tomar medicamento
- ✅ Vibración en el reloj
- ✅ Información: Nombre, dosis, hora programada

### 2. **Marcar Toma desde el Reloj**
- ✅ Botón "Tomado" en la notificación
- ✅ Botón "Posponer" (10 minutos)
- ✅ Las acciones se sincronizan al móvil

### 3. **Lista Simple de Medicamentos**
- ✅ Pantalla optimizada para Wear OS
- ✅ Scroll vertical por medicamentos del día
- ✅ Indicador de medicamentos pendientes

### 4. **Sincronización Bidireccional**
- ✅ Data Layer API para comunicación
- ✅ Móvil → Reloj: medicamentos actualizados
- ✅ Reloj → Móvil: acciones del usuario

### 5. **Notificaciones Locales en Wear**
- ✅ Alarmas que se activan a la hora programada
- ✅ Vibración con patrón personalizado
- ✅ Sonido de notificación

---

## 🛠️ Estructura de Archivos Creados

```
lib/
├── services/
│   ├── wear_data_layer_service.dart       # Data Layer API
│   ├── wear_sync_service.dart             # Sincronización
│   ├── wear_notification_service.dart     # Notificaciones Wear
│   └── wear_response_service.dart         # Procesar respuestas
├── models/
│   └── wear_medicamento_model.dart        # Modelos Wear
└── pages/
    └── wear_home_page.dart                # Pantalla Wear OS

android/
├── app/src/main/
│   ├── AndroidManifest.xml                # Permisos y servicios
│   └── kotlin/com/medwear/medwear/
│       ├── WearDataLayerManager.kt        # Manager comunicación
│       ├── WearableListenerService.kt     # Listener Data Layer
│       └── WearNotificationReceiver.kt    # Broadcast Receiver
```

---

## 🚀 Instalación y Configuración

### Paso 1: Actualizar Dependencias

Ya se ha actualizado el `pubspec.yaml` con:

```yaml
dependencies:
  wearable_health: ^0.0.24
  http: ^1.1.0
  json_serializable: ^6.7.0
```

Ejecuta:
```bash
flutter pub get
```

### Paso 2: Configurar permisos Android

El `AndroidManifest.xml` ya incluye:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="com.google.android.permission.PROVIDE_BACKGROUND"/>
<uses-feature android:name="android.hardware.type.watch" android:required="false" />
```

### Paso 3: Inicializar Servicios Wear

En tu `main.dart` o en el controlador principal:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... resto de inicialización ...
  
  // Inicializar servicios Wear
  Get.put(WearDataLayerService());
  Get.put(WearSyncService());
  Get.put(WearNotificationService());
  Get.put(WearResponseService());
  
  runApp(const MedWearApp());
}
```

### Paso 4: Integrar en el Controlador Principal

Actualiza `medicamento_controller.dart`:

```dart
class MedicamentoController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  late final WearSyncService _wearSyncService;

  @override
  void onInit() {
    super.onInit();
    _wearSyncService = Get.find<WearSyncService>();
    cargarMedicamentos();
  }

  void cargarMedicamentos() {
    _firebaseService.obtenerMedicamentosActivos().listen((lista) {
      medicamentos.value = lista;
      
      // Sincronizar al reloj cuando hay cambios
      _wearSyncService.sincronizarMedicamentosAlReloj(lista);
    });
  }

  // ... resto del controlador ...
}
```

---

## 📱 Usar la Pantalla Wear OS

### Opción A: Detectar automáticamente si es Wear OS

```dart
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

bool isWearOS = defaultTargetPlatform == TargetPlatform.android &&
                MediaQuery.of(context).size.diagonal < 3.0; // ~2.8" tipico para Wear

if (isWearOS) {
  return WearHomePage();
} else {
  return HomePage();
}
```

### Opción B: Ruta específica para Wear

```dart
GetMaterialApp(
  // ...
  getPages: [
    GetPage(name: '/', page: () => HomePage()),
    GetPage(name: '/wear', page: () => WearHomePage()),
  ],
)
```

Luego accede desde el reloj visitando `/wear`.

---

## 🔄 Flujo de Sincronización

### Móvil → Reloj

1. **Cuando se crea/actualiza medicamento:**
```dart
await _wearSyncService.sincronizarMedicamentosAlReloj(medicamentos);
```

2. **Datos enviados:**
```json
{
  "medicamentos": [
    {
      "id": "123",
      "nombre": "Aspirin",
      "dosis": "500mg",
      "horarios": ["09:00", "21:00"],
      "ultimaToma": "2024-11-14T09:00:00Z",
      "tomadoHoy": true
    }
  ],
  "timestamp": "2024-11-14T10:30:00Z",
  "version": "1.0"
}
```

### Reloj → Móvil

1. **Usuario marca como "Tomado":**
- Envía: `/medicamento/tomado`
- Datos: `{medicamento_id, hora, timestamp}`

2. **Usuario marca como "Posponer":**
- Envía: `/medicamento/pospuesto`
- Datos: `{medicamento_id, hora, timestamp}`

3. **Procesar en móvil:**
```dart
final responseService = Get.find<WearResponseService>();

// Recibir evento
await responseService.procesarTomaDesdeReloj(
  medicamentoId: '123',
  horaCompleta: DateTime.now(),
);

// O posponer
await responseService.procesarPospuestDesdeReloj(
  medicamentoId: '123',
  horaCompleta: DateTime.now(),
  minutosPosponer: 10,
);
```

---

## 🔔 Notificaciones en Wear OS

### Programar Recordatorio

```dart
final wearNotif = Get.find<WearNotificationService>();

await wearNotif.programarRecordatorio(
  medicamentoId: 'med_123',
  medicamentoNombre: 'Ibuprofeno',
  dosis: '400mg',
  horaRecordatorio: DateTime(2024, 11, 14, 21, 0),
);
```

### Características de la Notificación

- **Vibración:** Patrón personalizado `[0, 500, 250, 500, 250, 500]`
- **Sonido:** `notification.wav`
- **Color:** Azul (#2196F3)
- **Acciones:** Botones "Tomado" y "Posponer"
- **Grupo:** Agrupa notificaciones de medicamentos

---

## 🧪 Pruebas en Emulador Wear OS

### 1. Crear AVD para Wear OS

```bash
flutter emulators --create --name wear_emulator
flutter emulators launch wear_emulator
```

### 2. Ejecutar app

```bash
# En una terminal
flutter run -d wear_emulator

# O especificar la app
flutter run -t lib/wear_main.dart -d wear_emulator
```

### 3. Simular notificación

```bash
adb shell am start -a android.intent.action.VIEW \
  -n com.medwear.medwear/.MainActivity
```

---

## 🐛 Debugging

### Ver logs de Wear

```bash
# Terminal 1: Ver logs del móvil
adb logcat -s "WearDataLayer"

# Terminal 2: Ver logs del reloj
adb -e logcat -s "WearableListener"

# Terminal 3: Logs de Flutter
flutter logs
```

### Comandos adb útiles

```bash
# Listar dispositivos
adb devices

# Emparejar reloj con móvil (en emulador)
adb -s emulator-5554 shell setprop debug.atrace.tags.enableflags 1

# Ver notificaciones
adb shell dumpsys notification
```

---

## 🎯 Checklist de Implementación

- [ ] `pubspec.yaml` actualizado con dependencias Wear
- [ ] `WearDataLayerService` en `lib/services/`
- [ ] `WearSyncService` en `lib/services/`
- [ ] `WearNotificationService` en `lib/services/`
- [ ] `WearResponseService` en `lib/services/`
- [ ] `WearHomePage` en `lib/pages/`
- [ ] `WearMedicamentoModel` en `lib/models/`
- [ ] `AndroidManifest.xml` actualizado con permisos Wear
- [ ] `WearDataLayerManager.kt` en `android/app/src/main/kotlin/`
- [ ] `WearableListenerService.kt` creado
- [ ] `WearNotificationReceiver.kt` creado
- [ ] Servicios Wear inicializados en `main.dart`
- [ ] Controlador actualizado para sincronizar
- [ ] Rutas de navegación configuradas

---

## 🔐 Consideraciones de Seguridad

1. **Datos Sensibles:** No guardes contraseñas en el reloj
2. **Almacenamiento Local:** Solo guarda información necesaria (medicamentos del día)
3. **Comunicación:** Data Layer API cifra datos automáticamente
4. **Permisos:** Solicita permisos necesarios en tiempo de ejecución

---

## 📊 Arquitectura de Datos

```
┌─────────────────────────────────────────────┐
│   Servidor (Firebase)                       │
│   - Medicamentos principales                │
│   - Historial completo de tomas             │
└────────────────┬────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────▼────────┐  ┌────▼────────────┐
│ Móvil (Zona 1) │  │ Reloj (Zona 2)  │
├─────────────┬──┤  ├──────────────┬──┤
│ - BD Local  │  │  │ - BD Local   │  │
│ - NotifServ │  │  │ - NotifServ  │  │
│ - Historial │  │  │ - Hoy solamente
│ completo    │  │  │                │
└─────────────┘  └──────────────────┘
```

---

## 🔄 Ciclo de Vida de una Toma

```
1. Medicamento programado en móvil
   ↓
2. Se sincroniza al reloj (Data Layer)
   ↓
3. A la hora, reloj genera notificación local
   ↓
4. Usuario ve notificación + acciones
   ↓
5. Usuario toca "Tomado" o "Posponer"
   ↓
6. Reloj envía datos al móvil
   ↓
7. Móvil recibe respuesta y registra en BD
   ↓
8. Confirmar a usuario en ambos dispositivos
```

---

## 🚨 Problemas Comunes

### Problema: "No hay conexión con el reloj"

**Solución:**
```dart
final isConnected = await _wearSyncService.verificarConexionReloj();
if (!isConnected) {
  print('Reloj no conectado. Esperando...');
  // Los datos se sincronizarán cuando se conecte
}
```

### Problema: "Notificaciones no llegan al reloj"

**Solución:**
1. Verificar permisos en `AndroidManifest.xml`
2. Verificar canal de notificaciones creado
3. Ver logs: `adb logcat -s "WearNotif"`

### Problema: "Datos no se sincronizan"

**Solución:**
1. Verificar que el reloj esté emparejado
2. Verificar conectividad Bluetooth
3. Usar `sendUrgentMessageToWear` en lugar de `sendDataToWear` para datos críticos

---

## 📚 Referencias

- [Wear OS Documentation](https://developer.android.com/wear)
- [Google Play Services - Wearable](https://developers.google.com/android/reference/com/google/android/gms/wearable/package-summary)
- [Data Layer API Guide](https://developer.android.com/training/wearables/data-layer)
- [Flutter - Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)

---

## 📝 Notas Importantes

- **Versión Mínima:** Android 5.0 (API 21) para Wear OS
- **Target SDK:** 34+
- **Kotlin:** 1.8.0+
- **Flutter:** 3.10+

---

## 🆘 Soporte

Para reportar problemas:

1. Recopilar logs: `flutter logs > medwear.log`
2. Incluir versión de Android/Wear OS
3. Describir los pasos para reproducir
4. Adjuntar screenshot si es posible

---

**Versión del documento:** 1.0  
**Última actualización:** 14 de Noviembre, 2024  
**Autor:** MedWear Development Team
