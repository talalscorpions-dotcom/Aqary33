import 'package:flutter/material.dart';

/// A single tappable card in a [CategoryGridScreen] — e.g. one of
/// Residential/Commercial/Agriculture/Industrial, or Buy/Rent/Sell,
/// or Villa/Apartment/Land. The same model drives every level of the
/// Properties taxonomy; only the data changes, not the widget.
class CategoryItem {
  final String id;
  final String label;
  final String? description;
  final IconData icon;
  final List<Color> gradient;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
    this.description,
  });
}
