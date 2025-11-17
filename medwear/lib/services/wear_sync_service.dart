import 'package:get/get.dart';
import '../models/medicamento_model.dart';
import '../models/wear_medicamento_model.dart';
import '../services/wear_data_layer_service.dart';

class WearSyncService extends GetxService {
  final WearDataLayerService _dataLayerService = WearDataLayerService();
  
  final RxBool isWearConnected = false.obs;
  final RxBool isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeWearListener();
  }

  /// Inicializa el listener para mensajes del reloj
  void _initializeWearListener() {
    _dataLayerService.listenToWearMessages((message) {
      print('🔄 Mensaje del reloj recibido: ${message.path}');
      
      if (message.isMedicamentoTomado) {
        _handleMedicamentoTomado(message);
      } else if (message.isMedicamentoPospuesto) {
        _handleMedicamentoPospuesto(message);
      }
    });
  }

  /// Sincroniza medicamentos del día al reloj
  Future<void> sincronizarMedicamentosAlReloj(
    List<Medicamento> medicamentos,
  ) async {
    if (isSyncing.value) return;
    
    try {
      isSyncing.value = true;
      
      // Convertir medicamentos a modelo Wear
      final wearMedicamentos = medicamentos.map((med) {
        return WearMedicamento(
          id: med.id ?? '',
          nombre: med.nombre,
          dosis: med.dosis,
          horarios: med.horarios,
          ultimaToma: DateTime.now(),
          tomadoHoy: false,
        );
      }).toList();

      // Crear payload
      final payload = WearSyncPayload(
        medicamentos: wearMedicamentos,
        timestampSync: DateTime.now(),
      );

      // Enviar al reloj
      await _dataLayerService.sendDataToWear(
        path: '/medicamentos/sync',
        data: payload.toJson(),
      );

      print('✅ Medicamentos sincronizados exitosamente al reloj');
      isWearConnected.value = true;
    } catch (e) {
      print('❌ Error sincronizando medicamentos: $e');
    } finally {
      isSyncing.value = false;
    }
  }


  Future<void> enviarRecordatorioAlReloj({
    required Medicamento medicamento,
    required String horario,
  }) async {
    try {
      // Parsear horario "HH:mm"
      final parts = horario.split(':');
      final ahora = DateTime.now();
      final horaRecordatorio = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      await _dataLayerService.sendReminderToWear(
        medicamentoId: medicamento.id ?? '',
        nombre: medicamento.nombre,
        dosis: medicamento.dosis,
        hora: horaRecordatorio,
      );

      print('📲 Recordatorio enviado al reloj');
    } catch (e) {
      print('❌ Error enviando recordatorio: $e');
    }
  }

  /// Maneja cuando el reloj reporta que tomó el medicamento
  void _handleMedicamentoTomado(WearableMessage message) {
    print('👍 Medicamento tomado desde reloj');
    print('ID: ${message.medicamentoId}');
    
    // Aquí se puede notificar al controlador principal
    // para que registre la toma en la BD
  }

  /// Maneja cuando el reloj reporta que pospuso el medicamento
  void _handleMedicamentoPospuesto(WearableMessage message) {
    print('⏱️ Medicamento pospuesto desde reloj');
    print('ID: ${message.medicamentoId}');
    
    // Programar nuevo recordatorio en 10 minutos
  }

  /// Obtiene el estado de conexión con el reloj
  Future<bool> verificarConexionReloj() async {
    try {
      // Enviar un mensaje de ping
      await _dataLayerService.sendDataToWear(
        path: '/ping',
        data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
      );
      isWearConnected.value = true;
      return true;
    } catch (e) {
      isWearConnected.value = false;
      return false;
    }
  }
}
