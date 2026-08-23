import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ResultsView { list, map }

/// The List/Map switch that appears identically on every results screen
/// (Villas for Sale, Apartments, Offices for Rent, Industrial Land, ...).
class ViewToggle extends StatelessWidget {
  final ResultsView value;
  final ValueChanged<ResultsView> onChanged;

  const ViewToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _segment(context, ResultsView.list, Icons.view_list_rounded, 'List'),
          _segment(context, ResultsView.map, Icons.map_rounded, 'Map'),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, ResultsView v, IconData icon, String label) {
    final active = value == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(v),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: active ? Colors.white : AppColors.mute),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
