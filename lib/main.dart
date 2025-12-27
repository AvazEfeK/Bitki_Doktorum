import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app_keys.dart';
import 'controllers/theme_controller.dart';
import 'pages/auth_gate.dart';
import 'pages/init_error_page.dart';

// Global Servis Instance'ları
late final ThemeController themeController;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("Global Flutter Error: ${details.exception}");
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Hata oluştu: ${details.exception}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    };

    try {
      await dotenv.load(fileName: ".env");

      // --- DÜZELTME BURADA ---
      // Firebase'i başlatmayı dene, eğer "zaten var" hatası verirse yut ve devam et.
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
      } catch (e) {
        // Eğer hata "duplicate-app" içeriyorsa bu bir sorun değil, devam et.
        if (!e.toString().contains('duplicate-app') && !e.toString().contains('default')) {
          rethrow; // Başka bir hataysa fırlat
        }
      }
      // -----------------------

      themeController = ThemeController();
      await themeController.loadTheme();

      runApp(const MyApp());
      
    } catch (e) {
      runApp(InitErrorPage(error: e.toString()));
    }

  }, (error, stack) {
    debugPrint("Async Error: $error");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Bitki Doktorum',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}