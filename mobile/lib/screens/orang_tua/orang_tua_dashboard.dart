import 'package:flutter/material.dart';

import '../../data/orang_tua_api_mapper.dart';
import '../../data/orang_tua_preview_data.dart';
import '../../services/api_service.dart';
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
  late OrangTuaDashboardData _data;
  bool _isLoading = false;
  bool _sessionExpired = false;
  String? _errorMessage;
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _data = widget.demoMode
        ? OrangTuaDashboardData.demo
        : OrangTuaDashboardData.empty;
    if (!widget.demoMode) _loadData();
  }

  Future<void> _loadData({String? childId}) async {
    if (!mounted || widget.demoMode) return;
    setState(() {
      _isLoading = true;
      _sessionExpired = false;
      _errorMessage = null;
    });

    try {
      final baseResponses = await Future.wait<dynamic>([
        ApiService.get('/users/me'),
        ApiService.get('/parent/children'),
        ApiService.get('/parent/announcements'),
      ]);
      final parent = _objectData(baseResponses[0], 'profil orang tua');
      final children = _responseData(baseResponses[1], 'daftar anak');
      final announcements = _responseData(baseResponses[2], 'pengumuman');
      final linkedChildren = OrangTuaApiMapper.linkedStudents(children);
      final requestedChildId = childId ?? _selectedChildId;
      final selectedChildIsLinked = linkedChildren.any(
        (child) => child.id == requestedChildId,
      );
      final selectedChildId = selectedChildIsLinked
          ? requestedChildId
          : linkedChildren.isEmpty
          ? null
          : linkedChildren.first.id;

      if (selectedChildId == null) {
        final data = OrangTuaApiMapper.fromResponses(
          parent: parent,
          children: children,
          announcements: announcements,
        );
        if (!mounted) return;
        setState(() {
          _data = data;
          _selectedChildId = null;
          _isLoading = false;
        });
        return;
      }

      final query = Uri.encodeQueryComponent(selectedChildId);
      final childResponses = await Future.wait<dynamic>([
        ApiService.get('/parent/child/profile?child_id=$query'),
        ApiService.get('/parent/child/summary?child_id=$query'),
        ApiService.get('/parent/child/attendances?child_id=$query'),
        ApiService.get('/parent/child/schedules?child_id=$query'),
        ApiService.get('/parent/child/ukt?child_id=$query'),
        ApiService.get('/parent/child/documents?child_id=$query'),
      ]);
      final data = OrangTuaApiMapper.fromResponses(
        parent: parent,
        children: children,
        announcements: announcements,
        childProfile: _objectData(childResponses[0], 'profil anak'),
        academicSummary: _objectData(childResponses[1], 'ringkasan akademik'),
        attendanceRecords: _responseData(childResponses[2], 'riwayat absensi'),
        schedules: _responseData(childResponses[3], 'jadwal'),
        uktRecords: _responseData(childResponses[4], 'data UKT'),
        documents: _responseData(childResponses[5], 'dokumen anak'),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _selectedChildId = selectedChildId;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Gagal memuat data akun orang tua: $error');
      if (!mounted) return;
      setState(() {
        _sessionExpired = error is SessionExpiredException;
        _errorMessage = ApiService.errorMessage(
          error,
          fallback: 'Data belum dapat dimuat. Periksa koneksi lalu coba lagi.',
        );
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _objectData(dynamic response, String name) {
    final value = _responseData(response, name);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('Format $name tidak valid.');
  }

  dynamic _responseData(dynamic response, String name) {
    if (response is! Map || !response.containsKey('data')) {
      throw FormatException('Respons $name tidak valid.');
    }
    return response['data'];
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: OrangTuaColors.emerald),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: OrangTuaColors.muted,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: _sessionExpired
                    ? () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false)
                    : _loadData,
                child: Text(_sessionExpired ? 'Kembali ke login' : 'Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_data.linkedChildren.length > 1) _buildChildSelector(),
        Expanded(
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
      ],
    );
  }

  Widget _buildChildSelector() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: DropdownButtonFormField<String>(
      initialValue: _selectedChildId,
      decoration: InputDecoration(
        labelText: 'Pilih anak',
        filled: true,
        fillColor: OrangTuaColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: OrangTuaColors.border),
        ),
      ),
      items: _data.linkedChildren
          .map(
            (child) => DropdownMenuItem(
              value: child.id,
              child: Text(
                '${child.name} · ${child.nim}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (id) {
        if (id != null && id != _selectedChildId) _loadData(childId: id);
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: OrangTuaColors.cream,
    body: SafeArea(child: _buildBody()),
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
