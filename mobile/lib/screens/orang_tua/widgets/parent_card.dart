import 'package:flutter/material.dart';

import 'orang_tua_theme.dart';

class ParentCard extends StatelessWidget {
  const ParentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = OrangTuaColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: OrangTuaColors.border.withValues(alpha: .8)),
      boxShadow: [
        BoxShadow(
          color: OrangTuaColors.forest.withValues(alpha: .045),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}
