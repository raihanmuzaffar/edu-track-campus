import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class NilaiTab extends StatefulWidget {
  const NilaiTab({super.key});

  @override
  State<NilaiTab> createState() => _NilaiTabState();
}

class _NilaiTabState extends State<NilaiTab> {
  static const Color _navy = Color(0xFF082D5C);
  static const Color _blue = Color(0xFF1F5F9D);
  static const Color _turquoise = Color(0xFF159D9B);
  static const Color _lightTurquoise = Color(0xFFD7F1F0);
  static const Color _offWhite = Color(0xFFF5F8FC);
  static const Color _yellow = Color(0xFFFFC83D);
  static const Color _muted = Color(0xFF68788D);

  bool _isLoading = true;
  bool _hasError = false;
  List<dynamic> _gradesData = [];

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      if (_gradesData.isEmpty) _isLoading = true;
    });

    try {
      final response = await ApiService.get('/grades/my');
      if (response is! Map || response['data'] is! List) {
        throw const FormatException('Unexpected grades response');
      }
      if (!mounted) return;
      setState(() {
        _gradesData = response['data'] as List;
        _isLoading = false;
        _hasError = false;
      });
    } on Exception catch (error) {
      debugPrint('Error fetching grades: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  dynamic _field(dynamic value, String key) {
    return value is Map<dynamic, dynamic> ? value[key] : null;
  }

  String? _displayValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  List<double> get _numericScores => _gradesData
      .map(
        (item) => double.tryParse(_displayValue(_field(item, 'score')) ?? ''),
      )
      .whereType<double>()
      .toList();

  int get _letterCount => _gradesData
      .where((item) => _displayValue(_field(item, 'letter')) != null)
      .length;

  String? get _averageScore {
    final scores = _numericScores;
    if (scores.isEmpty) return null;
    final average =
        scores.reduce((total, score) => total + score) / scores.length;
    return average % 1 == 0
        ? average.toStringAsFixed(0)
        : average.toStringAsFixed(1);
  }

  Color _letterColor(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return _turquoise;
      case 'B':
        return _blue;
      case 'C':
        return _yellow;
      default:
        return _navy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: RefreshIndicator(
          color: _turquoise,
          onRefresh: _fetchGrades,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 22),
                          if (_isLoading && _gradesData.isEmpty)
                            _buildLoading(constraints.maxHeight)
                          else if (_hasError && _gradesData.isEmpty)
                            _buildError(constraints.maxHeight)
                          else if (_gradesData.isEmpty)
                            _buildEmpty(constraints.maxHeight)
                          else ...[
                            if (_hasError) ...[
                              _buildRefreshError(),
                              const SizedBox(height: 16),
                            ],
                            _buildSummary(),
                            const SizedBox(height: 26),
                            Text(
                              'Daftar mata kuliah',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            ..._gradesData.map(_buildCourseCard),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: _yellow,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'EduTrack',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AKADEMIK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Nilai Akademik',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pantau hasil belajar dan nilai setiap mata kuliahmu.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: _turquoise,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 14,
                height: 3,
                decoration: BoxDecoration(
                  color: _yellow,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(double availableHeight) {
    return SizedBox(
      height: (availableHeight - 190).clamp(180.0, 360.0).toDouble(),
      child: const Center(child: CircularProgressIndicator(color: _turquoise)),
    );
  }

  Widget _buildError(double availableHeight) {
    return SizedBox(
      height: (availableHeight - 190).clamp(220.0, 360.0).toDouble(),
      child: Center(
        child: _StateCard(
          icon: Icons.cloud_off_rounded,
          title: 'Nilai belum dapat dimuat',
          description: 'Periksa koneksi internet, lalu coba lagi.',
          action: FilledButton.icon(
            onPressed: _fetchGrades,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba lagi'),
            style: FilledButton.styleFrom(
              backgroundColor: _turquoise,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(double availableHeight) {
    return SizedBox(
      height: (availableHeight - 190).clamp(220.0, 360.0).toDouble(),
      child: const Center(
        child: _StateCard(
          icon: Icons.auto_graph_rounded,
          title: 'Belum ada nilai',
          description:
              'Nilai mata kuliah akan tampil di sini setelah tersedia.',
        ),
      ),
    );
  }

  Widget _buildRefreshError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _navy, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Pembaruan gagal. Tampilkan nilai yang sudah dimuat.',
              style: TextStyle(color: _navy, fontSize: 12, height: 1.4),
            ),
          ),
          TextButton(
            onPressed: _fetchGrades,
            child: const Text(
              'Ulangi',
              style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF5)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan nilai',
            style: TextStyle(
              color: _navy,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  icon: Icons.bar_chart_rounded,
                  label: 'Rata-rata skor',
                  value: _averageScore ?? '—',
                  accent: _turquoise,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.grade_rounded,
                  label: 'Nilai huruf tercatat',
                  value: '$_letterCount',
                  accent: _blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic item) {
    final course = _field(_field(item, 'class'), 'course');
    final courseName =
        _displayValue(_field(course, 'name')) ??
        'Nama mata kuliah tidak tersedia';
    final courseCode = _displayValue(_field(course, 'code'));
    final sks = _displayValue(_field(course, 'sks'));
    final score = _displayValue(_field(item, 'score'));
    final letter = _displayValue(_field(item, 'letter'));
    final sksDetail = sks == null ? null : '$sks SKS';
    final details = <String>[?courseCode, ?sksDetail];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF5)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: _turquoise,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    details.join('  ·  '),
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (score != null || letter != null) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (score != null)
                  Text(
                    score,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                if (letter != null) ...[
                  if (score != null) const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _letterColor(letter).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        color: _letterColor(letter),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _NilaiTabState._offWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NilaiTabState._navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NilaiTabState._muted,
                    fontSize: 10,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EEF5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: _NilaiTabState._lightTurquoise,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _NilaiTabState._turquoise, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _NilaiTabState._navy,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _NilaiTabState._muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          ?action,
        ],
      ),
    );
  }
}
