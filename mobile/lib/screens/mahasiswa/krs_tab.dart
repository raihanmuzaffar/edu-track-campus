import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class _AcademicPeriod {
  const _AcademicPeriod({this.year, this.semester});

  final String? year;
  final String? semester;

  String get key => '${year ?? ''}\u001f${semester ?? ''}';

  String? get semesterType {
    final value = (semester ?? '').toLowerCase();
    if (value.contains('ganjil') || value.contains('odd')) return 'Ganjil';
    if (value.contains('genap') || value.contains('even')) return 'Genap';
    final numberMatch = RegExp(r'^(?:semester\s*)?(\d+)$')
        .firstMatch(value.trim());
    final number = int.tryParse(numberMatch?.group(1) ?? '');
    if (number != null) return number.isOdd ? 'Ganjil' : 'Genap';
    return null;
  }

  int? get semesterNumber {
    final semesterValue = semester?.trim() ?? '';
    final explicitNumber = RegExp(
      r'^semester\s*(\d+)$',
      caseSensitive: false,
    ).firstMatch(semesterValue);
    if (explicitNumber != null) {
      return int.tryParse(explicitNumber.group(1)!);
    }
    if (RegExp(r'^\d+$').hasMatch(semesterValue)) {
      return int.tryParse(semesterValue);
    }

    return null;
  }

  String get label {
    final yearLabel = year;
    final type = semesterType;
    if (yearLabel == null && type == null) {
      return 'Periode belum dicantumkan';
    }

    final period = [
      yearLabel,
      type ?? semester,
    ].whereType<String>().join(' — ');
    final number = semesterNumber;
    return number == null ? period : '$period (Semester $number)';
  }
}

class KrsTab extends StatefulWidget {
  const KrsTab({super.key, this.mockEnrollments});

  const KrsTab.preview({super.key}) : mockEnrollments = _previewEnrollments;

