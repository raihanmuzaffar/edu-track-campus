import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/mahasiswa_demo_data.dart';
import '../../services/api_service.dart';

class ProfilTab extends StatefulWidget {
  const ProfilTab({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  String _email = '-';
  String _role = '-';
  bool _isLoading = true;
  final Color primaryColor = const Color(0xFF082D5C);
  final Color textPrimary = const Color(0xFF1F2937);
  final Color textSecondary = const Color(0xFF6B7280);
  final Color borderColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.demoMode) {
      setState(() {
        _email = MahasiswaDemoData.student['email']! as String;
        _role = MahasiswaDemoData.student['role']! as String;
        _isLoading = false;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _email = prefs.getString('email') ?? 'Email tidak ditemukan';
      _role = prefs.getString('role') ?? 'Role tidak ditemukan';
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (widget.demoMode) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('DEMO • Sesi lokal tidak mengubah akun atau server.'),
          ),
        );
        return;
      }
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profil Saya',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.demoMode) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5D6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFC83D)),
                  ),
                  child: const Text(
                    'DEMO · DATA ILUSTRASI',
                    style: TextStyle(
                      color: Color(0xFF082D5C),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF082D5C),
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Mahasiswa',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(_email, style: TextStyle(fontSize: 14, color: textSecondary)),

            const SizedBox(height: 30),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  // PERBAIKAN: Menghapus const karena menggunakan primaryColor
                  ListTile(
                    leading: Icon(Icons.badge_outlined, color: primaryColor),
                    title: const Text('Role Akses'),
                    trailing: Text(
                      _role.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  // Ini biarkan const karena semua warnanya const
                  const ListTile(
                    leading: Icon(
                      Icons.school_outlined,
                      color: Color(0xFF082D5C),
                    ),
                    title: Text('Program Studi'),
                    trailing: Text(
                      'TRKJ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Keluar Aplikasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
