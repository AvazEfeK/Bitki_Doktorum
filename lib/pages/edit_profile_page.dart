import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/show_snack.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _userSvc = UserService();
  final _authSvc = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _nameCtrl.text = widget.userData!['firstName'] ?? '';
      _surnameCtrl.text = widget.userData!['lastName'] ?? '';
      _phoneCtrl.text = widget.userData!['phone'] ?? '';
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final uid = _authSvc.currentUser?.uid;
      if (uid != null) {
        await _userSvc.updateUserDoc(uid, {
          'firstName': _nameCtrl.text.trim(),
          'lastName': _surnameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        });
        if(mounted) {
          showSnack(context, "Profil güncellendi.");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if(mounted) showSnack(context, "Hata: $e", isError: true);
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Düzenle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Ad", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _surnameCtrl, decoration: const InputDecoration(labelText: "Soyad", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 24),
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)), child: const Text("Kaydet")),
          ],
        ),
      ),
    );
  }
}