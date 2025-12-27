import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Hassas işlemler için yeniden doğrulama yardımcısı
  Future<bool> reauthenticate(BuildContext context) async {
    final passwordController = TextEditingController();
    bool? success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Güvenlik Doğrulaması'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu işlem için mevcut şifrenizi girmeniz gerekiyor.'),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (currentUser?.email == null) throw Exception("Kullanıcı yok");
                AuthCredential credential = EmailAuthProvider.credential(
                  email: currentUser!.email!,
                  password: passwordController.text,
                );
                await currentUser!.reauthenticateWithCredential(credential);
                Navigator.pop(ctx, true);
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('Doğrula'),
          ),
        ],
      ),
    );
    return success ?? false;
  }

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }
  
  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }
  
  String mapAuthError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found': return 'Kullanıcı bulunamadı.';
        case 'wrong-password': return 'Hatalı şifre.';
        case 'email-already-in-use': return 'Bu e-posta zaten kullanımda.';
        case 'invalid-email': return 'Geçersiz e-posta formatı.';
        case 'weak-password': return 'Şifre çok zayıf.';
        case 'requires-recent-login': return 'Güvenlik gereği tekrar giriş yapmalısınız.';
        default: return 'Bir hata oluştu: ${e.message}';
      }
    }
    return 'Bilinmeyen hata: $e';
  }
}