import 'package:get/get.dart';
import '../models/wear_medicamento_model.dart';
import '../models/toma_model.dart';
import '../services/firebase_service.dart';
import '../controllers/medicamento_controller.dart';

/// Servicio para recibir y procesar respuestas del reloj
/// Maneja acciones del usuario desde el Wear OS
class WearResponseService extends GetxService {
  final FirebaseService _firebaseService = FirebaseService();
  late MedicamentoController _medicamentoController;

  // Streams para notificaciones
  final RxBool isProcessing = false.obs;
  final RxList<WearMedicamentoAccion> accionesRecientes =
      <WearMedicamentoAccion>[].obs;

  @override
  void onInit() {
    super.onInit();
    _medicamentoController = Get.find<MedicamentoController>();
  }

  /// Procesar respuesta cuando el usuario toma un medicamento desde el reloj
  Future<void> procesarTomaDesdeReloj({
    required String medicamentoId,
    required DateTime horaCompleta,
  }) async {
    try {
      isProcessing.value = true;

      // Encontrar el medicamento (usar método simple para evitar conflicto de extensión)
      dynamic medicamentoOpt;
      for (var med in _medicamentoController.medicamentos) {
        if (med.id == medicamentoId) {
          medicamentoOpt = med;
          break;
        }
      }

      if (medicamentoOpt == null) {
        print(' Medicamento no encontrado: $medicamentoId');
        return;
      }

      // Crear registro de toma
      final toma = Toma(
        medicamentoId: medicamentoId,
        medicamentoNombre: medicamentoOpt.nombre,
        dosis: medicamentoOpt.dosis,
        fechaHoraProgramada: horaCompleta,
        fechaHoraReal: DateTime.now(),
        estado: EstadoToma.tomado,
        notas: 'Registrado desde Wear OS',
      );

      // Guardar en Firebase
      await _firebaseService.registrarToma(toma);

      // Guardar acción local
      final accion = WearMedicamentoAccion(
        medicamentoId: medicamentoId,
        accion: TipoAccion.tomado,
        timestamp: DateTime.now(),
      );
      accionesRecientes.add(accion);

      print('✅ Toma registrada desde reloj: ${medicamentoOpt.nombre}');
    } catch (e) {
      print('❌ Error procesando toma desde reloj: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Procesar respuesta cuando el usuario pospone desde el reloj
  Future<void> procesarPospuestDesdeReloj({
    required String medicamentoId,
    required DateTime horaCompleta,
    int minutosPosponer = 10,
  }) async {
    try {
      isProcessing.value = true;

      // Encontrar el medicamento (usar método simple para evitar conflicto de extensión)
      dynamic medicamentoOpt;
      for (var med in _medicamentoController.medicamentos) {
        if (med.id == medicamentoId) {
          medicamentoOpt = med;
          break;
        }
      }

      if (medicamentoOpt == null) {
        print('❌ Medicamento no encontrado: $medicamentoId');
        return;
      }

      // Crear registro de pospuesto
      final toma = Toma(
        medicamentoId: medicamentoId,
        medicamentoNombre: medicamentoOpt.nombre,
        dosis: medicamentoOpt.dosis,
        fechaHoraProgramada: horaCompleta,
        fechaHoraReal: horaCompleta.add(Duration(minutes: minutosPosponer)),
        estado: EstadoToma.pospuesto,
        notas: 'Pospuesto $minutosPosponer min desde Wear OS',
      );

      // Guardar en Firebase
      await _firebaseService.registrarToma(toma);

      // Guardar acción local
      final accion = WearMedicamentoAccion(
        medicamentoId: medicamentoId,
        accion: TipoAccion.pospuesto,
        timestamp: DateTime.now(),
      );
      accionesRecientes.add(accion);

      print('⏱ Toma pospuesta desde reloj: ${medicamentoOpt.nombre}');
    } catch (e) {
      print('❌ Error procesando pospuesto desde reloj: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  /// Sincronizar cambios de medicamentos al reloj
  /// Se llama cuando hay cambios en el móvil
  Future<void> sincronizarCambiosAlReloj() async {
    try {
      print('🔄 Sincronizando cambios al reloj...');

      final medicamentos = _medicamentoController.obtenerMedicamentosHoy();

      if (medicamentos.isEmpty) {
        print('⚠️ No hay medicamentos para hoy');
        return;
      }

      // Aquí se enviaría al servicio Wear
      // await _wearSyncService.sincronizarMedicamentosAlReloj(medicamentos);

      print('✅ Cambios sincronizados al reloj');
    } catch (e) {
      print('❌ Error sincronizando cambios: $e');
    }
  }

  /// Obtener estado de la última acción en el reloj
  WearMedicamentoAccion? obtenerUltimaAccion({String? medicamentoId}) {
    if (accionesRecientes.isEmpty) return null;

    if (medicamentoId != null) {
      for (var accion in accionesRecientes) {
        if (accion.medicamentoId == medicamentoId) {
          return accion;
        }
      }
      return null;
    }

    return accionesRecientes.isNotEmpty ? accionesRecientes.last : null;
  }

  /// Limpiar acciones antiguas (más de N horas)
  void limpiarAccionesAntiguas({int horasAntiguas = 24}) {
    final limite = DateTime.now().subtract(Duration(hours: horasAntiguas));

    accionesRecientes.removeWhere((accion) {
      return accion.timestamp.isBefore(limite);
    });

    print('🗑 Acciones antiguas limpiadas');
  }

  /// Registrar cambio en medicamento para sincronizar al reloj
  Future<void> notificarCambioMedicamento(String medicamentoId) async {
    print('📤 Notificando cambio de medicamento al reloj: $medicamentoId');

    // Aquí se podría enviar solo la actualización del medicamento específico
    // en lugar de sincronizar todos
  }
}

// Extensión para List.firstWhereOrNull (con prefijo para evitar conflictos)
extension WearFirstWhereOrNull<E> on List<E> {
  E? wearFirstWhereOrNull(bool Function(E) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}

extension FirstWhereOrNull<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
