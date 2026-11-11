import 'package:flutter/material.dart';

import 'qr_generator_screen.dart';
import '../../services/api_service.dart';

class BerandaDosenTab extends StatefulWidget {
  const BerandaDosenTab({super.key});

  @override
  State<BerandaDosenTab> createState() => _BerandaDosenTabState();
}

class _BerandaDosenTabState extends State<BerandaDosenTab> {
  static const Color _navy = Color(0xFF082D5C);
  static const Color _blue = Color(0xFF1F5F9D);
  static const Color _turquoise = Color(0xFF159D9B);
  static const Color _lightTurquoise = Color(0xFFD7F1F0);
  static const Color _lightBlue = Color(0xFFEAF2FA);
  static const Color _softYellow = Color(0xFFFFF4D6);
  static const Color _yellowInk = Color(0xFF775600);
  static const Color _offWhite = Color(0xFFF1F5FA);
  static const Color _textSecondary = Color(0xFF68778B);
  static const Color _border = Color(0xFFE2E9F1);

  bool _isLoading = true;
  List<dynamic> _myClasses = [];
  String _dosenName = 'Dosen';
  String _lecturerId = '';
  String _studyProgram = '';
  String? _errorMessage;

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
      final meResponse = await ApiService.get('/users/me');
      final userData = meResponse['data'];
      final user = userData is Map ? userData : <String, dynamic>{};
      final myId = (user['id'] as num?)?.toInt() ?? 0;

      final classesResponse = await ApiService.get('/classes/list');
      final classesEnvelope = classesResponse['data'];
      final classData = classesEnvelope is Map ? classesEnvelope['data'] : null;
      final List<dynamic> allClasses = classData is List
          ? classData
          : <dynamic>[];
      final assignedClasses = allClasses.where((item) {
        if (item is! Map) return false;
        return (item['dosen_id'] as num?)?.toInt() == myId;
      }).toList();

