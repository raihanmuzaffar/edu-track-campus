import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'absensi_tab.dart';
import 'beranda_tab.dart';
import 'informasi_tab.dart';
import 'keuangan_tab.dart';
import 'jadwal_tab.dart';
import 'nilai_tab.dart';
import 'pengumuman_tab.dart';
import 'profil_anak_tab.dart';
import 'profil_orang_tua_tab.dart';
import 'widgets/orang_tua_theme.dart';

class OrangTuaDashboard extends StatefulWidget {
  const OrangTuaDashboard({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  State<OrangTuaDashboard> createState() => _OrangTuaDashboardState();
}

class _OrangTuaDashboardState extends State<OrangTuaDashboard> {
  int _selectedIndex = 0;

  late final OrangTuaDashboardData _data = widget.demoMode
      ? OrangTuaDashboardData.demo
      : OrangTuaDashboardData.empty;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: OrangTuaColors.cream,
    body: SafeArea(
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          BerandaTab(data: _data, onNavigate: _selectTab),
          ProfilAnakTab(data: _data),
          NilaiTab(data: _data),
          AbsensiTab(data: _data),
          JadwalTab(data: _data),
          PengumumanTab(data: _data),
          ProfilOrangTuaTab(data: _data, isDemo: widget.demoMode),
          InformasiTab(data: _data, onNavigate: _selectTab),
          KeuanganTab(data: _data),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: switch (_selectedIndex) {
        0 => 0,
        1 => 1,
        2 => 2,
        6 => 4,
        _ => 3,
      },
      onDestinationSelected: (index) {
        _selectTab(switch (index) {
          0 => 0,
          1 => 1,
          2 => 2,
          3 => 7,
          _ => 6,
        });
      },
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      height: 70,
      indicatorColor: OrangTuaColors.paleGreen,
      backgroundColor: OrangTuaColors.surface,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Anak',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_graph_outlined),
          selectedIcon: Icon(Icons.auto_graph_rounded),
          label: 'Nilai',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Info',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_circle_outlined),
          selectedIcon: Icon(Icons.account_circle_rounded),
          label: 'Profil',
        ),
      ],
    ),
  );
}
