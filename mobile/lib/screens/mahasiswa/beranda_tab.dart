import 'package:flutter/material.dart';

import '../../data/mahasiswa_demo_data.dart';
import '../../services/api_service.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key, this.demoMode = false, this.onNavigate});

  final bool demoMode;
  final ValueChanged<int>? onNavigate;

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  static const Color _navy = Color(0xFF082D5C);
  static const Color _blue = Color(0xFF1F5F9D);
  static const Color _turquoise = Color(0xFF159D9B);
  static const Color _background = Color(0xFFF5F8FC);
  static const Color _gold = Color(0xFFFFC83D);
  static const Color _textPrimary = Color(0xFF243247);
  static const Color _textSecondary = Color(0xFF68778B);
  static const Color _border = Color(0xFFE2E8F0);

  bool _isLoading = true;
  String? _errorMessage;
  String _userName = 'Nama belum tersedia';
  String _userNim = 'Belum tersedia';
  String _studyProgram = 'Belum tersedia';
  int _totalSKS = 0;
  double _ipk = 0.0;
  bool _hasIpkData = false;
  List<dynamic> _schedules = [];
  List<dynamic> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.demoMode) {
        final currentEnrollments = MahasiswaDemoData.krsEnrollments.where(
          (item) => item['class']?['year'] == '2026/2027',
        );
        final totalSKS = currentEnrollments.fold<int>(
          0,
          (sum, item) =>
              sum + (item['class']?['course']?['sks'] as int? ?? 0),
        );
        final gradeScores = MahasiswaDemoData.grades
            .map((grade) => (grade['score'] as num).toDouble())
            .toList();
        final average = gradeScores.reduce((a, b) => a + b) / gradeScores.length;
        if (!mounted) return;
        setState(() {
          _userName = MahasiswaDemoData.student['name']! as String;
          _userNim = MahasiswaDemoData.student['nim']! as String;
          _studyProgram =
              MahasiswaDemoData.student['program_studi']! as String;
          _totalSKS = totalSKS;
          _ipk = double.parse(((average / 100) * 4).toStringAsFixed(2));
          _hasIpkData = true;
          _schedules = MahasiswaDemoData.schedules;
          _announcements = MahasiswaDemoData.announcements;
          _isLoading = false;
        });
        return;
      }

      final meResponse = await ApiService.get('/users/me');
      final userData = meResponse['data'];
      final userName = _identityValue(userData?['name']);
      final userNim = _identityValue(userData?['nim']);
      final studyProgram = _identityValue(userData?['program_studi']);

      final krsResponse = await ApiService.get('/enrollments/my');
      final List krsList = krsResponse['data'] ?? [];
      int totalSKS = 0;
      for (var item in krsList) {
        totalSKS += (item['class']?['course']?['sks'] ?? 0) as int;
      }

      final gradesResponse = await ApiService.get('/grades/my');
      final List gradesList = gradesResponse['data'] ?? [];
      double totalScore = 0;
      int gradeCount = 0;
      for (var grade in gradesList) {
        if (grade['score'] != null) {
          totalScore += (grade['score'] as num).toDouble();
          gradeCount++;
        }
      }
      final double avgScore = gradeCount > 0 ? totalScore / gradeCount : 0;
      final double ipk = double.parse(
        ((avgScore / 100) * 4).toStringAsFixed(2),
      );

      final scheduleResponse = await ApiService.get('/admin/schedules/list');
      final List scheduleList = scheduleResponse['data'] ?? [];
      final schedules = scheduleList.take(2).toList();

      final announcementResponse = await ApiService.get(
        '/admin/announcements/list',
      );
      final List announcementList = announcementResponse['data'] ?? [];
      final announcements = announcementList.take(2).toList();

      if (!mounted) return;
      setState(() {
        _userName = userName;
        _userNim = userNim;
        _studyProgram = studyProgram;
        _totalSKS = totalSKS;
        _ipk = ipk;
        _hasIpkData = gradeCount > 0;
        _schedules = schedules;
        _announcements = announcements;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Data beranda belum dapat dimuat. Periksa koneksi lalu coba lagi.';
        _isLoading = false;
      });
    }
  }

  void _showUnavailableMessage(String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$feature belum tersedia.')));
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    final date = value.toString();
    return date.length >= 10 ? date.substring(0, 10) : date;
  }

  String _identityValue(dynamic value) {
    if (value is Map) {
      value = value['name'];
    }
    if (value == null || value.toString().trim().isEmpty) {
      return 'Belum tersedia';
    }
    return value.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? 16.0
        : 20.0;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.school_outlined, size: 23),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'EduTrack',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pencarian',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showUnavailableMessage('Pencarian'),
          ),
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _showUnavailableMessage('Notifikasi'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: ColoredBox(color: _blue, child: SizedBox(height: 3)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              color: _navy,
              onRefresh: _fetchData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  22,
                  horizontalPadding,
                  32,
                ),
                children: [
                  if (widget.demoMode) ...[
                    _buildDemoBadge(),
                    const SizedBox(height: 14),
                  ],
                  _buildStudentIdentity(),
                  const SizedBox(height: 25),
                  _buildSectionTitle('Ringkasan akademik'),
                  const SizedBox(height: 12),
                  _buildAcademicSummary(),
                  const SizedBox(height: 32),
                  _buildFeatureShortcuts(),
                  const SizedBox(height: 28),
                  _buildSectionTitle(
                    'Jadwal perkuliahan',
                    actionText: 'Lihat semua',
                    onAction: () => _showUnavailableMessage('Jadwal lengkap'),
                  ),
                  const SizedBox(height: 12),
                  if (_schedules.isEmpty)
                    _buildEmptyState(
                      icon: Icons.event_busy_outlined,
                      message: 'Belum ada jadwal yang tersedia.',
                    )
                  else
                    ..._schedules.asMap().entries.map(
                      (entry) => _buildScheduleCard(
                        entry.value,
                        isNext: entry.key == 0,
                      ),
                    ),
                  const SizedBox(height: 22),
                  _buildSectionTitle(
                    'Informasi kampus',
                    actionText: 'Lihat semua',
                    onAction: () =>
                        _showUnavailableMessage('Informasi kampus lengkap'),
                  ),
                  const SizedBox(height: 12),
                  if (_announcements.isEmpty)
                    _buildEmptyState(
                      icon: Icons.campaign_outlined,
                      message: 'Belum ada informasi kampus.',
                    )
                  else
                    ..._announcements.map(_buildAnnouncementCard),
                ],
              ),
            ),
    );
  }

  Widget _buildDemoBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold),
        ),
        child: const Text(
          'DEMO · DATA ILUSTRASI',
          style: TextStyle(
            color: _navy,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureShortcuts() {
    const shortcuts = [
      (label: 'KRS', icon: Icons.menu_book_outlined, index: 1),
      (label: 'Absensi', icon: Icons.fact_check_outlined, index: 2),
      (label: 'Nilai', icon: Icons.bar_chart_rounded, index: 3),
      (label: 'Profil', icon: Icons.person_outline_rounded, index: 4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Akses cepat'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: shortcuts.map((shortcut) {
                return SizedBox(
                  width: itemWidth,
                  child: OutlinedButton.icon(
                    onPressed: widget.onNavigate == null
                        ? null
                        : () => widget.onNavigate!(shortcut.index),
                    icon: Icon(shortcut.icon, size: 19),
                    label: Text(shortcut.label),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: _navy,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStudentIdentity() {
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 21, 20, 22),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(23),
        border: const Border(bottom: BorderSide(color: _gold, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IDENTITAS MAHASISWA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 23),
          Text(
            _userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NIM  ·  $_userNim',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.24)),
          const SizedBox(height: 13),
          _buildIdentityDetail('PROGRAM STUDI', _studyProgram),
        ],
      ),
    );
  }

  Widget _buildIdentityDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildAcademicSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'IPK',
            value: _hasIpkData ? _ipk.toStringAsFixed(2) : '—',
            subtitle: _hasIpkData ? 'Dari skala 4.00' : 'Belum ada data nilai',
            background: _turquoise,
            foreground: Colors.white,
            detailColor: Colors.white70,
            icon: Icons.auto_graph_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'SKS diambil',
            value: '$_totalSKS',
            subtitle: 'Total pada KRS',
            background: _gold,
            foreground: _navy,
            detailColor: _navy.withValues(alpha: 0.72),
            icon: Icons.menu_book_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color background,
    required Color foreground,
    required Color detailColor,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: detailColor, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(dynamic schedule, {required bool isNext}) {
    final course = schedule['course']?['name'] ?? 'Mata Kuliah';
    final day = schedule['day']?.toString() ?? '-';
    final startTime = schedule['start_time']?.toString() ?? '-';
    final endTime = schedule['end_time']?.toString() ?? '-';
    final room = schedule['room']?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                startTime,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 12,
            child: Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: isNext ? _gold : _turquoise,
                    shape: BoxShape.circle,
                    border: Border.all(color: _background, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withValues(alpha: 0.18),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Container(width: 2, height: 62, color: const Color(0xFFD8E4F1)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 12, 12),
              decoration: BoxDecoration(
                color: isNext ? const Color(0xFFE5F5F3) : Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isNext
                      ? const Color(0xFFBDE4E0)
                      : const Color(0xFFE2E9F1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _buildScheduleDetail(
                    Icons.calendar_today_outlined,
                    '$day  ·  $endTime',
                  ),
                  const SizedBox(height: 4),
                  _buildScheduleDetail(Icons.location_on_outlined, room),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetail(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: _textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final title = announcement['title'] ?? 'Pengumuman';
    final category = announcement['category'] ?? 'Umum';
    final date = _formatDate(announcement['start_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFDDEBFA),
        borderRadius: BorderRadius.circular(18),
        border: const Border(left: BorderSide(color: _gold, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.toString().toUpperCase(),
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: _textSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _navy,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        const Icon(Icons.cloud_off_outlined, color: _textSecondary, size: 44),
        const SizedBox(height: 16),
        Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              side: const BorderSide(color: _navy),
            ),
          ),
        ),
      ],
    );
  }
}
