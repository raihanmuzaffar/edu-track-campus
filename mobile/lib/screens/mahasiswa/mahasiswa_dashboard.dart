import 'package:flutter/material.dart';
import 'beranda_tab.dart';
import 'krs_tab.dart';
import 'absensi_tab.dart'; // Import tab baru
import 'nilai_tab.dart';
import 'profil_tab.dart';

class MahasiswaDashboard extends StatefulWidget {
  const MahasiswaDashboard({super.key});

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BerandaTab(),
    const KrsTab(),
    const AbsensiTab(), // Tambahan Tab Absensi
    const NilaiTab(),
    const ProfilTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        indicatorColor: const Color(0xFF145A4A).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF145A4A)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book, color: Color(0xFF145A4A)),
            label: 'KRS',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline), // Ikon Absensi
            selectedIcon: Icon(Icons.check_circle, color: Color(0xFF145A4A)),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF145A4A)),
            label: 'Nilai',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF145A4A)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}