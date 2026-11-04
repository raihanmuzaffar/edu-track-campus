import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Beri jeda 2 detik untuk efek visual
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (!mounted) return;

    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, '/welcome');
    } else if (token != null && role != null) {
      if (role == 'mahasiswa') {
        Navigator.pushReplacementNamed(context, '/mahasiswa');
      } else if (role == 'dosen') {
        Navigator.pushReplacementNamed(context, '/dosen');
      } else if (role == 'orangtua') {
        Navigator.pushReplacementNamed(context, '/orangtua');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF145A4A), // Hijau Tua
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- BAGIAN YANG DIUBAH ---
            // Menggunakan gambar dari assets, bukan Icon bawaan
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white, // Background putih di belakang logo
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Image.asset(
                'assets/logo.png', 
                fit: BoxFit.contain, // Agar gambar tidak terpotong
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EduTrack Campus',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.white, 
                letterSpacing: 1.5
              ),
            ),
          ],
        ),
      ),
    );
  }
}