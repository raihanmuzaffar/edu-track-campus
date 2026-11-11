import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/financial_summary_card.dart';
import 'widgets/menu_card.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/parent_header.dart';
import 'widgets/section_header.dart';
import 'widgets/summary_card.dart';

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key, required this.data, required this.onNavigate});

  final OrangTuaDashboardData data;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final student = data.student;
    final attendance = data.attendance;
    final activeSemester = data.semesters.isEmpty ? null : data.semesters.last;
    final semesterGpa = activeSemester?.semesterGpa;
    final nextSchedule = data.schedules.isEmpty ? null : data.schedules.first;
    final latestAnnouncement = data.announcements.isEmpty
        ? null
        : data.announcements.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        ParentHeader(
          isDemo: data.isDemo,
          parentName: data.parent?.name,
          onProfileTap: () => onNavigate(6),
          onAnnouncementsTap: () => onNavigate(5),
        ),
        const SizedBox(height: 22),
        _WelcomeCard(isDemo: data.isDemo, onTap: () => onNavigate(1)),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Pantau perkembangan',
          subtitle: 'Ringkasan akademik dan kehadiran anak.',
          isDemo: false,
        ),
        if (student == null)
          EmptyState(
            title: 'Profil anak belum tersedia',
            message:
                'Informasi akademik akan tampil di sini setelah akun anak '
                'terhubung dengan akun orang tua.',
            icon: Icons.school_outlined,
            actionLabel: 'Lihat profil anak',
            onAction: () => onNavigate(1),
          )
        else ...[
          _StudentCard(
            name: student.name,
            studyProgram: student.studyProgram,
            nim: student.nim,
            isDemo: data.isDemo,
            onTap: () => onNavigate(1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  label: 'Kehadiran',
                  value: attendance == null || attendance.total == 0
                      ? '--'
                      : '${(attendance.attendanceRate * 100).round()}%',
                  caption: attendance == null
                      ? 'Belum ada data'
                      : '${attendance.present} kali hadir',
                  icon: Icons.fact_check_outlined,
                  accent: OrangTuaColors.emerald,
                  onTap: () => onNavigate(3),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: SummaryCard(
                  label: 'IP Semester',
                  value: semesterGpa == null
                      ? '--'
                      : semesterGpa.toStringAsFixed(2),
                  caption: activeSemester == null
                      ? 'Belum ada nilai'
                      : 'IP Semester · IPK ${activeSemester.cumulativeGpa.toStringAsFixed(2)}',
                  icon: Icons.auto_graph_rounded,
                  accent: OrangTuaColors.orange,
                  onTap: () => onNavigate(2),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Keuangan semester aktif',
          subtitle: 'Pantau tagihan UKT dan status pengajuan.',
          actionLabel: 'Lihat detail',
          onAction: () => onNavigate(8),
        ),
        FinancialSummaryCard(
          financial: data.financial,
          isDemo: data.isDemo,
          onTap: () => onNavigate(8),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Jadwal kuliah',
          subtitle: 'Agenda perkuliahan yang tercatat.',
          actionLabel: 'Lihat semua',
          onAction: () => onNavigate(4),
        ),
        if (nextSchedule == null)
          _CompactEmpty(
            icon: Icons.calendar_month_outlined,
            message: 'Belum ada jadwal kuliah yang tersedia.',
            onTap: () => onNavigate(4),
          )
        else
          ParentCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: OrangTuaColors.paleGreen,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        nextSchedule.weekdayName,
                        style: const TextStyle(
                          color: OrangTuaColors.emeraldDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${nextSchedule.startTime}–${nextSchedule.endTime}',
                        style: const TextStyle(
                          color: OrangTuaColors.forest,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextSchedule.course,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OrangTuaColors.forest,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        nextSchedule.room ?? 'Ruang belum tersedia',
                        style: const TextStyle(
                          color: OrangTuaColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: OrangTuaColors.muted,
                ),
              ],
            ),
          ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Pengumuman terbaru',
          subtitle: 'Informasi penting dari kampus.',
          actionLabel: 'Lihat semua',
          onAction: () => onNavigate(5),
        ),
        if (latestAnnouncement == null)
          _CompactEmpty(
            icon: Icons.campaign_outlined,
            message: 'Belum ada pengumuman terbaru.',
            onTap: () => onNavigate(5),
          )
        else
          _AnnouncementPreview(
            title: latestAnnouncement.title,
            category: latestAnnouncement.category,
            date: latestAnnouncement.date,
            summary: latestAnnouncement.summary,
            onTap: () => onNavigate(5),
          ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Akses cepat',
          subtitle: 'Pilih informasi yang ingin dilihat.',
        ),
        MenuCard(
          title: 'Nilai akademik',
          subtitle: 'Lihat capaian per mata kuliah',
          icon: Icons.school_outlined,
          onTap: () => onNavigate(2),
        ),
        const SizedBox(height: 10),
        MenuCard(
          title: 'Riwayat kehadiran',
          subtitle: 'Ringkasan dan catatan perkuliahan',
          icon: Icons.event_available_outlined,
          accent: OrangTuaColors.orange,
          onTap: () => onNavigate(3),
        ),
        const SizedBox(height: 10),
        MenuCard(
          title: 'Jadwal kuliah',
          subtitle: 'Hari, waktu, dosen, dan ruang',
          icon: Icons.calendar_month_outlined,
          onTap: () => onNavigate(4),
        ),
        const SizedBox(height: 10),
        MenuCard(
          title: 'Keuangan & UKT',
          subtitle: 'Ringkasan tagihan dan riwayat pembayaran',
          icon: Icons.account_balance_wallet_outlined,
          accent: OrangTuaColors.orange,
          onTap: () => onNavigate(8),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.isDemo, required this.onTap});

  final bool isDemo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 12, 19),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [OrangTuaColors.emeraldDark, OrangTuaColors.emerald],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: OrangTuaColors.emeraldDark.withValues(alpha: .2),
          blurRadius: 20,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDemo ? 'RUANG PANTAU · DEMO' : 'RUANG PANTAU',
                style: const TextStyle(
                  color: Color(0xFFD8EEE4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Perjalanan kuliah,\nlebih dekat untuk keluarga.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  height: 1.28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Informasi akademik tersaji dalam satu tempat.',
                style: TextStyle(
                  color: Color(0xFFE0F0E9),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: OrangTuaColors.forest,
                  backgroundColor: const Color(0xFFFFF3E8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Profil anak  →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const _HeroIllustration(),
      ],
    ),
  );
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 118,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .11),
            shape: BoxShape.circle,
          ),
        ),
        const Positioned(
          top: 16,
          right: 4,
          child: Icon(Icons.auto_awesome, color: Color(0xFFFFD6A9), size: 17),
        ),
        const Positioned(
          bottom: 8,
          left: 1,
          child: Icon(Icons.circle, color: Color(0xFFB5D9C8), size: 9),
        ),
        const Icon(Icons.menu_book_rounded, color: Color(0xFFFFE6CC), size: 68),
      ],
    ),
  );
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.name,
    required this.studyProgram,
    required this.nim,
    required this.isDemo,
    required this.onTap,
  });

  final String name;
  final String studyProgram;
  final String nim;
  final bool isDemo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: OrangTuaColors.paleGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: OrangTuaColors.emeraldDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OrangTuaColors.forest,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isDemo)
                      const Icon(
                        Icons.verified_rounded,
                        color: OrangTuaColors.emerald,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  studyProgram,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'NIM  $nim${isDemo ? ' · data demo' : ''}',
                  style: const TextStyle(
                    color: OrangTuaColors.emeraldDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: OrangTuaColors.muted),
        ],
      ),
    ),
  );
}

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({
    required this.title,
    required this.category,
    required this.date,
    required this.summary,
    required this.onTap,
  });

  final String title;
  final String category;
  final String date;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: OrangTuaColors.paleOrange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.campaign_outlined,
                color: OrangTuaColors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$category  ·  $date',
                    style: const TextStyle(
                      color: OrangTuaColors.emeraldDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: const TextStyle(
                      color: OrangTuaColors.forest,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OrangTuaColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: OrangTuaColors.muted,
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompactEmpty extends StatelessWidget {
  const _CompactEmpty({
    required this.icon,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: const EdgeInsets.all(15),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: OrangTuaColors.emerald, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: OrangTuaColors.muted, fontSize: 12),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: OrangTuaColors.muted),
        ],
      ),
    ),
  );
}
