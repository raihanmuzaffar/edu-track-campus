import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/reset_success_screen.dart';
import 'screens/mahasiswa/mahasiswa_dashboard.dart'; 
import 'screens/dosen/dosen_dashboard.dart'; // <--- TAMBAHAN IMPORT DOSEN

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTrack Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF145A4A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF145A4A),
          primary: const Color(0xFF145A4A),
          secondary: const Color(0xFFD97736),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF145A4A), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97736),
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/reset-success': (context) => const ResetSuccessScreen(),
        
        // Rute Dashboard Mahasiswa
        '/mahasiswa': (context) => const MahasiswaDashboard(), 

        // Rute Dashboard Dosen (SUDAH DIPERBARUI)
        '/dosen': (context) => const DosenDashboard(), 

        // Rute Dummy untuk role lain (sementara)
        '/orangtua': (context) => const DummyDashboard(title: 'Dashboard Orang Tua', color: Colors.purple),
      },
    );
  }
}

// ==========================================
// HALAMAN DUMMY (SEMENTARA)
// ==========================================
class DummyDashboard extends StatelessWidget {
  final String title;
  final Color color;
  
  const DummyDashboard({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title), 
        backgroundColor: color, 
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: color),
            const SizedBox(height: 20),
            Text('Berhasil Masuk!', style: Theme.of(context).textTheme.headlineSmall),
            Text('Role: $title', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}