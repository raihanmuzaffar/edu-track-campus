import 'package:flutter/material.dart';
import 'beranda_tab.dart';
import 'krs_tab.dart';
import 'absensi_tab.dart'; // Import tab baru
import 'nilai_tab.dart';
import 'profil_tab.dart';

class MahasiswaDashboard extends StatefulWidget {
  const MahasiswaDashboard({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  State<MahasiswaDashboard> createState() => _MahasiswaDashboardState();
}

class _MahasiswaDashboardState extends State<MahasiswaDashboard> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          BerandaTab(
            demoMode: widget.demoMode,
            onNavigate: _selectTab,
          ),
          widget.demoMode ? const KrsTab.preview() : const KrsTab(),
          AbsensiTab(demoMode: widget.demoMode),
          NilaiTab(demoMode: widget.demoMode),
          ProfilTab(demoMode: widget.demoMode),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        indicatorColor: const Color(0xFFD7F1F0),
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF159D9B)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book, color: Color(0xFF159D9B)),
            label: 'KRS',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Color(0xFF159D9B)),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF159D9B)),
            label: 'Nilai',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF159D9B)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}