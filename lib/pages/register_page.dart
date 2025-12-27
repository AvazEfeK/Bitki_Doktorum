import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/show_snack.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  final _auth = AuthService();
  final _userSvc = UserService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      showSnack(context, "Zorunlu alanları doldurun", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.register(_emailCtrl.text.trim(), _passCtrl.text.trim());
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userSvc.createUserDoc(user.uid, {
          'firstName': _nameCtrl.text.trim(),
          'lastName': _surnameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        });
      }
      if(mounted) Navigator.pop(context); // Login'e dön veya AuthGate otomatik yakalar
    } catch (e) {
      if(mounted) showSnack(context, _auth.mapAuthError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Ad", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _surnameCtrl, decoration: const InputDecoration(labelText: "Soyad", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "E-posta *", border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: "Şifre *", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 24),
            _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Kayıt Ol"),
                  ),
          ],
        ),
      ),
    );
  }
}