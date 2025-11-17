import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';

/// Servicio para comunicación bidireccional entre móvil y reloj Wear OS
/// usando el patrón de Data Layer API de Google Play Services
class WearDataLayerService extends GetxService {
  late StreamController<WearableMessage> _messageStream;
  Stream<WearableMessage> get messageStream => _messageStream.stream;
  
  @override
  void onInit() {
    super.onInit();
    _messageStream = StreamController<WearableMessage>.broadcast();
  }

  /// Envía datos desde el móvil al reloj
  /// Los datos se sincronizan automáticamente cuando el reloj está conectado
  Future<bool> sendDataToWear({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📤 Enviando datos a Wear OS: $path');
      print('Datos: ${jsonEncode(data)}');
      
      // Simulación: En Android nativo se usaría:
      // Wearable.getDataClient(context).putDataItem(putDataRequest)
      
      // Para implementación real, usarías método channel nativo
      return true;
    } catch (e) {
      print('❌ Error enviando datos a Wear: $e');
      return false;
    }
  }

  /// Envía un mensaje urgente que requiere confirmación inmediata
  /// (A diferencia de DataItems que se sincronizan de fondo)
  Future<bool> sendUrgentMessageToWear({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('⚡ Enviando mensaje urgente a Wear: $path');
      
      // En Android nativo:
      // Wearable.getMessageClient(context).sendMessage(nodeId, path, data)
      
      return true;
    } catch (e) {
      print('❌ Error enviando mensaje urgente: $e');
      return false;
    }
  }

  /// Recibe datos desde el reloj
  /// Se ejecuta cuando hay cambios en los datos del reloj
  void listenToWearMessages(Function(WearableMessage) onMessage) {
    _messageStream.stream.listen((message) {
      print('📥 Mensaje recibido del reloj: ${message.path}');
      print('Datos: ${jsonEncode(message.data)}');
      onMessage(message);
    });
  }

  /// Sincroniza la lista de medicamentos del día al reloj
  Future<bool> syncMedicamentosToWear(List<Map<String, dynamic>> medicamentos) async {
    try {
      final data = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'medicamentos': medicamentos,
      };
      
      return await sendDataToWear(
        path: '/medicamentos/hoy',
        data: data,
      );
    } catch (e) {
      print('❌ Error sincronizando medicamentos: $e');
      return false;
    }
  }

  /// Envía un recordatorio al reloj para que genere notificación
  Future<bool> sendReminderToWear({
    required String medicamentoId,
    required String nombre,
    required String dosis,
    required DateTime hora,
  }) async {
    try {
      final data = {
        'medicamento_id': medicamentoId,
        'nombre': nombre,
        'dosis': dosis,
        'hora': hora.toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      return await sendUrgentMessageToWear(
        path: '/recordatorio/tomar',
        data: data,
      );
    } catch (e) {
      print('❌ Error enviando recordatorio: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _messageStream.close();
    super.onClose();
  }
}

/// Modelo para mensajes provenientes del reloj
class WearableMessage {
  final String path;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WearableMessage({
    required this.path,
    required this.data,
    required this.timestamp,
  });

  // Acciones comunes desde el reloj
  bool get isMedicamentoTomado => path == '/medicamento/tomado';
  bool get isMedicamentoPospuesto => path == '/medicamento/pospuesto';
  
  String? get medicamentoId => data['medicamento_id'];
  DateTime? get hora => data['hora'] != null 
    ? DateTime.parse(data['hora']) 
    : null;
}
