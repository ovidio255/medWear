// Ejemplos de Uso Avanzado - Wear OS Integration

// ============================================
// 1. INICIALIZACIÓN COMPLETA CON GETX
// ============================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medwear/services/wear_data_layer_service.dart';
import 'package:medwear/services/wear_sync_service.dart';
import 'package:medwear/services/wear_notification_service.dart';
import 'package:medwear/services/wear_response_service.dart';
import 'package:medwear/controllers/medicamento_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos, Firebase, etc.
  // await initializeServices();
  
  // 🕐 INICIALIZAR SERVICIOS WEAR OS
  final wearDataLayer = Get.put(WearDataLayerService());
  final wearSync = Get.put(WearSyncService());
  final wearNotif = Get.put(WearNotificationService());
  final wearResponse = Get.put(WearResponseService());
  
  // Inicializar notificaciones Wear
  await wearNotif.initialize();
  
  // Inicializar controladores
  Get.put(MedicamentoController());
  
  runApp(const MedWearApp());
}

// ============================================
// 2. ACTUALIZAR MEDICAMENTO CONTROLLER
// ============================================

class MedicamentoControllerWear extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();
  
  // 🕐 SERVICIOS WEAR
  late WearSyncService _wearSync;
  late WearNotificationService _wearNotif;
  late WearResponseService _wearResponse;

  final RxList<Medicamento> medicamentos = <Medicamento>[].obs;
  final RxBool isWearConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    _wearSync = Get.find<WearSyncService>();
    _wearNotif = Get.find<WearNotificationService>();
    _wearResponse = Get.find<WearResponseService>();
    
    cargarMedicamentos();
    _escucharWear();
  }

  /// Cargar medicamentos y sincronizar al reloj
  void cargarMedicamentos() {
    _firebaseService.obtenerMedicamentosActivos().listen((lista) {
      medicamentos.value = lista;
      
      // 🔄 SINCRONIZAR AL RELOJ AUTOMÁTICAMENTE
      _sincronizarWear(lista);
    });
  }

  /// Sincronizar medicamentos al reloj
  Future<void> _sincronizarWear(List<Medicamento> medicamentos) async {
    try {
      final medicamentosHoy = obtenerMedicamentosHoy();
      
      if (medicamentosHoy.isNotEmpty) {
        await _wearSync.sincronizarMedicamentosAlReloj(medicamentosHoy);
        print('✅ Medicamentos sincronizados al reloj');
      }
    } catch (e) {
      print('❌ Error sincronizando: $e');
    }
  }

  /// Escuchar respuestas desde el reloj
  void _escucharWear() {
    // Observar estado de conexión
    ever(_wearSync.isWearConnected, (connected) {
      isWearConnected.value = connected;
      if (connected) {
        print('📱 Reloj conectado');
        _sincronizarWear(medicamentos);
      } else {
        print('📵 Reloj desconectado');
      }
    });

    // Observar acciones del reloj
    ever(_wearResponse.accionesRecientes, (acciones) {
      if (acciones.isNotEmpty) {
        final ultimaAccion = acciones.last;
        print('🔄 Acción recibida: ${ultimaAccion.accion}');
      }
    });
  }

  /// Agregar medicamento (con sincronización Wear)
  Future<bool> agregarMedicamento(Medicamento medicamento) async {
    try {
      isLoading.value = true;
      
      // Crear en Firebase
      final id = await _firebaseService.crearMedicamento(medicamento);
      final medConId = medicamento.copyWith(id: id);
      
      // Programar notificaciones en móvil
      await _notificationService.programarNotificacionesMedicamento(medConId);
      
      // 📲 NOTIFICAR AL RELOJ
      if (_wearSync.isWearConnected.value) {
        await _wearSync.enviarRecordatorioAlReloj(
          medicamento: medConId,
          horario: medConId.horarios.isNotEmpty 
            ? medConId.horarios.first 
            : '09:00',
        );
      }
      
      // Programar notificaciones Wear
      for (final horario in medConId.horarios) {
        await _programarNotificacionWear(medConId, horario);
      }
      
      return true;
    } catch (e) {
      Get.snackbar('Error', 'No se pudo agregar: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Programar notificación en Wear OS
  Future<void> _programarNotificacionWear(
    Medicamento medicamento,
    String horario,
  ) async {
    try {
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
        medicamentoId: medicamento.id ?? '',
        medicamentoNombre: medicamento.nombre,
        dosis: medicamento.dosis,
        horaRecordatorio: horaNotif,
      );
    } catch (e) {
      print('Error programando notif Wear: $e');
    }
  }

  /// Marcar como tomado (desde Wear o móvil)
  Future<void> marcarComoTomado(Medicamento medicamento) async {
    try {
      final ahora = DateTime.now();
      
      // Registrar en BD
      await registrarToma(medicamento, EstadoToma.tomado);
      
      // 📤 NOTIFICAR AL RELOJ
      if (_wearSync.isWearConnected.value) {
        await _wearSync.sendDataToWear(
          path: '/medicamento/confirmacion',
          data: {
            'medicamento_id': medicamento.id,
            'estado': 'tomado',
            'timestamp': ahora.millisecondsSinceEpoch,
          },
        );
      }
      
      Get.snackbar('✅', 'Medicamento registrado');
    } catch (e) {
      Get.snackbar('❌', 'Error: $e');
    }
  }

  /// Posponer medicamento
  Future<void> postponerToma(Medicamento medicamento) async {
    try {
      final nuevaHora = DateTime.now().add(Duration(minutes: 10));
      
      // Registrar como pospuesto
      await registrarToma(medicamento, EstadoToma.pospuesto);
      
      // Programar nuevo recordatorio
      await _notificationService.programarNotificacionMedicamento(
        medicamento,
        nuevaHora,
      );
      
      // 📤 NOTIFICAR AL RELOJ
      if (_wearSync.isWearConnected.value) {
        await _wearSync.sendDataToWear(
          path: '/medicamento/confirmacion',
          data: {
            'medicamento_id': medicamento.id,
            'estado': 'pospuesto',
            'nuevaHora': nuevaHora.toIso8601String(),
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      }
      
      Get.snackbar('⏱', 'Recordatorio en 10 minutos');
    } catch (e) {
      Get.snackbar('❌', 'Error: $e');
    }
  }

  List<Medicamento> obtenerMedicamentosHoy() {
    final hoy = DateTime.now();
    final diaSemana = hoy.weekday;

    return medicamentos.where((med) {
      if (!med.activo) return false;
      if (!med.diasSemana.contains(diaSemana)) return false;
      if (hoy.isBefore(med.fechaInicio)) return false;
      if (med.fechaFin != null && hoy.isAfter(med.fechaFin!)) return false;
      return true;
    }).toList();
  }

  Future<bool> registrarToma(
    Medicamento medicamento,
    EstadoToma estado, {
    DateTime? fechaHoraProgramada,
    String? notas,
  }) async {
    try {
      final toma = Toma(
        medicamentoId: medicamento.id!,
        medicamentoNombre: medicamento.nombre,
        dosis: medicamento.dosis,
        fechaHoraProgramada: fechaHoraProgramada ?? DateTime.now(),
        fechaHoraReal: DateTime.now(),
        estado: estado,
        notas: notas,
      );

      await _firebaseService.registrarToma(toma);
      return true;
    } catch (e) {
      print('Error registrando toma: $e');
      return false;
    }
  }
}

// ============================================
// 3. CREAR PANTALLA ADAPTATIVA
// ============================================

class AdaptiveHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWearOS = _isWearOS(context);
    
    return isWearOS ? WearHomePage() : HomePage();
  }

  bool _isWearOS(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = size.width * size.width + size.height * size.height;
    
    // Reloj típico: 1.4" = ~280x360px
    // Teléfono típico: 5.5" = ~1080x1920px
    
    return diagonal < 300 * 300; // Diagonal < ~3"
  }
}

// ============================================
// 4. USAR GETPAGE PARA RUTAS WEAR
// ============================================

GetMaterialApp(
  title: 'MedWear',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  getPages: [
    // Ruta móvil
    GetPage(
      name: '/',
      page: () => HomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<MedicamentoController>(
          () => MedicamentoControllerWear(),
        );
      }),
    ),
    
    // Ruta Wear OS
    GetPage(
      name: '/wear',
      page: () => WearHomePage(),
      transition: Transition.cupertino,
    ),
  ],
  initialRoute: _getInitialRoute(),
)

