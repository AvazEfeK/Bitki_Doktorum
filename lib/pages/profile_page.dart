import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/show_snack.dart';
import '../main.dart'; // themeController için
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userSvc = UserService();
  final _authSvc = AuthService();
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _authSvc.currentUser?.uid;
    if (uid == null) return;
    try {
      final data = await _userSvc.getUserDoc(uid);
      if (mounted) setState(() { _userData = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _authSvc.logout();
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hesabı Sil"),
        content: const Text("Bu işlem geri alınamaz. Emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        await _authSvc.deleteAccount();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (!mounted) return;
          final reauthSuccess = await _authSvc.reauthenticate(context);
          if (reauthSuccess) {
             // Tekrar dene
             try {
               await _userSvc.deleteUserDoc(_authSvc.currentUser!.uid); // Önce doc sil
               await _authSvc.deleteAccount();
             } catch (e2) {
               if(mounted) showSnack(context, "Silme hatası: $e2", isError: true);
             }
          }
        } else {
          if(mounted) showSnack(context, _authSvc.mapAuthError(e), isError: true);
        }
      } catch (e) {
        if(mounted) showSnack(context, "Hata: $e", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authSvc.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: Icon(themeController.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeController.toggleTheme(themeController.themeMode != ThemeMode.dark),
          )
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 16),
              Center(child: Text(user.email ?? "", style: Theme.of(context).textTheme.bodyLarge)),
              const SizedBox(height: 8),
              Center(child: Text("${_userData?['firstName'] ?? ''} ${_userData?['lastName'] ?? ''}", style: Theme.of(context).textTheme.headlineSmall)),
              const SizedBox(height: 32),
              
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Profili Düzenle"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(userData: _userData)));
                  _loadData();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text("Çıkış Yap"),
                onTap: _logout,
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Hesabı Sil"),
                onTap: _deleteAccount,
              ),
            ],
          ),
    );
  }
}