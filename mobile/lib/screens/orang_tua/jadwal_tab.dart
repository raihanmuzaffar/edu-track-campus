import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class JadwalTab extends StatelessWidget {
  const JadwalTab({super.key, required this.data});

  final OrangTuaDashboardData data;

  @override
  Widget build(BuildContext context) {
    final schedules = [...data.schedules]
      ..sort((a, b) {
        final dayOrder = a.weekday.compareTo(b.weekday);
        return dayOrder != 0 ? dayOrder : a.startTime.compareTo(b.startTime);
      });
    final grouped = <int, List<ClassSchedule>>{};
    for (final schedule in schedules) {
      grouped.putIfAbsent(schedule.weekday, () => []).add(schedule);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        SectionHeader(
          title: 'Jadwal kuliah',
          subtitle: 'Agenda kelas, pengajar, dan lokasi perkuliahan.',
          isDemo: data.isDemo,
        ),
        if (schedules.isEmpty)
          const EmptyState(
            title: 'Jadwal belum tersedia',
            message:
                'Jadwal kuliah akan ditampilkan setelah informasi perkuliahan '
                'tersedia.',
            icon: Icons.calendar_month_outlined,
          )
        else ...[
          if (data.isDemo)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: OrangTuaColors.paleOrange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF9A5728),
                    size: 19,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Jadwal berikut adalah data DEMO, bukan jadwal kuliah nyata.',
                      style: TextStyle(
                        color: Color(0xFF80552F),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ...grouped.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 9),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: OrangTuaColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.value.first.weekdayName,
                          style: const TextStyle(
                            color: OrangTuaColors.forest,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${entry.value.length} kelas',
                          style: const TextStyle(
                            color: OrangTuaColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entry.value.map(
                    (schedule) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ScheduleCard(schedule: schedule),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final ClassSchedule schedule;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              schedule.startTime,
              style: const TextStyle(
                color: OrangTuaColors.emeraldDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              width: 1,
              height: 12,
              color: OrangTuaColors.border,
            ),
            Text(
              schedule.endTime,
              style: const TextStyle(color: OrangTuaColors.muted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(width: 13),
        Container(
          width: 3,
          height: 55,
          decoration: BoxDecoration(
            color: OrangTuaColors.emerald.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                schedule.course,
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              _ScheduleDetail(
                icon: Icons.person_outline_rounded,
                value: schedule.lecturer ?? 'Dosen belum tersedia',
              ),
              const SizedBox(height: 4),
              _ScheduleDetail(
                icon: Icons.location_on_outlined,
                value: schedule.room ?? 'Ruang belum tersedia',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ScheduleDetail extends StatelessWidget {
  const _ScheduleDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: OrangTuaColors.muted, size: 14),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: OrangTuaColors.muted, fontSize: 10),
        ),
      ),
    ],
  );
}
