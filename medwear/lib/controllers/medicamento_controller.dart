import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/medicamento_model.dart';
import '../models/toma_model.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class MedicamentoController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final NotificationService _notificationService = NotificationService();

  final RxList<Medicamento> medicamentos = <Medicamento>[].obs;
  final RxList<Toma> historialTomas = <Toma>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    cargarMedicamentos();
    cargarHistorial();
    solicitarPermisosNotificaciones();
  }

  Future<void> solicitarPermisosNotificaciones() async {
    await _notificationService.solicitarPermisos();
  }

  void cargarMedicamentos() {
    _firebaseService.obtenerMedicamentosActivos().listen(
      (lista) {
        medicamentos.value = lista;
      },
      onError: (e, st) {
        _mostrarMensaje('Error', 'No se pudieron cargar los medicamentos');
      },
      cancelOnError: false,
    );
  }

  void cargarHistorial({int dias = 30}) {
    _firebaseService.obtenerHistorialTomas(dias: dias).listen(
      (lista) {
        historialTomas.value = lista;
      },
      onError: (e, st) {
        _mostrarMensaje('Error', 'No se pudo cargar el historial');
      },
      cancelOnError: false,
    );
  }

  Future<bool> agregarMedicamento(Medicamento medicamento) async {
    try {
      isLoading.value = true;
      final id = await _firebaseService.crearMedicamento(medicamento);
      
      final medicamentoConId = medicamento.copyWith(id: id);
      await _notificationService.programarNotificacionesMedicamento(
          medicamentoConId);

      _mostrarMensaje('Éxito', 'Medicamento agregado correctamente');
      return true;
    } catch (e) {
      _mostrarMensaje('Error', 'No se pudo agregar el medicamento: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> actualizarMedicamento(Medicamento medicamento) async {
    try {
      isLoading.value = true;
      await _firebaseService.actualizarMedicamento(medicamento);
      
      await _notificationService.programarNotificacionesMedicamento(medicamento);

      _mostrarMensaje('Éxito', 'Medicamento actualizado correctamente');
      return true;
    } catch (e) {
      _mostrarMensaje('Error', 'No se pudo actualizar el medicamento: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> desactivarMedicamento(String id) async {
    try {
      isLoading.value = true;
      await _firebaseService.desactivarMedicamento(id);
      
      await _notificationService.cancelarNotificacionesMedicamento(id);

      _mostrarMensaje('Éxito', 'Medicamento desactivado');
      return true;
    } catch (e) {
      _mostrarMensaje('Error', 'No se pudo desactivar el medicamento: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
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

      final mensaje = estado == EstadoToma.tomado
          ? 'Toma registrada correctamente'
          : estado == EstadoToma.pospuesto
              ? 'Toma pospuesta'
              : 'Toma omitida';

      _mostrarMensaje('Registro', mensaje);
      return true;
    } catch (e) {
      _mostrarMensaje('Error', 'No se pudo registrar la toma: $e');
      return false;
    }
  }

  Future<void> marcarComoTomado(Medicamento medicamento) async {
    await registrarToma(medicamento, EstadoToma.tomado);
  }

  Future<void> postponerToma(Medicamento medicamento) async {
    await registrarToma(medicamento, EstadoToma.pospuesto);
    
    final fechaHora = DateTime.now().add(const Duration(minutes: 10));
    await _notificationService.programarNotificacionMedicamento(
      medicamento,
      fechaHora,
    );

    _mostrarMensaje('Pospuesto', 'Te recordaremos en 10 minutos');
  }

  List<Medicamento> obtenerMedicamentosHoy() {
    final hoy = DateTime.now();
    final diaSemana = hoy.weekday;

    return medicamentos.where((med) {
      // Verificar que esté activo
      if (!med.activo) return false;

      // Verificar que sea un día del tratamiento
      if (!med.diasSemana.contains(diaSemana)) return false;

      // Verificar que esté dentro del rango de fechas
      if (hoy.isBefore(med.fechaInicio)) return false;
      if (med.fechaFin != null && hoy.isAfter(med.fechaFin!)) return false;

      return true;
    }).toList();
  }

  Future<Map<String, dynamic>> obtenerEstadisticas({int dias = 7}) async {
    return await _firebaseService.obtenerEstadisticas(dias: dias);
  }

  Future<void> mostrarNotificacionPrueba() async {
    await _notificationService.mostrarNotificacionInmediata(
      'Prueba de Notificación',
      'Las notificaciones están funcionando correctamente',
    );
  }

  void _mostrarMensaje(String titulo, String mensaje) {
    if (kIsWeb) {
      print('$titulo: $mensaje');
    } else {
      Get.snackbar(
        titulo,
        mensaje,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
