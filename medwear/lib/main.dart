import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'app.dart';

// imports específicos para reloj
import 'controllers/medicamento_controller.dart';
import 'services/wear_sync_service.dart';
import 'pages/wear_home_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[ARRANQUE] WidgetsFlutterBinding inicializado');

    // Captura global de errores de Flutter
    FlutterError.onError = (details) {
      debugPrint('FlutterError: \n${details.exceptionAsString()}');
      debugPrint(details.stack?.toString());
    };

    try {
      await initializeDateFormatting('es', null);
      debugPrint('[ARRANQUE] Formato de fechas listo');
    } catch (e) {
      debugPrint('Error inicializando formato de fechas: $e');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[ARRANQUE] Firebase inicializado');
    } catch (e, st) {
      debugPrint('Error inicializando Firebase: $e');
      debugPrint(st.toString());
    }

    if (!kIsWeb) {
      try {
        const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
        );
        await flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse:
              (NotificationResponse response) {},
        );
        debugPrint('[ARRANQUE] Notificaciones inicializadas');
      } catch (e) {
        debugPrint('Error inicializando notificaciones: $e');
      }
    }

    debugPrint('[ARRANQUE] Lanzando runApp');
    runApp(const MedWearApp());
    debugPrint('[ARRANQUE] runApp completado');
  }, (error, stack) {
    debugPrint('Excepción no capturada: $error');
    debugPrint(stack.toString());
  });
}

class MedWearApp extends StatelessWidget {
  const MedWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Detectar tamaño de pantalla: si es muy pequeña, asumimos reloj
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;
        final bool isWatch = shortestSide < 300; // umbral simple

        if (isWatch) {
          // Registrar dependencias necesarias para Wear OS
          if (!Get.isRegistered<MedicamentoController>()) {
            Get.put(MedicamentoController(), permanent: true);
          }
          if (!Get.isRegistered<WearSyncService>()) {
            Get.put(WearSyncService(), permanent: true);
          }

          // App específica del reloj
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            home: const WearHomePage(),
          );
        } else {
          // App normal (móvil / tablet)
          return const App();
        }
      },
    );
  }
}