  static const List<Map<String, dynamic>> _previewEnrollments = [
    {
      'class': {
        'name': 'Kelas B',
        'year': '2026/2027',
        'semester': '6',
        'day': 'Senin',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF310',
          'name': 'Kecerdasan Buatan',
          'semester': 6,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2026/2027',
        'semester': '6',
        'day': 'Rabu',
        'start_time': '10:00',
        'end_time': '13:20',
        'course': {
          'code': 'IF315',
          'name': 'Rekayasa Perangkat Lunak',
          'semester': 6,
          'sks': 4,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2026/2027',
        'semester': '5',
        'day': 'Selasa',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF221',
          'name': 'Struktur Data',
          'semester': 5,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2026/2027',
        'semester': '5',
        'day': 'Kamis',
        'start_time': '10:00',
        'end_time': '12:30',
        'course': {
          'code': 'IF224',
          'name': 'Interaksi Manusia dan Komputer',
          'semester': 5,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2025/2026',
        'semester': '4',
        'day': 'Senin',
        'start_time': '10:00',
        'end_time': '13:20',
        'course': {
          'code': 'IF215',
          'name': 'Pemrograman Berorientasi Objek',
          'semester': 4,
          'sks': 4,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2025/2026',
        'semester': '4',
        'day': 'Rabu',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF218',
          'name': 'Jaringan Komputer',
          'semester': 4,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas C',
        'year': '2025/2026',
        'semester': '3',
        'day': 'Selasa',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'IF101',
          'name': 'Pengantar Teknologi Informasi',
          'semester': 3,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas C',
        'year': '2025/2026',
        'semester': '3',
        'day': 'Kamis',
        'start_time': '10:00',
        'end_time': '12:30',
        'course': {
          'code': 'MT101',
          'name': 'Matematika Dasar',
          'semester': 3,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2024/2025',
        'semester': '2',
        'day': 'Senin',
        'start_time': '08:00',
        'end_time': '11:20',
        'course': {
          'code': 'IF105',
          'name': 'Algoritma dan Pemrograman',
          'semester': 2,
          'sks': 4,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas B',
        'year': '2024/2025',
        'semester': '2',
        'day': 'Rabu',
        'start_time': '08:00',
        'end_time': '10:30',
        'course': {
          'code': 'MT102',
          'name': 'Matematika Diskrit',
          'semester': 2,
          'sks': 3,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2024/2025',
        'semester': '1',
        'day': 'Selasa',
        'start_time': '08:00',
        'end_time': '09:40',
        'course': {
          'code': 'IF100',
          'name': 'Pengantar Ilmu Komputer',
          'semester': 1,
          'sks': 2,
        },
      },
    },
    {
      'class': {
        'name': 'Kelas A',
        'year': '2024/2025',
        'semester': '1',
        'day': 'Kamis',
        'start_time': '08:00',
        'end_time': '11:20',
        'course': {
          'code': 'MT100',
          'name': 'Kalkulus I',
          'semester': 1,
          'sks': 4,
        },
      },
    },
  ];

  final List<Map<String, dynamic>>? mockEnrollments;

  @override
  State<KrsTab> createState() => _KrsTabState();
}

class _KrsTabState extends State<KrsTab> {
  static const Color _navy = Color(0xFF082D5C);
  static const Color _blue = Color(0xFF1F5F9D);
  static const Color _turquoise = Color(0xFF159D9B);
  static const Color _lightTurquoise = Color(0xFFD7F1F0);
  static const Color _background = Color(0xFFF5F8FC);
  static const Color _textSecondary = Color(0xFF68778B);
  static const Color _border = Color(0xFFE2E8F0);

  bool _isLoading = true;
  String? _errorMessage;
  _AcademicPeriod? _selectedPeriod;
  _AcademicPeriod? _pendingPeriod;
  String? _selectedYear;
  List<dynamic> _krsData = [];

  @override
  void initState() {
    super.initState();
    _fetchKRS();
  }

  Future<void> _fetchKRS({_AcademicPeriod? period}) async {
    if (!mounted) return;
    final requestedPeriod = period ?? _selectedPeriod;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pendingPeriod = requestedPeriod;
    });

    try {
      final List<dynamic> krsData;
      if (widget.mockEnrollments != null) {
        krsData = widget.mockEnrollments!;
      } else {
        final response = await ApiService.get('/enrollments/my');
        krsData = response['data'] ?? [];
      }
      final periods = _availablePeriods(krsData);
      final matchingPeriod = _findPeriod(periods, requestedPeriod?.key);

      if (!mounted) return;
      setState(() {
        _krsData = krsData;
        _selectedPeriod = matchingPeriod ?? _firstPeriod(periods);
        _selectedYear = _selectedPeriod?.year;
        _pendingPeriod = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching KRS: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'KRS belum dapat dimuat. Periksa koneksi lalu coba lagi.';
        _isLoading = false;
      });
    }
  }

  Map _mapOf(dynamic value) {
    return value is Map ? value : const <String, dynamic>{};
  }

  String? _value(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  _AcademicPeriod? _periodFor(dynamic enrollment) {
    final classData = _mapOf(_mapOf(enrollment)['class']);
    final year = _value(classData['year']);
    final semester = _value(classData['semester']);
    if (year == null && semester == null) {
      return const _AcademicPeriod();
    }
    return _AcademicPeriod(year: year, semester: semester);
  }

  List<_AcademicPeriod> _availablePeriods([List<dynamic>? data]) {
    final periods = <String, _AcademicPeriod>{};
    for (final enrollment in data ?? _krsData) {
      final period = _periodFor(enrollment);
      if (period != null) periods.putIfAbsent(period.key, () => period);
    }
    final sortedPeriods = periods.values.toList()..sort(_comparePeriods);
    return sortedPeriods;
  }

  _AcademicPeriod? _findPeriod(List<_AcademicPeriod> periods, String? key) {
    for (final period in periods) {
      if (period.key == key) return period;
    }
    return null;
  }

  _AcademicPeriod? _firstPeriod(List<_AcademicPeriod> periods) {
    return periods.isEmpty ? null : periods.first;
  }

  List<String> get _availableYears {
    final years = _availablePeriods()
        .map((period) => period.year)
        .whereType<String>()
        .toSet()
        .toList();
    years.sort((left, right) => _yearOrder(right) - _yearOrder(left));
    return years;
  }

  _AcademicPeriod? _periodForYearAndType(String year, String type) {
    final matchingPeriods = _availablePeriods()
        .where((period) => period.year == year && period.semesterType == type)
        .toList();
    return matchingPeriods.isEmpty ? null : matchingPeriods.first;
  }

  Future<void> _selectYear(String year) async {
    final previousType = _selectedPeriod?.semesterType;
    final matchingPeriod = previousType == null
        ? null
        : _periodForYearAndType(year, previousType);
    final selectedPeriod =
        matchingPeriod ??
        _availablePeriods().firstWhere((period) => period.year == year);
    await _fetchKRS(period: selectedPeriod);
  }

  Future<void> _selectSemester(String type) async {
    final year = _selectedYear;
    if (year == null) return;
    final period = _periodForYearAndType(year, type);
    if (period == null) return;
    await _fetchKRS(period: period);
  }

  int _comparePeriods(_AcademicPeriod left, _AcademicPeriod right) {
    final leftSemester = left.semesterNumber;
    final rightSemester = right.semesterNumber;
    if (leftSemester != null && rightSemester != null) {
      return rightSemester.compareTo(leftSemester);
    }
    final yearComparison = _yearOrder(right.year) - _yearOrder(left.year);
    if (yearComparison != 0) return yearComparison;
    final semesterComparison =
        _semesterOrder(right.semester) - _semesterOrder(left.semester);
    if (semesterComparison != 0) return semesterComparison;
    return right.label.compareTo(left.label);
  }

  int _yearOrder(String? year) {
    final match = RegExp(r'\d{4}').firstMatch(year ?? '');
    return match == null ? 0 : int.parse(match.group(0)!);
  }

  int _semesterOrder(String? semester) {
    final value = (semester ?? '').toLowerCase();
    if (value.contains('genap') || value.contains('even')) return 2;
    if (value.contains('ganjil') || value.contains('odd')) return 1;
    final number = RegExp(r'\d+').firstMatch(value);
    return number == null ? 0 : int.parse(number.group(0)!);
  }

  List<dynamic> get _visibleKrs {
    if (_selectedPeriod == null) return _krsData;
    return _krsData
        .where(
          (enrollment) => _periodFor(enrollment)?.key == _selectedPeriod!.key,
        )
        .toList();
  }

  String get _academicYear {
    return _selectedPeriod?.label ?? '—';
  }

  int get _totalSKS {
    return _visibleKrs.fold<int>(0, (total, item) {
      final course = _mapOf(_mapOf(_mapOf(item)['class'])['course']);
      final value = course['sks'];
      if (value is num) return total + value.toInt();
      return total + (int.tryParse(value?.toString() ?? '') ?? 0);
    });
  }

  int? _durationInMinutes(dynamic startValue, dynamic endValue) {
    final start = _value(startValue);
    final end = _value(endValue);
    if (start == null || end == null) return null;

    final timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');
    final startMatch = timePattern.firstMatch(start);
    final endMatch = timePattern.firstMatch(end);
    if (startMatch == null || endMatch == null) return null;

    final startHour = int.parse(startMatch.group(1)!);
    final startMinute = int.parse(startMatch.group(2)!);
    final endHour = int.parse(endMatch.group(1)!);
    final endMinute = int.parse(endMatch.group(2)!);
    if (startHour > 23 || endHour > 23 || startMinute > 59 || endMinute > 59) {
      return null;
    }

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    return endMinutes > startMinutes ? endMinutes - startMinutes : null;
  }

  int? get _totalMinutes {
    var total = 0;
    var hasSchedule = false;
    for (final enrollment in _visibleKrs) {
      final classData = _mapOf(_mapOf(enrollment)['class']);
      final minutes = _durationInMinutes(
        classData['start_time'],
        classData['end_time'],
      );
      if (minutes != null) {
        total += minutes;
        hasSchedule = true;
      }
    }
    return hasSchedule ? total : null;
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes mnt';
    if (remainingMinutes == 0) return '$hours jam';
    return '$hours jam $remainingMinutes mnt';
  }

  String get _classNames {
    final names = <String>[];
    for (final enrollment in _visibleKrs) {
      final className = _value(_mapOf(_mapOf(enrollment)['class'])['name']);
      if (className != null && !names.contains(className)) names.add(className);
    }
    return names.isEmpty ? '—' : names.join(', ');
  }

  String? _scheduleFor(dynamic enrollment) {
    final classData = _mapOf(_mapOf(enrollment)['class']);
    final day = _value(classData['day']);
    final start = _value(classData['start_time']);
    final end = _value(classData['end_time']);
    final time = [start, end].whereType<String>().join('–');
    final parts = [day, time].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' • ');
  }

  void _showPrintUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fitur cetak belum tersedia. Solusi cetak/PDF memerlukan dukungan frontend tambahan.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        toolbarHeight: 82,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: Color(0x332D83B5),
              child: Icon(Icons.menu_book_rounded, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kartu Rencana Studi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Rencana studi semester akademik',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFD7F1F0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_blue, _turquoise]),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _navy))
          : RefreshIndicator(
              color: _turquoise,
              onRefresh: _fetchKRS,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? 16.0
                      : 20.0;
                  final contentWidth =
                      constraints.maxWidth - horizontalPadding * 2;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      22,
                      horizontalPadding,
                      32,
                    ),
                    children: [
                      if (widget.mockEnrollments != null) ...[
                        _buildDemoBadge(),
                        const SizedBox(height: 14),
                      ],
                      if (_krsData.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildPeriodSelector(),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionTitle('Ringkasan akademik'),
                      const SizedBox(height: 12),
                      _buildAcademicSummary(contentWidth),
                      const SizedBox(height: 28),
                      _buildCourseSectionHeading(),
                      const SizedBox(height: 12),
                      if (_errorMessage != null)
                        _buildErrorState()
                      else if (_visibleKrs.isEmpty)
                        _buildEmptyState()
                      else ...[
                        ..._visibleKrs.asMap().entries.map(
                          (entry) =>
                              _buildCourseItem(entry.key + 1, entry.value),
                        ),
                        const SizedBox(height: 3),
                        _buildTotals(),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _showPrintUnavailable,
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Cetak KRS'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _turquoise,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
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
          border: Border.all(color: const Color(0xFFFFC83D)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, color: _navy, size: 15),
            SizedBox(width: 6),
            Text(
              'DEMO · DATA ILUSTRASI',
              style: TextStyle(
                color: _navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final years = _availableYears;
    final selectedYear = _selectedYear;
    final ganjilAvailable =
        selectedYear != null &&
        _periodForYearAndType(selectedYear, 'Ganjil') != null;
    final genapAvailable =
        selectedYear != null &&
        _periodForYearAndType(selectedYear, 'Genap') != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PILIH TAHUN AKADEMIK',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 5),
          DropdownButton<String>(
            value: years.contains(selectedYear) ? selectedYear : null,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _navy),
            hint: const Text('Pilih tahun akademik'),
            style: const TextStyle(
              color: _navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            items: years
                .map(
                  (year) =>
                      DropdownMenuItem<String>(value: year, child: Text(year)),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (year) {
                    if (year != null) _selectYear(year);
                  },
          ),
          const SizedBox(height: 10),
          const Text(
            'SEMESTER',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 9,
            runSpacing: 8,
            children: [
              _buildSemesterOption('Ganjil', available: ganjilAvailable),
              _buildSemesterOption('Genap', available: genapAvailable),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterOption(String type, {required bool available}) {
    final selected = _selectedPeriod?.semesterType == type;
    return ChoiceChip(
      label: Text(type),
      selected: selected,
      onSelected: !available || _isLoading
          ? null
          : (_) => _selectSemester(type),
      selectedColor: _lightTurquoise,
      disabledColor: const Color(0xFFF1F4F7),
      labelStyle: TextStyle(
        color: !available
            ? const Color(0xFF9AA5B1)
            : selected
            ? _navy
            : _textSecondary,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected && available ? _turquoise : _border),
      showCheckmark: false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
      ),
    );
  }

  Widget _buildAcademicSummary(double width) {
    final columns = width < 320 ? 1 : 2;
    final cardWidth = columns == 1 ? width : (width - 12) / 2;
    final List<
      ({IconData icon, String label, String value, Color color, Color tint})
    >
    metrics = [
      (
        icon: Icons.calendar_today_outlined,
        label: 'PERIODE AKADEMIK',
        value: _academicYear,
        color: _blue,
        tint: const Color(0xFFE6EFF8),
      ),
      (
        icon: Icons.groups_2_outlined,
        label: 'KELAS / PARALEL',
        value: _classNames,
        color: _turquoise,
        tint: _lightTurquoise,
      ),
      (
        icon: Icons.menu_book_outlined,
        label: 'TOTAL SKS',
        value: '$_totalSKS',
        color: _turquoise,
        tint: _lightTurquoise,
      ),
      (
        icon: Icons.format_list_numbered_rounded,
        label: 'MATA KULIAH',
        value: '${_visibleKrs.length}',
        color: _blue,
        tint: const Color(0xFFE6EFF8),
      ),
      (
        icon: Icons.auto_graph_outlined,
        label: 'IP SEMESTER LALU',
        value: '—',
        color: _blue,
        tint: const Color(0xFFE6EFF8),
      ),
      (
        icon: Icons.stars_outlined,
        label: 'IP KUMULATIF (IPK)',
        value: '—',
        color: _navy,
        tint: const Color(0xFFFFF5D6),
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: metric.icon,
                label: metric.label,
                value: metric.value,
                color: metric.color,
                tint: metric.tint,
                isUnavailable: metric.value == '—',
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color tint,
    required bool isUnavailable,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnavailable ? _textSecondary : _navy,
              fontSize: isUnavailable ? 16 : 15,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSectionHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Rencana Studi Aktif',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.25,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Daftar mata kuliah pada periode terpilih.',
          style: TextStyle(color: _textSecondary, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCourseItem(int number, dynamic enrollment) {
    final classData = _mapOf(_mapOf(enrollment)['class']);
    final course = _mapOf(classData['course']);
    final code = _value(course['code']);
    final name = _value(course['name']) ?? 'Nama mata kuliah belum tersedia';
    final semester = _value(course['semester']);
    final sks = _value(course['sks']);
    final schedule = _scheduleFor(enrollment);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _lightTurquoise,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (code != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (semester != null || sks != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if (semester != null)
                        _buildBadge('Semester $semester', _blue),
                      if (sks != null) _buildBadge('$sks SKS', _turquoise),
                    ],
                  ),
                ],
                if (schedule != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: _textSecondary,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          schedule,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTotals() {
    final totalMinutes = _totalMinutes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightTurquoise,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _turquoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTotalValue(
              icon: Icons.menu_book_outlined,
              label: 'TOTAL SKS',
              value: '$_totalSKS',
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: _turquoise.withValues(alpha: 0.22),
          ),
          Expanded(
            child: _buildTotalValue(
              icon: Icons.schedule_rounded,
              label: 'TOTAL JAM',
              value: totalMinutes == null ? '—' : _formatDuration(totalMinutes),
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalValue({
    required IconData icon,
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _turquoise, size: 17),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _navy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.45,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return _buildStatusCard(
      icon: Icons.menu_book_outlined,
      title: 'KRS belum dibagikan',
      message: 'Daftar mata kuliah akan tampil di sini setelah dibagikan oleh admin.',
      iconColor: _turquoise,
      iconBackground: _lightTurquoise,
    );
  }

  Widget _buildErrorState() {
    return _buildStatusCard(
      icon: Icons.cloud_off_outlined,
      title: 'Data belum tersedia',
      message: _errorMessage!,
      iconColor: _blue,
      iconBackground: const Color(0xFFE6EFF8),
      action: OutlinedButton.icon(
        onPressed: () => _fetchKRS(period: _pendingPeriod ?? _selectedPeriod),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Coba lagi'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _navy,
          side: const BorderSide(color: _navy),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String message,
    required Color iconColor,
    required Color iconBackground,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: iconColor, size: 29),
          ),
          const SizedBox(height: 14),
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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }
}
