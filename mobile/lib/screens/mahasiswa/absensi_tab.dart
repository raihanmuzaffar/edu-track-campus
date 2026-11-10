import 'package:flutter/material.dart';

import '../../services/api_service.dart';

const _navy = Color(0xFF082D5C);
const _blue = Color(0xFF1F5F9D);
const _turquoise = Color(0xFF159D9B);
const _lightTurquoise = Color(0xFFD7F1F0);
const _offWhite = Color(0xFFF5F8FC);
const _yellow = Color(0xFFFFC83D);
const _muted = Color(0xFF718096);
const _border = Color(0xFFE4EBF3);

enum _StatusKind { present, nonPresent, unknown }

class _AttendanceRecord {
  const _AttendanceRecord({
    required this.course,
    required this.date,
    required this.status,
  });

  factory _AttendanceRecord.fromJson(Map<dynamic, dynamic> item) {
    var courseName = 'Mata Kuliah';
    final classValue = item['Class'];
    if (classValue is Map) {
      final courseValue = classValue['Course'];
      if (courseValue is Map) {
        final name = courseValue['name']?.toString().trim();
        if (name != null && name.isNotEmpty) courseName = name;
      }
    }

    final dateValue = item['date']?.toString().trim();
    final statusValue = item['status']?.toString().trim();
    return _AttendanceRecord(
      course: courseName,
      date: dateValue == null || dateValue.isEmpty ? '-' : dateValue,
      status: statusValue == null || statusValue.isEmpty
          ? 'Tidak diketahui'
          : statusValue,
    );
  }

  final String course;
  final String date;
  final String status;

  _StatusKind get kind {
    final normalized = status.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    if (normalized == 'hadir' || normalized == 'present') {
      return _StatusKind.present;
    }
    if (const {
      'izin',
      'sakit',
      'alpa',
      'alpha',
      'tidakhadir',
      'absent',
    }.contains(normalized)) {
      return _StatusKind.nonPresent;
    }
    return _StatusKind.unknown;
  }
}

class _CourseRecords {
  _CourseRecords(this.name);

  final String name;
  final List<_AttendanceRecord> records = [];
}

class AbsensiTab extends StatefulWidget {
  const AbsensiTab({super.key});

  @override
  State<AbsensiTab> createState() => _AbsensiTabState();
}

class _AbsensiTabState extends State<AbsensiTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_AttendanceRecord> _attendanceData = [];

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
      final response = await ApiService.get('/attendances/my');
      if (response is! Map || response['data'] is! List) {
        throw const FormatException('Unexpected attendance response');
      }

      final records = (response['data'] as List)
          .whereType<Map>()
          .map(_AttendanceRecord.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _attendanceData = records;
        _isLoading = false;
      });
    } on Exception catch (error) {
      debugPrint('Error fetching attendance: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Data kehadiran belum dapat dimuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendanceData
        .where((record) => record.kind == _StatusKind.present)
        .length;
    final nonPresentCount = _attendanceData
        .where((record) => record.kind == _StatusKind.nonPresent)
        .length;
    final unknownCount = _attendanceData
        .where((record) => record.kind == _StatusKind.unknown)
        .length;
    final recognizedCount = presentCount + nonPresentCount;
    final attendanceRate = recognizedCount == 0
        ? null
        : (presentCount * 100 / recognizedCount).round();
    final courses = _groupByCourse(_attendanceData);

    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 66,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.school_rounded, color: _yellow, size: 23),
            ),
            const SizedBox(width: 11),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EduTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'PORTAL MAHASISWA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: ColoredBox(color: _blue, child: SizedBox(height: 3)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _turquoise,
          onRefresh: _fetchAttendance,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 720
                  ? 28.0
                  : 18.0;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  36,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _PageHeading(),
                          const SizedBox(height: 22),
                          if (_isLoading && _attendanceData.isEmpty)
                            const _LoadingCard()
                          else if (_errorMessage != null &&
                              _attendanceData.isEmpty)
                            _ErrorCard(onRetry: _fetchAttendance)
                          else if (_attendanceData.isEmpty)
                            const _EmptyCard()
                          else ...[
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 14),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8),
                                  ),
                                  child: LinearProgressIndicator(
                                    minHeight: 3,
                                    color: _turquoise,
                                    backgroundColor: _lightTurquoise,
                                  ),
                                ),
                              ),
                            if (_errorMessage != null) ...[
                              _RefreshErrorBanner(onRetry: _fetchAttendance),
                              const SizedBox(height: 14),
                            ],
                            _SummarySection(
                              total: _attendanceData.length,
                              present: presentCount,
                              nonPresent: nonPresentCount,
                              unknown: unknownCount,
                              rate: attendanceRate,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Catatan per mata kuliah',
                                    style: TextStyle(
                                      color: _navy,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${courses.length} mata kuliah',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Hanya catatan kehadiran yang diterima dari data Anda yang ditampilkan.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (final course in courses) ...[
                              _CourseCard(course: course),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<_CourseRecords> _groupByCourse(List<_AttendanceRecord> records) {
    final groups = <String, _CourseRecords>{};
    for (final record in records) {
      final key = record.course.trim().toLowerCase();
      final group = groups.putIfAbsent(
        key,
        () => _CourseRecords(record.course),
      );
      group.records.add(record);
    }
    return groups.values.toList();
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _lightTurquoise,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'AKADEMIK  /  KEHADIRAN',
            style: TextStyle(
              color: _blue,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'Rekap Kehadiran',
          style: TextStyle(
            color: _navy,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pantau status dan riwayat kehadiran yang tercatat untuk setiap mata kuliah.',
          style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.total,
    required this.present,
    required this.nonPresent,
    required this.unknown,
    required this.rate,
  });

  final int total;
  final int present;
  final int nonPresent;
  final int unknown;
  final int? rate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Total catatan',
                value: '$total',
                subtitle: 'rekaman diterima',
                icon: Icons.receipt_long_rounded,
                tint: _blue,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Hadir',
                value: '$present',
                subtitle: 'status hadir tercatat',
                icon: Icons.check_circle_rounded,
                tint: _turquoise,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Non-hadir eksplisit',
                value: '$nonPresent',
                subtitle: 'status selain hadir',
                icon: Icons.event_busy_rounded,
                tint: _yellow,
              ),
            ),
            SizedBox(
              width: width,
              child: _SummaryCard(
                title: 'Persentase hadir',
                value: rate == null ? '—' : '$rate%',
                subtitle: rate == null
                    ? 'belum ada status yang dikenali'
                    : 'dari status tercatat yang dikenali',
                icon: Icons.insights_rounded,
                tint: _navy,
              ),
            ),
            if (unknown > 0)
              SizedBox(
                width: width,
                child: _SummaryCard(
                  title: 'Status tak dikenal',
                  value: '$unknown',
                  subtitle: 'tidak masuk hitungan persentase',
                  icon: Icons.help_outline_rounded,
                  tint: _muted,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, size: 17, color: tint),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 10, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final _CourseRecords course;

  @override
  Widget build(BuildContext context) {
    final visibleRecords = course.records.take(16).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _lightTurquoise,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    course.name,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: _offWhite,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${course.records.length} catatan',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Visualisasi catatan',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${visibleRecords.length}/16 posisi terisi',
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 350 ? 4 : 8;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 16,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  if (index >= visibleRecords.length) {
                    return const _UnrecordedCell();
                  }
                  final record = visibleRecords[index];
                  final color = _statusColor(record.kind);
                  return Tooltip(
                    message: '${record.date} • ${record.status}',
                    child: Semantics(
                      label:
                          'Catatan ${index + 1}, ${record.date}, status ${record.status}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: color.withValues(alpha: .28),
                          ),
                        ),
                        child: Icon(
                          _statusIcon(record.kind),
                          color: color,
                          size: 17,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 9),
          const Text(
            'Urutan mengikuti catatan yang diterima; sel abu-abu belum tercatat, bukan penanda absen.',
            style: TextStyle(color: _muted, fontSize: 10, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 13),
          const Text(
            'Riwayat tercatat',
            style: TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < course.records.length; index++)
            _RecordRow(
              record: course.records[index],
              isLast: index == course.records.length - 1,
            ),
        ],
      ),
    );
  }
}

