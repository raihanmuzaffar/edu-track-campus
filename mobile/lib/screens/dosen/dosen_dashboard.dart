import 'package:flutter/material.dart';
import 'beranda_dosen_tab.dart';
import 'absensi_dosen_tab.dart';
import 'nilai_dosen_tab.dart';
import 'profil_dosen_tab.dart';

class DosenDashboard extends StatefulWidget {
  const DosenDashboard({super.key});

  @override
  State<DosenDashboard> createState() => _DosenDashboardState();
}

class _DosenDashboardState extends State<DosenDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const BerandaDosenTab(),
    const AbsensiDosenTab(),
    const NilaiDosenTab(),
    const ProfilDosenTab(),
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
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Color(0xFF145A4A)),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade, color: Color(0xFF145A4A)),
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