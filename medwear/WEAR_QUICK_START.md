# 🚀 Integración Wear OS - Quick Start

## 1️⃣ Inicializar en main.dart

```dart
import 'package:medwear/services/wear_data_layer_service.dart';
import 'package:medwear/services/wear_sync_service.dart';
import 'package:medwear/services/wear_notification_service.dart';
import 'package:medwear/services/wear_response_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... otras inicializaciones ...
  
  // 🕐 SERVICIOS WEAR OS
  Get.put(WearDataLayerService());
  Get.put(WearSyncService());
  Get.put(WearNotificationService());
  Get.put(WearResponseService());
  
  runApp(const MedWearApp());
}
```

---

## 2️⃣ Sincronizar Medicamentos

```dart
class MedicamentoController extends GetxController {
  late final WearSyncService _wearSync;

  @override
  void onInit() {
    super.onInit();
    _wearSync = Get.find<WearSyncService>();
  }

  // Al cargar medicamentos, sincronizar al reloj
  void cargarMedicamentos() {
    _firebaseService.obtenerMedicamentosActivos().listen((lista) {
      medicamentos.value = lista;
      
      // 🔄 SINCRONIZAR AL RELOJ
      _wearSync.sincronizarMedicamentosAlReloj(lista);
    });
  }

  // Al agregar medicamento nuevo
  Future<bool> agregarMedicamento(Medicamento medicamento) async {
    try {
      final id = await _firebaseService.crearMedicamento(medicamento);
      final medConId = medicamento.copyWith(id: id);
      
      // 📲 NOTIFICAR AL RELOJ
      await _wearSync.enviarRecordatorioAlReloj(
        medicamento: medConId,
        horario: medicamento.horarios.first,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
```

---

## 3️⃣ Mostrar Pantalla Wear OS

```dart
// En app.dart - detectar dispositivo
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: _getHomePage(),
    );
  }

  Widget _getHomePage() {
    // Opción 1: Por resolución
    if (MediaQuery.of(context).size.diagonal < 3.0) {
      return WearHomePage();
    }
    return HomePage();
    
    // Opción 2: Por ruta
    // return GetRouterOutlet();
  }
}
```

---

## 4️⃣ Recibir Respuestas del Reloj

```dart
class MedicamentoController extends GetxController {
  late final WearResponseService _wearResponse;

  @override
  void onInit() {
    super.onInit();
    _wearResponse = Get.find<WearResponseService>();
    
    // 📥 ESCUCHAR RESPUESTAS DEL RELOJ
    _escucharWear();
  }

  void _escucharWear() {
    // Observar acciones del reloj
    ever(_wearResponse.accionesRecientes, (_) {
      print('Nueva acción del reloj');
    });
  }

  // Cuando el reloj reporta medicamento tomado
  Future<void> registrarTomaDesdeWear(
    String medicamentoId,
    DateTime hora,
  ) async {
    await _wearResponse.procesarTomaDesdeReloj(
      medicamentoId: medicamentoId,
      horaCompleta: hora,
    );
  }

  // Cuando el reloj reporta pospuesto
  Future<void> registrarPospuesestoDesdeWear(
    String medicamentoId,
    DateTime hora,
  ) async {
    await _wearResponse.procesarPospuestDesdeReloj(
      medicamentoId: medicamentoId,
      horaCompleta: hora,
      minutosPosponer: 10,
    );
  }
}
```

---

## 5️⃣ Usar WearHomePage

```dart
// Acceso simple - muestra medicamentos del día en el reloj
class WearHomePage extends StatefulWidget {
  @override
  State<WearHomePage> createState() => _WearHomePageState();
}

class _WearHomePageState extends State<WearHomePage> {
  late final MedicamentoController _medController;
  late final WearSyncService _wearSync;

  @override
  void initState() {
    super.initState();
    _medController = Get.find<MedicamentoController>();
    _wearSync = Get.find<WearSyncService>();
    
    // Sincronizar cuando abre la pantalla
    _sincronizar();
  }

  Future<void> _sincronizar() async {
    final meds = _medController.obtenerMedicamentosHoy();
    await _wearSync.sincronizarMedicamentosAlReloj(meds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final meds = _medController.obtenerMedicamentosHoy();
        return ListView.builder(
          itemCount: meds.length,
          itemBuilder: (_, i) => _buildMedCard(meds[i]),
        );
      }),
    );
  }

  Widget _buildMedCard(Medicamento med) {
    return Card(
      child: Column(
        children: [
          Text(med.nombre, style: TextStyle(fontSize: 20)),
          Text(med.dosis),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _marcarTomado(med),
                child: Text('✓ Tomado'),
              ),
              ElevatedButton(
                onPressed: () => _posponer(med),
                child: Text('⏱ Posponer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _marcarTomado(Medicamento med) async {
    await _medController.marcarComoTomado(med);
  }

  Future<void> _posponer(Medicamento med) async {
    await _medController.postponerToma(med);
  }
}
```

