import 'package:flutter/material.dart';

import 'orang_tua_theme.dart';

class ParentHeader extends StatelessWidget {
  const ParentHeader({
    super.key,
    required this.isDemo,
    required this.onProfileTap,
    required this.onAnnouncementsTap,
    this.parentName,
  });

  final bool isDemo;
  final String? parentName;
  final VoidCallback onProfileTap;
  final VoidCallback onAnnouncementsTap;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'EDUTRACK  ·  ORANG TUA',
                  style: TextStyle(
                    color: OrangTuaColors.emeraldDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                if (isDemo) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: OrangTuaColors.paleOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(
                        color: Color(0xFF9A5728),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Selamat datang,',
              style: TextStyle(
                color: OrangTuaColors.forest.withValues(alpha: .68),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              parentName ?? 'Ayah & Bunda',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: OrangTuaColors.forest,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      _HeaderButton(
        icon: Icons.notifications_none_rounded,
        onTap: onAnnouncementsTap,
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onProfileTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: OrangTuaColors.paleGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: OrangTuaColors.emerald.withValues(alpha: .12),
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: OrangTuaColors.emeraldDark,
          ),
        ),
      ),
    ],
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: OrangTuaColors.surface,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: OrangTuaColors.forest, size: 21),
      ),
    ),
  );
}