class _UnrecordedCell extends StatelessWidget {
  const _UnrecordedCell();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Belum ada catatan',
      child: Semantics(
        label: 'Belum ada catatan, bukan penanda absen',
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3F7),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _border),
          ),
          child: const Icon(Icons.remove_rounded, color: _muted, size: 17),
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.isLast});

  final _AttendanceRecord record;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(record.kind);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: _muted, size: 14),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _displayDate(record.date),
              style: const TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(_StatusKind kind) {
  switch (kind) {
    case _StatusKind.present:
      return _turquoise;
    case _StatusKind.nonPresent:
      return const Color(0xFFB54747);
    case _StatusKind.unknown:
      return _muted;
  }
}

IconData _statusIcon(_StatusKind kind) {
  switch (kind) {
    case _StatusKind.present:
      return Icons.check_rounded;
    case _StatusKind.nonPresent:
      return Icons.circle_outlined;
    case _StatusKind.unknown:
      return Icons.help_outline_rounded;
  }
}

String _displayDate(String date) {
  if (date == '-') return 'Tanggal tidak tersedia';
  return date.length > 10 ? date.substring(0, 10) : date;
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: CircularProgressIndicator(color: _turquoise, strokeWidth: 2.5),
      title: 'Memuat kehadiran',
      description: 'Sedang mengambil catatan kehadiran Anda.',
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: const Icon(Icons.cloud_off_rounded, color: _blue, size: 27),
      title: 'Kehadiran belum tersedia',
      description:
          'Periksa koneksi Anda, lalu coba muat ulang catatan kehadiran.',
      action: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Coba lagi'),
        style: TextButton.styleFrom(foregroundColor: _blue),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icon(Icons.event_note_rounded, color: _turquoise, size: 28),
      title: 'Belum ada catatan kehadiran',
      description: 'Belum ada data kehadiran yang tercatat. Ini bukan penanda bahwa Anda absen.',
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final Widget icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          SizedBox(width: 30, height: 30, child: Center(child: icon)),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 9), action!],
        ],
      ),
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 5, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _yellow.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _navy, size: 18),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Pembaruan gagal. Catatan yang tampil mungkin belum terbaru.',
              style: TextStyle(color: _navy, fontSize: 11, height: 1.35),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: _blue),
            child: const Text('Ulangi'),
          ),
        ],
      ),
    );
  }
}
