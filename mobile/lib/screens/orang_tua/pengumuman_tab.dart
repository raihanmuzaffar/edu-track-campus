import 'package:flutter/material.dart';

import '../../data/orang_tua_preview_data.dart';
import 'widgets/empty_state.dart';
import 'widgets/orang_tua_theme.dart';
import 'widgets/parent_card.dart';
import 'widgets/section_header.dart';

class PengumumanTab extends StatelessWidget {
  const PengumumanTab({super.key, required this.data});

  final OrangTuaDashboardData data;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
    children: [
      SectionHeader(
        title: 'Pengumuman',
        subtitle: 'Kabar dan informasi dari lingkungan kampus.',
        isDemo: data.isDemo,
      ),
      if (data.announcements.isEmpty)
        const EmptyState(
          title: 'Belum ada pengumuman',
          message: 'Informasi terbaru dari kampus akan tampil di halaman ini.',
          icon: Icons.campaign_outlined,
        )
      else ...[
        if (data.isDemo)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                    'Semua pengumuman di halaman ini adalah konten DEMO.',
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
        ...data.announcements.map(
          (announcement) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: _AnnouncementCard(
              announcement: announcement,
              onTap: () => _showAnnouncement(context, announcement),
            ),
          ),
        ),
      ],
    ],
  );

  void _showAnnouncement(
    BuildContext context,
    CampusAnnouncement announcement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .78,
          ),
          decoration: const BoxDecoration(
            color: OrangTuaColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OrangTuaColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: OrangTuaColors.paleGreen,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text(
                        announcement.category,
                        style: const TextStyle(
                          color: OrangTuaColors.emeraldDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      announcement.date,
                      style: const TextStyle(
                        color: OrangTuaColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  announcement.title,
                  style: const TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 22,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (data.isDemo) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'KONTEN DEMO',
                    style: TextStyle(
                      color: OrangTuaColors.orange,
                      fontSize: 10,
                      letterSpacing: .7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                Text(
                  announcement.body,
                  style: const TextStyle(
                    color: OrangTuaColors.forest,
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OrangTuaColors.emeraldDark,
                      side: const BorderSide(color: OrangTuaColors.emerald),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final CampusAnnouncement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ParentCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: OrangTuaColors.paleOrange,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: OrangTuaColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: OrangTuaColors.paleGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    announcement.category,
                    style: const TextStyle(
                      color: OrangTuaColors.emeraldDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  announcement.date,
                  style: const TextStyle(
                    color: OrangTuaColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              announcement.title,
              style: const TextStyle(
                color: OrangTuaColors.forest,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              announcement.summary,
              style: const TextStyle(
                color: OrangTuaColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Baca selengkapnya',
                  style: TextStyle(
                    color: OrangTuaColors.emeraldDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: OrangTuaColors.emeraldDark,
                  size: 15,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
