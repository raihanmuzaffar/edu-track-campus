import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class AbsensiTab extends StatelessWidget {
  const AbsensiTab({super.key, required this.data});

  final OrangTuaDashboardData data;

  @override
  Widget build(BuildContext context) {
    final attendance = data.attendance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        SectionHeader(
          title: 'Kehadiran',
          subtitle: 'Ringkasan perkuliahan dan riwayat presensi.',
          isDemo: data.isDemo,
        ),
        if (attendance == null || attendance.total == 0)
          const EmptyState(
            title: 'Belum ada catatan kehadiran',
            message:
                'Persentase dan riwayat presensi akan tampil setelah data '
                'perkuliahan tersedia.',
            icon: Icons.fact_check_outlined,
          )
        else ...[
          ParentCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Persentase kehadiran',
                            style: TextStyle(
                              color: OrangTuaColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${(attendance.attendanceRate * 100).round()}%',
                            style: const TextStyle(
                              color: OrangTuaColors.forest,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: OrangTuaColors.paleGreen,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: OrangTuaColors.emeraldDark,
                        size: 25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: attendance.attendanceRate.clamp(0, 1),
                    minHeight: 9,
                    backgroundColor: OrangTuaColors.cream,
                    color: OrangTuaColors.emerald,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${attendance.present} dari ${attendance.total} pertemuan tercatat hadir'
                  '${data.isDemo ? ' · data DEMO' : ''}',
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AttendanceCount(
                  label: 'Hadir',
                  count: attendance.present,
                  icon: Icons.check_circle_outline_rounded,
                  color: OrangTuaColors.emerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AttendanceCount(
                  label: 'Izin',
                  count: attendance.excused,
                  icon: Icons.event_note_outlined,
                  color: const Color(0xFF6682B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AttendanceCount(
                  label: 'Sakit',
                  count: attendance.sick,
                  icon: Icons.health_and_safety_outlined,
                  color: OrangTuaColors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AttendanceCount(
                  label: 'Alpa',
                  count: attendance.absent,
                  icon: Icons.highlight_off_rounded,
                  color: const Color(0xFFBD6C63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Riwayat perkuliahan',
            style: TextStyle(
              color: OrangTuaColors.forest,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (attendance.records.isEmpty)
            const EmptyState(
              title: 'Riwayat belum tersedia',
              message: 'Catatan presensi akan muncul di bagian ini.',
              icon: Icons.history_rounded,
            )
          else
            ...attendance.records.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _AttendanceRecordCard(record: record),
              ),
            ),
          if (data.isDemo)
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Informasi presensi di atas hanya data DEMO untuk preview.',
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

class _AttendanceCount extends StatelessWidget {
  const _AttendanceCount({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: OrangTuaColors.muted, fontSize: 11),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: OrangTuaColors.forest,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (record.status) {
      AttendanceStatus.present => (
        'Hadir',
        OrangTuaColors.emerald,
        Icons.check_circle_rounded,
      ),
      AttendanceStatus.excused => (
        'Izin',
        const Color(0xFF6682B8),
        Icons.event_note_rounded,
      ),
      AttendanceStatus.sick => (
        'Sakit',
        OrangTuaColors.orange,
        Icons.health_and_safety_rounded,
      ),
      AttendanceStatus.absent => (
        'Alpa',
        const Color(0xFFBD6C63),
        Icons.highlight_off_rounded,
      ),
    };

    return ParentCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.course,
                  style: const TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.date,
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