String _getInitialRoute() {
  // Detectar si es Wear OS y cargar ruta apropiada
  return '/'; // O '/wear' si detectas Wear OS
}

// ============================================
// 5. NOTIFICACIONES AVANZADAS
// ============================================

Future<void> mostrarNotificacionAvanzada(Medicamento med) async {
  final wearNotif = Get.find<WearNotificationService>();
  
  // Opción 1: Notificación urgente con vibración intensa
  await wearNotif.mostrarNotificacionUrgente(
    titulo: '⚠️ ${med.nombre}',
    mensaje: 'Dosis: ${med.dosis} - Hora: ${_formatHora(DateTime.now())}',
    medicamentoId: med.id ?? '',
  );
}

String _formatHora(DateTime fecha) {
  return '${fecha.hour.toString().padLeft(2, '0')}:'
         '${fecha.minute.toString().padLeft(2, '0')}';
}

// ============================================
// 6. SINCRONIZACIÓN PERIÓDICA
// ============================================

class SyncScheduler {
  static void iniciarSincronizacionPeriodica() {
    // Sincronizar cada 5 minutos
    Timer.periodic(Duration(minutes: 5), (_) async {
      final medController = Get.find<MedicamentoControllerWear>();
      final medicamentos = medController.obtenerMedicamentosHoy();
      
      final wearSync = Get.find<WearSyncService>();
      await wearSync.sincronizarMedicamentosAlReloj(medicamentos);
      
      print('🔄 Sincronización periódica completada');
    });
  }
}

