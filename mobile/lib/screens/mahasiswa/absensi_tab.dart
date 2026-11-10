import 'package:flutter/material.dart';

import '../../data/mahasiswa_demo_data.dart';
import '../../services/api_service.dart';

enum _AttendanceStatus { present, absent, unrecorded }

class _AttendanceMeeting {
  const _AttendanceMeeting({required this.number, this.date, this.status});

  final int number;
  final String? date;
  final _AttendanceStatus? status;
}

String? _scheduleFor(Map<String, dynamic> classData) {
  final day = classData['day']?.toString();
  final start = classData['start_time']?.toString();
  final end = classData['end_time']?.toString();
  final room = classData['room']?.toString();
  final time = [start, end].where((value) => value != null).join('–');
  final details = [
    if (day != null && day.isNotEmpty) day,
    if (time.isNotEmpty) time,
    if (room != null && room.isNotEmpty) room,
  ];
  return details.isEmpty ? null : details.join('  •  ');
}

class _AttendanceCourse {
  const _AttendanceCourse({
    required this.id,
    required this.name,
    required this.code,
    required this.className,
    required this.meetings,
    this.schedule,
    this.lecturer,
  });

  final String id;
  final String name;
  final String code;
  final String className;
  final List<_AttendanceMeeting> meetings;
  final String? schedule;
  final String? lecturer;

  int get presentCount => meetings
      .where((meeting) => meeting.status == _AttendanceStatus.present)
      .length;

  int get absentCount => meetings
      .where((meeting) => meeting.status == _AttendanceStatus.absent)
      .length;

  int get unrecordedCount => 16 - presentCount - absentCount;
}