---

## 6️⃣ Notificaciones en Wear

```dart
// Programar notificación para hora específica
class MedicamentoController extends GetxController {
  late final WearNotificationService _wearNotif;

  Future<void> programarNotificacionWear(Medicamento med, String horario) async {
    final parts = horario.split(':');
    final ahora = DateTime.now();
    final horaNotif = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    await _wearNotif.programarRecordatorio(
      medicamentoId: med.id ?? '',
      medicamentoNombre: med.nombre,
      dosis: med.dosis,
      horaRecordatorio: horaNotif,
    );
  }

  // Mostrar notificación inmediata
  Future<void> mostrarNotificacionInmediata(Medicamento med) async {
    await _wearNotif.mostrarRecordatorioWear(
      medicamentoId: med.id ?? '',
      medicamentoNombre: med.nombre,
      dosis: med.dosis,
      hora: DateTime.now(),
    );
  }
}
```

---

## 7️⃣ Verificar Conexión con Reloj

```dart
// En cualquier parte del código
final wearSync = Get.find<WearSyncService>();

// Verificar si está conectado
if (wearSync.isWearConnected.value) {
  print('✅ Reloj conectado');
} else {
  print('❌ Reloj desconectado');
}

// Verificar conexión
final isConnected = await wearSync.verificarConexionReloj();

// Escuchar cambios de conexión
ever(wearSync.isWearConnected, (connected) {
  if (connected) {
    print('📱 Reloj se conectó');
  } else {
    print('📵 Reloj se desconectó');
  }
});
```

---

## 8️⃣ Datos Que Se Sincronizan

### Móvil → Reloj

```json
{
  "tipo": "sincronización",
  "ruta": "/medicamentos/sync",
  "datos": {
    "medicamentos": [
      {
        "id": "med_123",
        "nombre": "Ibuprofeno",
        "dosis": "400mg",
        "horarios": ["09:00", "21:00"],
        "ultimaToma": "2024-11-14T09:00:00Z",
        "tomadoHoy": true
      }
    ],
    "timestamp": "2024-11-14T10:30:00Z"
  }
}
```

### Reloj → Móvil (Tomado)

```json
{
  "ruta": "/medicamento/tomado",
  "datos": {
    "medicamento_id": "med_123",
    "hora": "2024-11-14T09:00:00Z",
    "timestamp": 1731573600000
  }
}
```

### Reloj → Móvil (Pospuesto)

```json
{
  "ruta": "/medicamento/pospuesto",
  "datos": {
    "medicamento_id": "med_123",
    "hora": "2024-11-14T09:00:00Z",
    "timestamp": 1731573600000
  }
}
```

---

## 🔍 Debugging - Ver Logs

```bash
# Logs de Wear OS
adb logcat -s "WearableListener|WearDataLayer|WearNotif"

# Logs de Flutter
flutter logs -t "wear"

# Ver notificaciones
adb shell dumpsys notification | grep medwear
```

---

## ⚡ API Rápida

| Método | Descripción | Ejemplo |
|--------|-------------|---------|
| `sincronizarMedicamentosAlReloj()` | Enviar medicamentos | `await wearSync.sincronizarMedicamentosAlReloj(meds)` |
| `enviarRecordatorioAlReloj()` | Enviar recordatorio urgente | `await wearSync.enviarRecordatorioAlReloj(med, hora)` |
| `procesarTomaDesdeReloj()` | Procesar acción "tomado" | `await wearResp.procesarTomaDesdeReloj(id, hora)` |
| `procesarPospuestDesdeReloj()` | Procesar acción "posponer" | `await wearResp.procesarPospuestDesdeReloj(id, hora)` |
| `programarRecordatorio()` | Programar notificación | `await wearNotif.programarRecordatorio(id, nombre, dosis, hora)` |
| `verificarConexionReloj()` | Verificar si conectado | `final ok = await wearSync.verificarConexionReloj()` |

---

## ✅ Checklist Rápido

```
☐ Servicios Wear inicializados en main.dart
☐ MedicamentoController actualizado
☐ WearHomePage importada
☐ Rutas de navegación configuradas
☐ AndroidManifest.xml con permisos Wear
☐ Servicios Kotlin compilados
☐ Emulador Wear OS ejecutando
☐ App instalada en emulador
☐ Notificaciones probadas
☐ Sincronización probada
☐ Respuestas del reloj procesadas
```

---

**Para documentación completa, ver:** `WEAR_OS_IMPLEMENTATION.md`
