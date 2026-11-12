import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class ProfilAnakTab extends StatelessWidget {
  const ProfilAnakTab({super.key, required this.data});

  final OrangTuaDashboardData data;

  @override
  Widget build(BuildContext context) {
    final student = data.student;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      children: [
        SectionHeader(
          title: 'Profil anak',
          subtitle: 'Informasi mahasiswa dan status akademik.',
          isDemo: data.isDemo,
        ),
        if (student == null)
          const EmptyState(
            title: 'Data anak belum terhubung',
            message:
                'Saat akun mahasiswa terhubung, profil dan informasi akademik '
                'akan ditampilkan di halaman ini.',
            icon: Icons.person_search_outlined,
          )
        else ...[
          ParentCard(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: OrangTuaColors.paleGreen,
                    border: Border.all(
                      color: OrangTuaColors.emerald.withValues(alpha: .17),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: OrangTuaColors.emeraldDark,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  student.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  student.studyProgram,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 13,
                  ),
                ),
                if (data.isDemo) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: OrangTuaColors.paleOrange,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'PROFIL CONTOH · DEMO',
                      style: TextStyle(
                        color: Color(0xFF9A5728),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle(
                  icon: Icons.badge_outlined,
                  title: 'Informasi mahasiswa',
                ),
                const SizedBox(height: 8),
                _InformationRow(label: 'NIM', value: student.nim),
                _InformationRow(
                  label: 'Program studi',
                  value: student.studyProgram,
                ),
                _InformationRow(label: 'Fakultas', value: student.faculty),
                _InformationRow(
                  label: 'Semester',
                  value: 'Semester ${student.semester}',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ParentCard(
            color: OrangTuaColors.paleGreen.withValues(alpha: .72),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: OrangTuaColors.emeraldDark,
                  size: 21,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    data.isDemo
                        ? 'Seluruh informasi pada profil ini adalah data DEMO '
                              'untuk preview desain, bukan data mahasiswa sungguhan.'
                        : 'Informasi di halaman ini akan mengikuti data '
                              'mahasiswa yang terhubung ke akun.',
                    style: const TextStyle(
                      color: OrangTuaColors.forest,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: OrangTuaColors.emerald, size: 20),
      const SizedBox(width: 9),
      Text(
        title,
        style: const TextStyle(
          color: OrangTuaColors.forest,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: isLast ? 7 : 11),
    decoration: isLast
        ? null
        : const BoxDecoration(
            border: Border(bottom: BorderSide(color: OrangTuaColors.border)),
          ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(color: OrangTuaColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: OrangTuaColors.forest,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
