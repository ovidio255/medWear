import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../main.dart';
import '../models/medicamento_model.dart';

class NotificationService {
  static bool _tzInitialized = false;
  Future<void> _ensureTzInitialized() async {
    if (_tzInitialized || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      _tzInitialized = true;
    } catch (_) {}
  }
  Future<void> programarNotificacionMedicamento(
    Medicamento medicamento,
    DateTime fechaHora,
  ) async {
    if (kIsWeb) return;
    await _ensureTzInitialized();
    final notificationId = _generarNotificationId(
      medicamento.id ?? '',
      fechaHora,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicamentos_channel',
      'Recordatorios de Medicamentos',
      channelDescription:
          'Notificaciones para recordar la toma de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final scheduledDate = tz.TZDateTime.from(fechaHora, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '⏰ Hora de tomar medicamento',
      '${medicamento.nombre} - ${medicamento.dosis}',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: medicamento.id,
    );
  }

  Future<void> programarNotificacionesMedicamento(
      Medicamento medicamento) async {
    if (kIsWeb) return;
    await _ensureTzInitialized();
    
    if (!medicamento.activo) return;

    final ahora = DateTime.now();
    final fechaLimite = ahora.add(const Duration(days: 7));

    await cancelarNotificacionesMedicamento(medicamento.id ?? '');

    for (int dia = 0; dia < 7; dia++) {
      final fecha = ahora.add(Duration(days: dia));

      final diaSemana = fecha.weekday; // 1=Lunes, 7=Domingo en Dart
      if (!medicamento.diasSemana.contains(diaSemana)) continue;

      if (fecha.isBefore(medicamento.fechaInicio)) continue;
      if (medicamento.fechaFin != null &&
          fecha.isAfter(medicamento.fechaFin!)) continue;

      for (String horario in medicamento.horarios) {
        final partes = horario.split(':');
        if (partes.length != 2) continue;

        final hora = int.tryParse(partes[0]);
        final minuto = int.tryParse(partes[1]);
        if (hora == null || minuto == null) continue;

        final fechaHora = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hora,
          minuto,
        );

        if (fechaHora.isAfter(ahora) && fechaHora.isBefore(fechaLimite)) {
          await programarNotificacionMedicamento(medicamento, fechaHora);
        }
      }
    }
  }

  Future<void> cancelarNotificacionesMedicamento(String medicamentoId) async {
    if (kIsWeb) return;
    
    final activeNotifications =
        await flutterLocalNotificationsPlugin.getActiveNotifications();

    for (var notification in activeNotifications) {
      if (notification.payload == medicamentoId) {
        await flutterLocalNotificationsPlugin.cancel(notification.id ?? 0);
      }
    }
  }

  Future<void> cancelarTodasLasNotificaciones() async {
    if (kIsWeb) return;
    
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> mostrarNotificacionInmediata(
    String titulo,
    String mensaje, {
    String? payload,
  }) async {
    if (kIsWeb) {
      print('📱 Notificación (solo en Android): $titulo - $mensaje');
      return;
    }
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicamentos_channel',
      'Recordatorios de Medicamentos',
      channelDescription:
          'Notificaciones para recordar la toma de medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      titulo,
      mensaje,
      notificationDetails,
      payload: payload,
    );
  }

  int _generarNotificationId(String medicamentoId, DateTime fechaHora) {
    final idString = '$medicamentoId-${fechaHora.millisecondsSinceEpoch}';
    return idString.hashCode.abs() % 2147483647; // Max int32
  }

  Future<bool> solicitarPermisos() async {
    if (kIsWeb) return true;
    
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final result = await androidImplementation.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }
}