      if (!mounted) return;
      setState(() {
        _dosenName = _nonEmptyText(user['name']) ?? 'Dosen';
        _lecturerId =
            _nonEmptyText(user['nidn']) ?? _nonEmptyText(user['nip']) ?? '';
        _studyProgram = _nonEmptyText(user['program_studi']) ?? '';
        _myClasses = assignedClasses;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching lecturer dashboard data: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Data beranda belum dapat dimuat. Periksa koneksi lalu coba lagi.';
        _isLoading = false;
      });
    }
  }

  static String? _nonEmptyText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static const Map<String, int> _weekdayOrder = {
    'senin': 1,
    'selasa': 2,
    'rabu': 3,
    'kamis': 4,
    'jumat': 5,
    'sabtu': 6,
    'minggu': 7,
  };

  String get _todayName {
    const weekdays = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return weekdays[DateTime.now().weekday];
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi,';
    if (hour < 15) return 'Selamat siang,';
    if (hour < 19) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  int? _dayOrder(dynamic value) {
    final day = _nonEmptyText(value)?.toLowerCase();
    return day == null ? null : _weekdayOrder[day];
  }

  int? _parseTimeInMinutes(dynamic value) {
    final parts = _nonEmptyText(value)?.split(':');
    if (parts == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  int _timeInMinutes(dynamic value) {
    return _parseTimeInMinutes(value) ?? 24 * 60;
  }

  String _formatTime(dynamic start, dynamic end) {
    final startTime = _nonEmptyText(start);
    final endTime = _nonEmptyText(end);
    if (startTime == null && endTime == null) return 'Waktu belum tersedia';
    if (startTime == null) return endTime!;
    if (endTime == null) return startTime;
    return '$startTime - $endTime';
  }

  List<Map> get _sortedClasses {
    final classes = _myClasses.whereType<Map>().toList();
    classes.sort((a, b) {
      final dayA = _dayOrder(a['day']) ?? 8;
      final dayB = _dayOrder(b['day']) ?? 8;
      if (dayA != dayB) return dayA.compareTo(dayB);
      return _timeInMinutes(a['start_time'])
          .compareTo(_timeInMinutes(b['start_time']));
    });
    return classes;
  }

  List<Map> get _todayClasses {
    final today = _todayName.toLowerCase();
    return _sortedClasses
        .where((item) => _nonEmptyText(item['day'])?.toLowerCase() == today)
        .toList();
  }

  int get _courseCount {
    return _myClasses
        .whereType<Map>()
        .map((item) {
          final course = item['course'];
          if (course is! Map) return null;
          return _nonEmptyText(course['id']) ?? _nonEmptyText(course['name']);
        })
        .whereType<String>()
        .toSet()
        .length;
  }

  bool _isClassOngoing(Map item) {
    final start = _parseTimeInMinutes(item['start_time']);
    final end = _parseTimeInMinutes(item['end_time']);
    if (start == null || end == null) return false;
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    return currentMinutes >= start && currentMinutes < end;
  }

  String _courseName(Map item) {
    final course = item['course'];
    if (course is Map) {
      return _nonEmptyText(course['name']) ?? 'Mata kuliah';
    }
    return 'Mata kuliah';
  }

  String _className(Map item) => _nonEmptyText(item['name']) ?? 'Kelas';

  String _classRoom(Map item) =>
      _nonEmptyText(item['room']) ?? 'Ruang belum tersedia';

  IconData _getCourseIcon(String courseName) {
    final name = courseName.toLowerCase();
    if (name.contains('pemrograman') || name.contains('coding')) {
      return Icons.code_rounded;
    }
    if (name.contains('basis data') || name.contains('database')) {
      return Icons.storage_rounded;
    }
    if (name.contains('jaringan') || name.contains('network')) {
      return Icons.router_rounded;
    }
    if (name.contains('desain') || name.contains('ui')) {
      return Icons.design_services_rounded;
    }
    return Icons.menu_book_rounded;
  }

  void _openQrSession(Map item) {
    final classId = item['id'];
    if (classId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            QrGeneratorScreen(classId: classId, className: _className(item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _turquoise))
            : RefreshIndicator(
                color: _turquoise,
                onRefresh: _fetchData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 22),
                          if (_errorMessage != null) ...[
                            _buildErrorBanner(_errorMessage!),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 24),
                          _buildSectionHeading(
                            title: 'Aktivitas Mengajar',
                            subtitle: 'Ringkasan kelas dan agenda Anda',
                          ),
                          const SizedBox(height: 14),
                          _buildStatsGrid(),
                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            title: 'Jadwal Mengajar Hari Ini',
                            subtitle: _todayName,
                          ),
                          const SizedBox(height: 14),
                          _buildTodaySchedule(),
                          const SizedBox(height: 28),
                          _buildSectionHeading(
                            title: 'Kelas yang Diampu',
                            subtitle: 'Akses sesi QR absensi untuk kelas',
                          ),
                          const SizedBox(height: 14),
                          if (_myClasses.isEmpty)
                            _buildEmptyClasses()
                          else
                            ..._sortedClasses.map(_buildClassCard),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final details = <String>[
      if (_lecturerId.isNotEmpty) 'NIDN/NIP: $_lecturerId',
      if (_studyProgram.isNotEmpty) _studyProgram,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'EduTrack Campus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _greeting,
            style: const TextStyle(
              color: Color(0xFFD7E5F3),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _dosenName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details.join('  •  '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _lightTurquoise,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: 38,
            height: 3,
            decoration: BoxDecoration(
              color: _turquoise,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: _textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Kelas diampu',
            value: '${_myClasses.length}',
            caption: 'kelas',
            icon: Icons.menu_book_rounded,
            backgroundColor: _turquoise,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _buildStatCard(
            title: 'Mata kuliah',
            value: _courseCount.toString(),
            caption: 'berbeda',
            icon: Icons.library_books_outlined,
            backgroundColor: _lightBlue,
            foregroundColor: _navy,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _buildStatCard(
            title: 'Jadwal hari ini',
            value: '${_todayClasses.length}',
            caption: _todayName,
            icon: Icons.today_rounded,
            backgroundColor: _softYellow,
            foregroundColor: _yellowInk,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String caption,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 124),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: foregroundColor, size: 17),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor.withValues(alpha: 0.78),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final classes = _todayClasses;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _buildScheduleGroup(
        title: 'Agenda • $_todayName',
        icon: Icons.today_outlined,
        classes: classes,
        emptyMessage: 'Tidak ada jadwal kelas untuk hari ini.',
      ),
    );
  }

  Widget _buildScheduleGroup({
    required String title,
    required IconData icon,
    required List<Map> classes,
    required String emptyMessage,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _turquoise, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (classes.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            )
          else
            ...classes.map(_buildTimelineItem),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map item) {
    final isOngoing = _isClassOngoing(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: isOngoing ? _turquoise : _blue,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: isOngoing ? 72 : 45,
                color: _lightTurquoise,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _courseName(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isOngoing) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _turquoise,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Sedang berlangsung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  '${_formatTime(item['start_time'], item['end_time'])}  •  ${_className(item)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  _classRoom(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map item) {
    final courseName = _courseName(item);
    final day = _nonEmptyText(item['day']) ?? 'Hari belum tersedia';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: _lightTurquoise,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_getCourseIcon(courseName), color: _blue, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_className(item)}  •  $day',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: _turquoise, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  _formatTime(item['start_time'], item['end_time']),
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ),
              const Icon(
                Icons.location_on_outlined,
                color: _turquoise,
                size: 16,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _classRoom(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: OutlinedButton.icon(
              onPressed: () => _openQrSession(item),
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text('Buka Sesi QR Absensi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(color: _lightTurquoise),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClasses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_outlined, color: _textSecondary, size: 30),
          SizedBox(height: 10),
          Text(
            'Belum ada kelas yang ditugaskan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2D4CC)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFF9B4330),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF823B2B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