// En main:
void main() async {
  // ... inicialización ...
  
  // Iniciar sincronización periódica
  SyncScheduler.iniciarSincronizacionPeriodica();
  
  runApp(const MedWearApp());
}

// ============================================
// 7. MONITOREAR ESTADO DEL RELOJ
// ============================================

class WearStatusWidget extends GetView<WearSyncService> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final connected = controller.isWearConnected.value;
      final syncing = controller.isSyncing.value;
      
      return Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 8,
                backgroundColor: connected ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 8),
              Text(
                connected ? '✅ Reloj conectado' : '⚠️ Reloj desconectado',
                style: TextStyle(
                  color: connected ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (syncing)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(),
              ),
            ),
        ],
      );
    });
  }
}

// ============================================
// 8. TESTING - SIMULAR ACCIONES DEL RELOJ
// ============================================

class WearTestHelper {
  static Future<void> simulateMedicamentoTomado(String medId) async {
    final wearResponse = Get.find<WearResponseService>();
    
    await wearResponse.procesarTomaDesdeReloj(
      medicamentoId: medId,
      horaCompleta: DateTime.now(),
    );
    
    print('✅ Simulado: Medicamento tomado');
  }

  static Future<void> simulateMedicamentoPospuesto(String medId) async {
    final wearResponse = Get.find<WearResponseService>();
    
    await wearResponse.procesarPospuestDesdeReloj(
      medicamentoId: medId,
      horaCompleta: DateTime.now(),
      minutosPosponer: 10,
    );
    
    print('⏱ Simulado: Medicamento pospuesto');
  }

  static Future<void> simulateWearConnection() async {
    final wearSync = Get.find<WearSyncService>();
    
    final isConnected = await wearSync.verificarConexionReloj();
    print(isConnected ? '📱 Reloj conectado' : '📵 Reloj no disponible');
  }
}

// Usar en pruebas:
// await WearTestHelper.simulateMedicamentoTomado('med_123');
