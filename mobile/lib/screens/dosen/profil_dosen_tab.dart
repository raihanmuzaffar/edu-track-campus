import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfilDosenTab extends StatefulWidget {
  const ProfilDosenTab({super.key});

  @override
  State<ProfilDosenTab> createState() => _ProfilDosenTabState();
}

class _ProfilDosenTabState extends State<ProfilDosenTab> {
  String _email = '-';
  bool _isLoading = true;
  final Color primaryColor = const Color(0xFF145A4A);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final meResponse = await ApiService.get('/users/me');
    setState(() {
      _email = meResponse['data']['email'] ?? 'Email tidak ditemukan';
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: primaryColor));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil Dosen', style: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFF145A4A), child: Icon(Icons.person, size: 40, color: Colors.white)),
            const SizedBox(height: 16),
            Text(_email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }
}