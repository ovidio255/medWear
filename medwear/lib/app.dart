import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'es_ES';
    
    return GetMaterialApp(
      title: 'MedWear',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<void>(
        future: _ensureFirebaseReady(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _Splash();
          }
          if (snap.hasError) {
            return _StartupError(error: snap.error);
          }
          return const HomePage();
        },
      ),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _ensureFirebaseReady() async {
    // Evita excepciones si ya fue inicializado en main()
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Inicializando...')
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  final Object? error;
  const _StartupError({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('No se pudo inicializar la app'),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
