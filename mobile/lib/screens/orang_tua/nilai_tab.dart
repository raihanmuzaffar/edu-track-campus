import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class NilaiTab extends StatefulWidget {
  const NilaiTab({super.key, required this.data});

  final OrangTuaDashboardData data;

  @override
  State<NilaiTab> createState() => _NilaiTabState();
}

class _NilaiTabState extends State<NilaiTab> {
  String? _selectedSemesterId;

  @override
  void initState() {
    super.initState();
    _selectedSemesterId = _latestSemesterId(widget.data.semesters);
  }

  @override
  void didUpdateWidget(covariant NilaiTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.semesters != widget.data.semesters) {
      _selectedSemesterId = _latestSemesterId(widget.data.semesters);
    }
  }

  String? _latestSemesterId(List<AcademicSemester> semesters) =>
      semesters.isEmpty ? null : semesters.last.id;

  void _selectSemester(String id) {
    setState(() => _selectedSemesterId = id);
  }

  @override
  Widget build(BuildContext context) {
    final semesters = widget.data.semesters;
    final selectedIndex = semesters.indexWhere(
      (semester) => semester.id == _selectedSemesterId,
    );
    final safeIndex = selectedIndex < 0 && semesters.isNotEmpty
        ? semesters.length - 1
        : selectedIndex;
    final selected = safeIndex < 0 ? null : semesters[safeIndex];
    final previous = safeIndex > 0 ? semesters[safeIndex - 1] : null;
    final semesterGpa = selected?.semesterGpa;
    final previousSemesterGpa = previous?.semesterGpa;
    final semesterChange = semesterGpa == null || previousSemesterGpa == null
        ? null
        : semesterGpa - previousSemesterGpa;
    final cumulativeChange = selected == null || previous == null
        ? null
        : selected.cumulativeGpa - previous.cumulativeGpa;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        SectionHeader(
          title: 'Nilai akademik',
          subtitle: 'Pantau perkembangan nilai setiap semester.',
          isDemo: widget.data.isDemo,
        ),
        if (semesters.isEmpty)
          const EmptyState(
            title: 'Belum ada data nilai',
            message:
                'IP semester, IPK, dan mata kuliah akan tampil setelah hasil '
                'akademik tersedia. Tidak ada nilai contoh pada akun ini.',
            icon: Icons.auto_graph_rounded,
          )
        else ...[
          _SemesterSelector(
            semesters: semesters,
            selectedId: selected!.id,
            onChanged: _selectSemester,
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _GpaCard(
                  label: 'IP semester',
                  value: semesterGpa?.toStringAsFixed(2) ?? '--',
                  detail: 'Semester terpilih',
                  icon: Icons.auto_graph_rounded,
                  accent: OrangTuaColors.emerald,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GpaCard(
                  label: 'IPK kumulatif',
                  value: selected.cumulativeGpa.toStringAsFixed(2),
                  detail: 'Hingga semester ini',
                  icon: Icons.stacked_line_chart_rounded,
                  accent: OrangTuaColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompactMetric(
                  label: 'Beban semester',
                  value: '${selected.totalCredits} SKS',
                  icon: Icons.menu_book_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactMetric(
                  label: 'Mata kuliah',
                  value: '${selected.grades.length}',
                  icon: Icons.library_books_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          _SemesterComparison(
            selected: selected,
            previous: previous,
            semesterChange: semesterChange,
            cumulativeChange: cumulativeChange,
          ),
          const SizedBox(height: 19),
          _GpaTrendChart(
            semesters: semesters,
            selectedIndex: safeIndex,
            onSelect: (index) => _selectSemester(semesters[index].id),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mata kuliah',
                  style: TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                selected.label,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selected.grades.isEmpty)
            const EmptyState(
              title: 'Belum ada mata kuliah',
              message:
                  'Daftar mata kuliah untuk semester terpilih belum tersedia.',
              icon: Icons.menu_book_outlined,
            )
          else
            ...selected.grades.map(
              (grade) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _GradeCard(grade: grade),
              ),
            ),
          if (widget.data.isDemo)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Seluruh riwayat IP, IPK, dan nilai mata kuliah pada preview '
                'merupakan data DEMO.',
                style: TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SemesterSelector extends StatelessWidget {
  const _SemesterSelector({
    required this.semesters,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AcademicSemester> semesters;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.fromLTRB(15, 13, 12, 12),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: OrangTuaColors.paleGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.calendar_month_outlined,
            color: OrangTuaColors.emeraldDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih semester',
                style: TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: OrangTuaColors.emeraldDark,
                  ),
                  style: const TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  items: semesters
                      .map(
                        (semester) => DropdownMenuItem(
                          value: semester.id,
                          child: Text(
                            semester.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id != null) onChanged(id);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GpaCard extends StatelessWidget {
  const _GpaCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Text(
          value,
          style: const TextStyle(
            color: OrangTuaColors.forest,
            fontSize: 25,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          detail,
          style: const TextStyle(color: OrangTuaColors.muted, fontSize: 9),
        ),
      ],
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: OrangTuaColors.emerald, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SemesterComparison extends StatelessWidget {
  const _SemesterComparison({
    required this.selected,
    required this.previous,
    required this.semesterChange,
    required this.cumulativeChange,
  });

  final AcademicSemester selected;
  final AcademicSemester? previous;
  final double? semesterChange;
  final double? cumulativeChange;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perkembangan akademik',
          style: TextStyle(
            color: OrangTuaColors.forest,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          previous == null
              ? 'Belum ada semester sebelumnya untuk dibandingkan.'
              : 'Perbandingan dengan ${previous!.label}.',
          style: const TextStyle(color: OrangTuaColors.muted, fontSize: 10),
        ),
        if (previous != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ChangeMetric(
                  label: 'Perubahan IP',
                  value: semesterChange,
                ),
              ),
              Container(width: 1, height: 36, color: OrangTuaColors.border),
              Expanded(
                child: _ChangeMetric(
                  label: 'Perubahan IPK',
                  value: cumulativeChange,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _ChangeMetric extends StatelessWidget {
  const _ChangeMetric({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final change = value;
    final isPositive = change != null && change >= 0;
    final color = change == null
        ? OrangTuaColors.muted
        : isPositive
        ? OrangTuaColors.emeraldDark
        : const Color(0xFFBD6C63);
    final icon = change == null
        ? Icons.remove_rounded
        : isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final valueText = change == null
        ? '--'
        : '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valueText,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _GpaTrendChart extends StatelessWidget {
  const _GpaTrendChart({
    required this.semesters,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<AcademicSemester> semesters;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = semesters[selectedIndex];

    return ParentCard(
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren IP semester',
            style: TextStyle(
              color: OrangTuaColors.forest,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ketuk titik pada grafik atau pilih semester di atas.',
            style: TextStyle(color: OrangTuaColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 186,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (semesters.length < 2) {
                    onSelect(0);
                    return;
                  }
                  const left = 37.0;
                  const right = 12.0;
                  final plotWidth = constraints.maxWidth - left - right;
                  final relativeX =
                      (details.localPosition.dx - left).clamp(0, plotWidth) /
                      plotWidth;
                  final index = (relativeX * (semesters.length - 1))
                      .round()
                      .clamp(0, semesters.length - 1);
                  onSelect(index);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _GpaChartPainter(
                    semesters: semesters,
                    selectedIndex: selectedIndex,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: OrangTuaColors.emerald,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${selected.label}  ·  IP ${selected.semesterGpa?.toStringAsFixed(2) ?? 'belum tersedia'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpaChartPainter extends CustomPainter {
  _GpaChartPainter({required this.semesters, required this.selectedIndex});

  final List<AcademicSemester> semesters;
  final int selectedIndex;

  static const _left = 37.0;
  static const _right = 12.0;
  static const _top = 17.0;
  static const _bottom = 31.0;
  static const _minimumGpa = 2.0;
  static const _maximumGpa = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    const labels = [2.0, 3.0, 4.0];
    final plotWidth = math.max(0.0, size.width - _left - _right);
    final plotHeight = math.max(0.0, size.height - _top - _bottom);
    if (plotWidth == 0 || plotHeight == 0) return;

    for (final value in labels) {
      final y = _yFor(value, plotHeight);
      canvas.drawLine(
        Offset(_left, y),
        Offset(size.width - _right, y),
        Paint()
          ..color = OrangTuaColors.border
          ..strokeWidth = 1,
      );
      _drawLabel(
        canvas,
        value.toStringAsFixed(0),
        Offset(0, y - 6),
        color: OrangTuaColors.muted,
        fontSize: 9,
      );
    }

    final points = <Offset>[];
    for (var index = 0; index < semesters.length; index++) {
      final gpa = semesters[index].semesterGpa;
      if (gpa == null) continue;
      final x = semesters.length == 1
          ? _left + plotWidth / 2
          : _left + plotWidth * index / (semesters.length - 1);
      points.add(Offset(x, _yFor(gpa, plotHeight)));
    }

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        linePath.lineTo(point.dx, point.dy);
      }

      final fillPath = Path.from(linePath)
        ..lineTo(points.last.dx, _top + plotHeight)
        ..lineTo(points.first.dx, _top + plotHeight)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              OrangTuaColors.emerald.withValues(alpha: .18),
              OrangTuaColors.emerald.withValues(alpha: .015),
            ],
          ).createShader(Rect.fromLTWH(_left, _top, plotWidth, plotHeight)),
      );
      canvas.drawPath(
        linePath,
        Paint()
          ..color = OrangTuaColors.emerald
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var index = 0; index < semesters.length; index++) {
      final gpa = semesters[index].semesterGpa;
      if (gpa == null) continue;
      final x = semesters.length == 1
          ? _left + plotWidth / 2
          : _left + plotWidth * index / (semesters.length - 1);
      final point = Offset(x, _yFor(gpa, plotHeight));
      final selected = index == selectedIndex;

      if (selected) {
        canvas.drawCircle(
          point,
          10,
          Paint()..color = OrangTuaColors.emerald.withValues(alpha: .13),
        );
      }
      canvas.drawCircle(
        point,
        selected ? 5 : 3.5,
        Paint()..color = selected ? OrangTuaColors.orange : Colors.white,
      );
      canvas.drawCircle(
        point,
        selected ? 5 : 3.5,
        Paint()
          ..color = OrangTuaColors.emerald
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      _drawLabel(
        canvas,
        semesters[index].shortLabel,
        Offset(x - 8, size.height - _bottom + 10),
        color: selected ? OrangTuaColors.emeraldDark : OrangTuaColors.muted,
        fontSize: 9,
        bold: selected,
      );
    }
  }

  double _yFor(double gpa, double plotHeight) {
    final clamped = gpa.clamp(_minimumGpa, _maximumGpa);
    return _top +
        plotHeight -
        ((clamped - _minimumGpa) / (_maximumGpa - _minimumGpa)) * plotHeight;
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required Color color,
    required double fontSize,
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GpaChartPainter oldDelegate) =>
      oldDelegate.semesters != semesters ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.grade});

  final CourseGrade grade;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 48,
          decoration: BoxDecoration(
            color: OrangTuaColors.paleGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              grade.letter ?? '—',
              style: const TextStyle(
                color: OrangTuaColors.emeraldDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grade.course,
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${grade.code}  ·  ${grade.credits} SKS',
                style: const TextStyle(
                  color: OrangTuaColors.muted,
                  fontSize: 11,
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
              grade.score?.toString() ?? '—',
              style: const TextStyle(
                color: OrangTuaColors.forest,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              'NILAI',
              style: TextStyle(
                color: OrangTuaColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