class AbsensiTab extends StatefulWidget {
  const AbsensiTab({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  State<AbsensiTab> createState() => _AbsensiTabState();
}

class _AbsensiTabState extends State<AbsensiTab> {
  static const _navy = Color(0xFF082D5C);
  static const _blue = Color(0xFF1F5F9D);
  static const _turquoise = Color(0xFF159D9B);
  static const _background = Color(0xFFF5F8FC);
  static const _green = Color(0xFFE0F3E9);
  static const _pink = Color(0xFFFBE4EB);
  static const _gray = Color(0xFFEDF1F5);

  bool _isLoading = true;
  String? _errorMessage;
  List<_AttendanceCourse> _courses = [];
  _AttendanceCourse? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> records;
      final List<dynamic> enrollments;
      if (widget.demoMode) {
        records = MahasiswaDemoData.attendances;
        enrollments = const [];
      } else {
        final response = await ApiService.get('/attendances/my');
        records = response['data'] is List ? response['data'] as List : [];
        final enrollmentResponse = await ApiService.get('/enrollments/my');
        enrollments = enrollmentResponse['data'] is List
            ? enrollmentResponse['data'] as List
            : [];
      }

      final courses = _groupAttendance(records, enrollments);
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _selectedCourse = null;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching Attendance: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Data absensi belum dapat dimuat. Coba muat ulang.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  List<_AttendanceCourse> _groupAttendance(
    List<dynamic> records,
    List<dynamic> enrollments,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final enrollment in enrollments) {
      final enrollmentData = _map(enrollment);
      final classData = _map(enrollmentData['class']);
      final course = _map(classData['course']);
      final key =
          (enrollmentData['class_id'] ??
                  classData['id'] ??
                  course['code'] ??
                  course['name'] ??
                  'unknown')
              .toString();
      grouped.putIfAbsent(key, () => []).add({
        'class_id': key,
        'class': classData,
        '_is_placeholder': true,
      });
    }

    for (final record in records) {
      final item = _map(record);
      final classData = _map(item['class']);
      final course = _map(classData['course']);
      final key =
          (item['class_id'] ??
                  classData['id'] ??
                  course['code'] ??
                  course['name'] ??
                  'unknown')
              .toString();
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.entries.map((entry) {
      final seed = entry.value.first;
      final sortedRecords =
          entry.value
              .where((record) => record['_is_placeholder'] != true)
              .toList()
            ..sort(
              (left, right) => (left['date']?.toString() ?? '').compareTo(
                right['date']?.toString() ?? '',
              ),
            );
      final classData = _map(seed['class']);
      final course = _map(classData['course']);
      final meetings = <_AttendanceMeeting>[];
      for (var index = 0; index < 16; index++) {
        if (index >= sortedRecords.length) {
          meetings.add(
            _AttendanceMeeting(
              number: index + 1,
              status: _AttendanceStatus.unrecorded,
            ),
          );
          continue;
        }
        final record = sortedRecords[index];
        meetings.add(
          _AttendanceMeeting(
            number: index + 1,
            date: record['date']?.toString(),
            status: _statusFrom(record['status']?.toString()),
          ),
        );
      }
      return _AttendanceCourse(
        id: entry.key,
        name: course['name']?.toString() ?? 'Mata kuliah',
        code: course['code']?.toString() ?? '—',
        className: classData['name']?.toString() ?? 'Kelas',
        meetings: meetings,
        schedule: _scheduleFor(classData),
        lecturer: _map(classData['dosen'])['name']?.toString(),
      );
    }).toList();
  }

  _AttendanceStatus _statusFrom(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'hadir':
        return _AttendanceStatus.present;
      case 'alpa':
      case 'izin':
      case 'sakit':
      case 'tidak hadir':
        return _AttendanceStatus.absent;
      default:
        return _AttendanceStatus.unrecorded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourse = _selectedCourse;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(
          selectedCourse == null ? 'Absensi' : selectedCourse.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: selectedCourse == null
            ? null
            : IconButton(
                tooltip: 'Kembali ke daftar mata kuliah',
                onPressed: () => setState(() => _selectedCourse = null),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: ColoredBox(
            color: _turquoise,
            child: const SizedBox(height: 3),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : _errorMessage != null
          ? _buildError()
          : selectedCourse == null
          ? _buildCourseList()
          : _buildCourseDetail(selectedCourse),
    );
  }

  Widget _buildCourseList() {
    if (_courses.isEmpty) {
      return _buildStatus(
        icon: Icons.fact_check_outlined,
        title: 'Belum ada data absensi',
        message: 'Daftar mata kuliah dan rekap pertemuan akan tampil di sini.',
      );
    }
    return RefreshIndicator(
      color: _turquoise,
      onRefresh: _fetchAttendance,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          if (widget.demoMode) ...[_demoBadge(), const SizedBox(height: 14)],
          const Text(
            'Pilih mata kuliah untuk melihat riwayat 16 pertemuan.',
            style: TextStyle(color: Color(0xFF68778B), fontSize: 13),
          ),
          const SizedBox(height: 14),
          ..._courses.map(_buildCourseCard),
        ],
      ),
    );
  }

  Widget _buildCourseCard(_AttendanceCourse course) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _selectedCourse = course),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7F1F0),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _turquoise,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.code}  •  ${course.className}',
                          style: const TextStyle(
                            color: Color(0xFF68778B),
                            fontSize: 12,
                          ),
                        ),
                        if (course.schedule != null ||
                            course.lecturer != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            [
                              if (course.schedule != null) course.schedule,
                              if (course.lecturer != null)
                                'Dosen ${course.lecturer}',
                            ].join('  •  '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF68778B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _blue),
                ],
              ),
              const SizedBox(height: 15),
              _buildCounts(course),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounts(_AttendanceCourse course) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _countBadge(
          'Hadir',
          course.presentCount,
          _green,
          const Color(0xFF27734B),
        ),
        _countBadge(
          'Tidak hadir',
          course.absentCount,
          _pink,
          const Color(0xFFAA4865),
        ),
        _countBadge(
          'Belum tercatat',
          course.unrecordedCount,
          _gray,
          const Color(0xFF68778B),
        ),
      ],
    );
  }

  Widget _countBadge(
    String label,
    int count,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCourseDetail(_AttendanceCourse course) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        if (widget.demoMode) ...[_demoBadge(), const SizedBox(height: 14)],
        Text(
          '${course.code}  •  ${course.className}',
          style: const TextStyle(
            color: Color(0xFF68778B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildCounts(course),
        const SizedBox(height: 20),
        const Text(
          'Riwayat pertemuan',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 16,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final meeting = course.meetings[index];
            final color = _meetingColor(meeting.status);
            return Material(
              color: color,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showMeetingDetail(meeting),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${meeting.number}',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Icon(
                      _meetingIcon(meeting.status),
                      size: 15,
                      color: _meetingForeground(meeting.status),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => _showScannerDemo(course),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Buka pemindaian QR'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _navy,
            side: const BorderSide(color: _blue),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Color _meetingColor(_AttendanceStatus? status) {
    return switch (status) {
      _AttendanceStatus.present => _green,
      _AttendanceStatus.absent => _pink,
      _AttendanceStatus.unrecorded || null => _gray,
    };
  }

  Color _meetingForeground(_AttendanceStatus? status) {
    return switch (status) {
      _AttendanceStatus.present => const Color(0xFF27734B),
      _AttendanceStatus.absent => const Color(0xFFAA4865),
      _AttendanceStatus.unrecorded || null => const Color(0xFF68778B),
    };
  }

  IconData _meetingIcon(_AttendanceStatus? status) {
    return switch (status) {
      _AttendanceStatus.present => Icons.check_circle_rounded,
      _AttendanceStatus.absent => Icons.cancel_rounded,
      _AttendanceStatus.unrecorded || null => Icons.schedule_rounded,
    };
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _legendItem('Hadir', _green),
        _legendItem('Tidak hadir', _pink),
        _legendItem('Belum tercatat', _gray),
      ],
    );
  }

  Widget _legendItem(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF68778B), fontSize: 11),
        ),
      ],
    );
  }

  void _showMeetingDetail(_AttendanceMeeting meeting) {
    final status = switch (meeting.status) {
      _AttendanceStatus.present => 'Hadir',
      _AttendanceStatus.absent => 'Tidak hadir',
      _AttendanceStatus.unrecorded || null => 'Belum tercatat',
    };
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pertemuan ${meeting.number}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            if (meeting.date != null) ...[
              const SizedBox(height: 6),
              Text('Tanggal: ${_formatDate(meeting.date!)}'),
            ],
            if (widget.demoMode) ...[
              const SizedBox(height: 12),
              const Text(
                'DEMO • Data ilustrasi, tidak tersimpan ke backend.',
                style: TextStyle(color: _blue, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) =>
      date.length >= 10 ? date.substring(0, 10) : date;

  void _showScannerDemo(_AttendanceCourse course) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          color: _turquoise,
          size: 38,
        ),
        title: const Text('Pemindaian QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 170,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFD7F1F0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _turquoise),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 82,
                color: _navy,
              ),
            ),
            const SizedBox(height: 14),
            Text(course.name, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'DEMO • Kamera pemindai belum terhubung. Tidak ada absensi yang disimpan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF68778B), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'DEMO • Pemindaian disimulasikan; tidak ada absensi yang disimpan.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Simulasikan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _demoBadge() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC83D)),
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

  Widget _buildError() => _buildStatus(
    icon: Icons.cloud_off_outlined,
    title: 'Data belum tersedia',
    message: _errorMessage ?? 'Terjadi kesalahan.',
    action: OutlinedButton.icon(
      onPressed: _fetchAttendance,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Coba lagi'),
    ),
  );

  Widget _buildStatus({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _turquoise),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF68778B)),
            ),
            if (action != null) ...[const SizedBox(height: 14), action],
          ],
        ),
      ),
    );
  }
}
