import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/show_snack.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      showSnack(context, "Lütfen tüm alanları doldurun", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      // Başarılı ise AuthGate yönlendirecek
    } catch (e) {
      if(mounted) showSnack(context, _auth.mapAuthError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty) {
       try {
         await _auth.resetPassword(email);
         if(mounted) showSnack(context, "$email adresine sıfırlama linki gönderildi.");
       } catch (e) {
         if(mounted) showSnack(context, _auth.mapAuthError(e), isError: true);
       }
    } else {
      // Dialog ile sor
      final controller = TextEditingController();
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("Şifre Sıfırla"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'E-posta')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(onPressed: () async {
            Navigator.pop(ctx);
            if(controller.text.isNotEmpty) {
               try {
                 await _auth.resetPassword(controller.text.trim());
                 if(mounted) showSnack(context, "Sıfırlama linki gönderildi.");
               } catch (e) {
                 if(mounted) showSnack(context, _auth.mapAuthError(e), isError: true);
               }
            }
          }, child: const Text("Gönder")),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Giriş Yap")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.local_florist, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                decoration: const InputDecoration(labelText: "Şifre", border: OutlineInputBorder()),
                obscureText: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _forgotPassword, child: const Text("Şifremi Unuttum")),
              ),
              const SizedBox(height: 16),
              _isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text("Giriş Yap"),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), 
                child: const Text("Hesabın yok mu? Kayıt Ol")
              ),
            ],
          ),
        ),
      ),
    );
  }
}