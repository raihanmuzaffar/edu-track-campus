import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/financial_summary_card.dart';
import 'widgets/menu_card.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class InformasiTab extends StatelessWidget {
  const InformasiTab({super.key, required this.data, required this.onNavigate});

  final OrangTuaDashboardData data;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
    children: [
      SectionHeader(
        title: 'Informasi kampus',
        subtitle: 'Kehadiran, jadwal kuliah, dan kabar terbaru.',
        isDemo: data.isDemo,
      ),
      ParentCard(
        color: OrangTuaColors.emeraldDark,
        child: Row(
          children: [
            Container(
              width: 47,
              height: 47,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.isDemo ? 'Jelajahi preview DEMO' : 'Tetap terhubung',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.isDemo
                        ? 'Konten contoh ditandai dengan jelas.'
                        : 'Pilih informasi yang ingin dipantau.',
                    style: const TextStyle(
                      color: Color(0xFFDCEDE5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 19),
      FinancialSummaryCard(
        financial: data.financial,
        isDemo: data.isDemo,
        onTap: () => onNavigate(8),
      ),
      const SizedBox(height: 10),
      MenuCard(
        title: 'Detail keuangan & UKT',
        subtitle: data.financial?.activeSemester == null
            ? 'Informasi tagihan belum tersedia'
            : '${data.financial!.activeSemester!.academicTerm}'
                  '${data.isDemo ? ' · DEMO' : ''}',
        icon: Icons.account_balance_wallet_outlined,
        accent: OrangTuaColors.orange,
        onTap: () => onNavigate(8),
      ),
      const SizedBox(height: 10),
      MenuCard(
        title: 'Kehadiran',
        subtitle: data.attendance == null
            ? 'Ringkasan presensi belum tersedia'
            : '${data.attendance!.present} pertemuan tercatat hadir'
                  '${data.isDemo ? ' · DEMO' : ''}',
        icon: Icons.fact_check_outlined,
        onTap: () => onNavigate(3),
      ),
      const SizedBox(height: 10),
      MenuCard(
        title: 'Jadwal kuliah',
        subtitle: data.schedules.isEmpty
            ? 'Belum ada jadwal yang tersedia'
            : '${data.schedules.length} jadwal perkuliahan'
                  '${data.isDemo ? ' · DEMO' : ''}',
        icon: Icons.calendar_month_outlined,
        accent: OrangTuaColors.orange,
        onTap: () => onNavigate(4),
      ),
      const SizedBox(height: 10),
      MenuCard(
        title: 'Pengumuman',
        subtitle: data.announcements.isEmpty
            ? 'Belum ada pengumuman terbaru'
            : '${data.announcements.length} informasi kampus'
                  '${data.isDemo ? ' · DEMO' : ''}',
        icon: Icons.campaign_outlined,
        onTap: () => onNavigate(5),
      ),
      const SizedBox(height: 22),
      Text(
        'Metadata dokumen anak',
        style: TextStyle(
          color: OrangTuaColors.forest,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 10),
      ParentCard(
        color: OrangTuaColors.surface,
        child: data.documents.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Belum ada metadata dokumen yang tersedia.',
                  style: TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              )
            : Column(
                children: [
                  for (var index = 0; index < data.documents.length; index++) ...[
                    if (index > 0)
                      const Divider(height: 20, color: OrangTuaColors.border),
                    _DocumentMetadataRow(document: data.documents[index]),
                  ],
                ],
              ),
      ),
    ],
  );
}

class _DocumentMetadataRow extends StatelessWidget {
  const _DocumentMetadataRow({required this.document});

  final StudentDocument document;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(
        Icons.description_outlined,
        color: OrangTuaColors.emerald,
        size: 20,
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              document.type,
              style: const TextStyle(
                color: OrangTuaColors.forest,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${document.semester} · ${document.status}',
              style: const TextStyle(
                color: OrangTuaColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            Text(
              document.date,
              style: const TextStyle(
                color: OrangTuaColors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
