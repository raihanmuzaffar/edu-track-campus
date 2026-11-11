import 'package:flutter/material.dart';

import '../../data/mahasiswa_demo_data.dart';
import '../../services/api_service.dart';

class NilaiTab extends StatefulWidget {
  const NilaiTab({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  State<NilaiTab> createState() => _NilaiTabState();
}

class _NilaiTabState extends State<NilaiTab> {
  static const _navy = Color(0xFF082D5C);
  static const _turquoise = Color(0xFF159D9B);
  static const _background = Color(0xFFF5F8FC);

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _grades = [];
  String? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final List<dynamic> grades;
      if (widget.demoMode) {
        grades = MahasiswaDemoData.grades;
      } else {
        final response = await ApiService.get('/grades/my');
        grades = response['data'] is List ? response['data'] as List : [];
      }
      if (!mounted) return;
      final periods = _periods(grades);
      setState(() {
        _grades = grades;
        _selectedPeriod ??= periods.isEmpty ? null : periods.first;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching Grades: $error');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Data nilai belum dapat dimuat. Coba muat ulang.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};

  String? _periodFor(dynamic grade) {
    final classData = _map(_map(grade)['class']);
    final year = classData['year']?.toString();
    final semester = classData['semester']?.toString();
    if (year == null && semester == null) return null;
    return '${year ?? 'Tahun tidak dicantumkan'} · Semester ${semester ?? '—'}';
  }

  List<String> _periods([List<dynamic>? grades]) {
    final periods = (grades ?? _grades)
        .map(_periodFor)
        .whereType<String>()
        .toSet()
        .toList();
    periods.sort((left, right) => right.compareTo(left));
    return periods;
  }

  List<dynamic> get _visibleGrades => _grades
      .where((grade) => _periodFor(grade) == _selectedPeriod)
      .toList();

  double? get _averageScore {
    final scores = _visibleGrades
        .map((grade) => _map(grade)['score'])
        .whereType<num>()
        .toList();
    if (scores.isEmpty) return null;
    return scores.fold<double>(0, (sum, score) => sum + score) / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Nilai Akademik',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
          : RefreshIndicator(
              color: _turquoise,
              onRefresh: _fetchGrades,
              child: _grades.isEmpty
                  ? _buildEmptyState()
                  : _buildGradeList(),
            ),
    );
  }

  Widget _buildGradeList() {
    final periods = _periods();
    final average = _averageScore;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        if (widget.demoMode) ...[
          _demoBadge(),
          const SizedBox(height: 15),
        ],
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PILIH PERIODE AKADEMIK',
                style: TextStyle(
                  color: Color(0xFF68778B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              DropdownButton<String>(
                value: periods.contains(_selectedPeriod)
                    ? _selectedPeriod
                    : null,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Pilih semester'),
                items: periods
                    .map(
                      (period) => DropdownMenuItem(
                        value: period,
                        child: Text(
                          period,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (period) => setState(() => _selectedPeriod = period),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (average != null) _buildAverageCard(average),
        if (average != null) const SizedBox(height: 20),
        Text(
          'Daftar nilai · ${_visibleGrades.length} mata kuliah',
          style: const TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 11),
        if (_visibleGrades.isEmpty)
          _buildNoPeriodGrades()
        else
          ..._visibleGrades.map(_buildGradeCard),
      ],
    );
  }

  Widget _buildAverageCard(double average) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _turquoise],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RATA-RATA NILAI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Semester terpilih',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            average.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(dynamic grade) {
    final item = _map(grade);
    final classData = _map(item['class']);
    final course = _map(classData['course']);
    final score = item['score'];
    final letter = item['letter']?.toString() ?? '—';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showGradeDetail(grade),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F1F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_outlined, color: _turquoise),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['name']?.toString() ?? 'Mata kuliah',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course['code'] ?? '—'}  •  ${course['sks'] ?? 0} SKS',
                      style: const TextStyle(
                        color: Color(0xFF68778B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    score?.toString() ?? '—',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _letterBadge(letter),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letterBadge(String letter) {
    final passed = const {'A', 'AB', 'B', 'BC', 'C'}.contains(letter);
    final color = passed ? const Color(0xFF27734B) : const Color(0xFFAA4865);
    final fill = passed ? const Color(0xFFE0F3E9) : const Color(0xFFFBE4EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  void _showGradeDetail(dynamic grade) {
    final item = _map(grade);
    final classData = _map(item['class']);
    final course = _map(classData['course']);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _background,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course['name']?.toString() ?? 'Detail nilai',
                style: const TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${course['code'] ?? '—'}  •  ${classData['name'] ?? 'Kelas'}',
                style: const TextStyle(color: Color(0xFF68778B)),
              ),
              const SizedBox(height: 18),
              _detailRow('Nilai angka', item['score']?.toString() ?? '—'),
              _detailRow('Nilai huruf', item['letter']?.toString() ?? '—'),
              _detailRow('Bobot SKS', '${course['sks'] ?? 0} SKS'),
              if (widget.demoMode) ...[
                const SizedBox(height: 12),
                const Text(
                  'DEMO • Data ilustrasi, tidak tersimpan ke backend.',
                  style: TextStyle(color: _turquoise, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF68778B))),
        ),
        Text(
          value,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _buildNoPeriodGrades() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Text(
      _selectedPeriod == null
          ? 'Pilih semester untuk melihat nilai.'
          : 'Belum ada nilai pada periode ini.',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF68778B)),
    ),
  );

  Widget _buildEmptyState() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 100),
      const Icon(Icons.bar_chart_rounded, size: 50, color: _turquoise),
      const SizedBox(height: 12),
      const Text(
        'Belum ada nilai',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _navy,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Nilai akan tampil setelah tersedia.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF68778B)),
      ),
    ],
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: _turquoise),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Data belum tersedia.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fetchGrades,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );

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
}
