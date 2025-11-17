
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

/// Servicio para notificaciones optimizadas para Wear OS
class WearNotificationService {
  static final WearNotificationService _instance =
      WearNotificationService._internal();

  factory WearNotificationService() {
    return _instance;
  }

  WearNotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  Future<void> initialize() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Configuración Android para Wear
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Crear canal de notificaciones para Wear
    await _crearCanalNotificacionesWear();
  }

  /// Crear canal de notificaciones optimizado para Wear OS
  Future<void> _crearCanalNotificacionesWear() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medwear_recordatorios',
      'Recordatorios de Medicamentos',
      description: 'Notificaciones de medicamentos para el reloj',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      showBadge: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Mostrar notificación de recordatorio en el reloj
  /// Esta notificación será optimizada para Wear OS
  Future<void> mostrarRecordatorioWear({
    required String medicamentoId,
    required String medicamentoNombre,
    required String dosis,
    required DateTime hora,
  }) async {
    final ahora = DateTime.now();
    final diferencia = hora.difference(ahora).inSeconds;

    if (diferencia < 0) return; // No mostrar si ya pasó la hora

    // Crear payload con acciones
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'medwear_recordatorios',
      'Recordatorios de Medicamentos',
      channelDescription: 'Notificaciones de medicamentos para el reloj',
      importance: Importance.high,
      priority: Priority.high,
      // Configuración para Wear OS
      enableVibration: true,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      
      // Habilitar acciones rápidas en Wear
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'tomado',
          '✓ Tomado',
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'posponer',
          '⏱ Posponer',
          cancelNotification: false,
        ),
      ],
      
      // Configurar para que aparezca en el reloj
      groupKey: 'medicamentos',
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      medicamentoId.hashCode,
      medicamentoNombre,
      'Dosis: $dosis - Hora: ${_formatearHora(hora)}',
      platformChannelSpecifics,
      payload: medicamentoId,
    );

    print('📢 Notificación Wear enviada: $medicamentoNombre');
  }

  /// Mostrar notificación urgente (vibración intensa)
  Future<void> mostrarNotificacionUrgente({
    required String titulo,
    required String mensaje,
    required String medicamentoId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'medwear_recordatorios',
      'Recordatorios de Medicamentos',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      medicamentoId.hashCode,
      titulo,
      mensaje,
      details,
      payload: medicamentoId,
    );
  }

  /// Programar recordatorio futuro
  Future<void> programarRecordatorio({
    required String medicamentoId,
    required String medicamentoNombre,
    required String dosis,
    required DateTime horaRecordatorio,
  }) async {
    // Calcular delay
    final ahora = DateTime.now();
    final diferencia = horaRecordatorio.difference(ahora);

    if (diferencia.isNegative) {
      print('⚠️ La hora ya pasó para el recordatorio');
      return;
    }

    // Programar con Timer (para pruebas)
    Timer(diferencia, () async {
      await mostrarRecordatorioWear(
        medicamentoId: medicamentoId,
        medicamentoNombre: medicamentoNombre,
        dosis: dosis,
        hora: horaRecordatorio,
      );
    });

    print('⏰ Recordatorio programado para $medicamentoNombre a '
        '${_formatearHora(horaRecordatorio)}');
  }

  /// Cancelar notificación
  Future<void> cancelarNotificacion(String medicamentoId) async {
    await _flutterLocalNotificationsPlugin.cancel(medicamentoId.hashCode);
  }

  /// Cancelar todas las notificaciones
  Future<void> cancelarTodas() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Callback cuando se toca la notificación
  void _onNotificationResponse(NotificationResponse response) {
    print('Notificación tocada: ${response.payload}');
    print('Acción: ${response.actionId}');

    if (response.actionId == 'tomado') {
      print('✓ Usuario marcó como tomado');
    } else if (response.actionId == 'posponer') {
      print('⏱ Usuario pospuso');
    }
  }

  /// Formatear hora para mostrar
  String _formatearHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  /// Obtener acciones de notificación (para Wear)
  static List<AndroidNotificationAction> obtenerAcciones() {
    return <AndroidNotificationAction>[
      const AndroidNotificationAction(
        'tomado',
        'Tomado',
        cancelNotification: true,
      ),
      const AndroidNotificationAction(
        'posponer_10',
        'Posponer 10 min',
        cancelNotification: false,
      ),
      const AndroidNotificationAction(
        'posponer_30',
        'Posponer 30 min',
        cancelNotification: false,
      ),
    ];
  }
}
