import 'package:flutter/material.dart';

import 'orang_tua_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 26),
    decoration: BoxDecoration(
      color: OrangTuaColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: OrangTuaColors.border),
    ),
    child: Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [OrangTuaColors.paleGreen, Color(0xFFFFF2E6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: OrangTuaColors.emeraldDark, size: 33),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OrangTuaColors.forest,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OrangTuaColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 15),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: OrangTuaColors.emeraldDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
