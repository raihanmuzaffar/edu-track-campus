import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Fungsi untuk menyimpan status bahwa user sudah melihat onboarding
  Future<void> _finishOnboarding(BuildContext context, String routeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false); // Tandai bahwa onboarding selesai
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Logo & Tombol Login Atas
              Row(
                children: [
                  const Icon(Icons.school, color: Color(0xFF145A4A), size: 30),
                  const SizedBox(width: 10),
                  const Text('EduTrack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finishOnboarding(context, '/login'), // Gunakan fungsi
                    child: const Text('Login', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Spacer(),
              
              // Ilustrasi
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories, size: 120, color: Color(0xFF145A4A)),
                ),
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'Welcome to EduTrack.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF145A4A)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Platform terpadu untuk memantau akademik, nilai, dan kehadiran Anda dengan mudah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              
              const Spacer(),
              
              // Tombol Buat Akun
              ElevatedButton(
                onPressed: () => _finishOnboarding(context, '/register'), // Gunakan fungsi
                child: const Text('Create an Account'),
              ),
              const SizedBox(height: 16),
              
              const Text('Or', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              
              // Tombol Login (Outline)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  side: const BorderSide(color: Color(0xFF145A4A)),
                ),
                onPressed: () => _finishOnboarding(context, '/login'), // Gunakan fungsi
                child: const Text('Login', style: TextStyle(color: Color(0xFF145A4A), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}