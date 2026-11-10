import 'package:flutter/material.dart';

import 'screens/mahasiswa/mahasiswa_dashboard.dart';

void main() {
  runApp(const MahasiswaDemoApp());
}

class MahasiswaDemoApp extends StatelessWidget {
  const MahasiswaDemoApp({super.key});

  static const _navy = Color(0xFF082D5C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTrack Mahasiswa · DEMO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _navy,
          primary: _navy,
          secondary: const Color(0xFF159D9B),
          surface: Colors.white,
        ),
      ),
      home: const MahasiswaDashboard(demoMode: true),
    );
  }
}
