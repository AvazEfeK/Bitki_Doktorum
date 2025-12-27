// Placeholder file.
// GERÇEK PROJEDE: flutterfire configure komutu bu dosyanın üzerine yazacak.
// Bu dosya sadece initial derleme hatası almamak için var.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web şu an desteklenmiyor.');
    }
    // Android/iOS placeholder. Configure komutu sonrası burası dolacak.
    return const FirebaseOptions(
      apiKey: 'PLACEHOLDER-API-KEY',
      appId: 'PLACEHOLDER-APP-ID',
      messagingSenderId: 'PLACEHOLDER-SENDER-ID',
      projectId: 'PLACEHOLDER-PROJECT-ID',
    );
  }
}