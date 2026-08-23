import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single dropdown-style filter chip (Bedrooms / Price / Location / Area).
class FilterChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const FilterChipButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lays out 2–3 [FilterChipButton]s in a row. Villa/Apartment results pass
/// Bedrooms + Price + Location; Land results pass Price + Location only,
/// per the filter rules in the Properties Module Architecture doc.
class FilterRow extends StatelessWidget {
  final List<String> filters;
  final ValueChanged<String>? onFilterTap;

  const FilterRow({super.key, required this.filters, this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < filters.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          FilterChipButton(
            label: filters[i],
            onTap: () => onFilterTap?.call(filters[i]),
          ),
        ],
      ],
    );
  }
}

/// The single "Region: All Oman (...)" filter used on Commercial and
/// Industrial results screens, which search nationwide rather than
/// defaulting to Muscat only.
class RegionFilterBar extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const RegionFilterBar({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: AppColors.terra),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.mute),
            ],
          ),
        ),
      ),
    );
  }
}
