import 'package:flutter/material.dart';

import 'orang_tua_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.isDemo = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final bool isDemo;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 8, 2, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: OrangTuaColors.forest,
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isDemo)
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
                  'DEMO',
                  style: TextStyle(
                    color: Color(0xFF9A5728),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: OrangTuaColors.emeraldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(
              color: OrangTuaColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ],
    ),
  );
}
