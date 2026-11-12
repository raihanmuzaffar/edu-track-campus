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
  final Set<int> _visitedTabs = {0};

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const BerandaDosenTab();
      case 1:
        return const AbsensiDosenTab();
      case 2:
        return const NilaiDosenTab();
      case 3:
        return const ProfilDosenTab();
      default:
        return const SizedBox.shrink();
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List<Widget>.generate(
          4,
          (index) => _visitedTabs.contains(index)
              ? _buildTab(index)
              : const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
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
