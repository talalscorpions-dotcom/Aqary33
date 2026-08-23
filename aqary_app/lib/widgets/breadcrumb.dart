import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders the current navigation path, e.g. "Properties > Residential > Buy".
/// Built from a plain list of strings so every screen below the top level
/// can reuse it without knowing about routing internals.
class Breadcrumb extends StatelessWidget {
  final List<String> path;

  const Breadcrumb({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < path.length; i++) {
      final isLast = i == path.length - 1;
      spans.add(TextSpan(
        text: path[i],
        style: TextStyle(
          fontSize: 12,
          fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
          color: isLast ? AppColors.tealDark : AppColors.mute,
        ),
      ));
      if (!isLast) {
        spans.add(const TextSpan(
          text: '  ›  ',
          style: TextStyle(fontSize: 11, color: AppColors.mute),
        ));
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(text: TextSpan(children: spans)),
    );
  }
}
