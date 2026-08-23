import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/category_item.dart';
import 'category_grid_screen.dart';
import 'property_results_screen.dart';

/// Wires the full Properties taxonomy — Residential is built out completely
/// (Buy/Rent/Sell → Villa/Apartment/Land → results); Commercial, Agriculture,
/// and Industrial are stubbed the same way and are straightforward to finish
/// by copying the Residential pattern below with different [MockData] lists.
///
/// Every screen in this chain is one of the two reusable components —
/// [CategoryGridScreen] or [PropertyResultsScreen] — configured with
/// different data. No new screen widgets are needed to extend the tree.

// ---------------- Level 1: Properties ----------------
Widget buildPropertiesTopScreen(BuildContext context) {
  return CategoryGridScreen(
    title: 'Properties',
    breadcrumbPath: const ['Properties'],
    items: MockData.topLevelCategories,
    footerNote: 'Every listing across all four categories is verified against ownership documentation before it\'s published.',
    onSelect: (item) {
      if (item.id == 'residential') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => buildResidentialScreen(context)));
      } else {
        _notImplemented(context, item.label);
      }
    },
  );
}

// ---------------- Level 2: Residential — Buy / Rent / Sell ----------------
Widget buildResidentialScreen(BuildContext context) {
  return CategoryGridScreen(
    title: 'Residential',
    breadcrumbPath: const ['Properties', 'Residential'],
    items: MockData.residentialOptions,
    footerNote: 'Buy and Rent search verified listings. Sell lists your own property for AQARY to verify and publish.',
    onSelect: (item) {
      switch (item.id) {
        case 'buy':
          Navigator.push(context, MaterialPageRoute(builder: (_) => buildBuyScreen(context)));
          break;
        case 'rent':
          Navigator.push(context, MaterialPageRoute(builder: (_) => buildRentScreen(context)));
          break;
        case 'sell':
          _notImplemented(context, 'Sell (listing submission form)');
          break;
      }
    },
  );
}

// ---------------- Level 3a: Buy — Villa / Apartment / Land ----------------
Widget buildBuyScreen(BuildContext context) {
  return CategoryGridScreen(
    title: 'Buy',
    breadcrumbPath: const ['Properties', 'Residential', 'Buy'],
    items: MockData.buyPropertyTypes,
    onSelect: (item) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _buildBuyResults(item)),
    ),
  );
}

Widget _buildBuyResults(CategoryItem item) {
  final filters = item.id == 'land' ? const ['Price', 'Location'] : const ['Bedrooms', 'Price', 'Location'];
  return PropertyResultsScreen(
    title: '${item.label}s for Sale',
    breadcrumbPath: ['Properties', 'Residential', 'Buy', item.label],
    category: 'residential',
    listingType: 'sale',
    propertyType: item.id,
    filterLabels: filters,
    allowScheduling: true,
  );
}

// ---------------- Level 3b: Rent — Apartment / Villa ----------------
Widget buildRentScreen(BuildContext context) {
  return CategoryGridScreen(
    title: 'Rent',
    breadcrumbPath: const ['Properties', 'Residential', 'Rent'],
    items: MockData.rentPropertyTypes,
    onSelect: (item) => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyResultsScreen(
          title: '${item.label}s for Rent',
          breadcrumbPath: ['Properties', 'Residential', 'Rent', item.label],
          category: 'residential',
          listingType: 'rent',
          propertyType: item.id,
          filterLabels: const ['Bedrooms', 'Price', 'Location'],
        ),
      ),
    ),
  );
}

void _notImplemented(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label — follows the same CategoryGridScreen / PropertyResultsScreen pattern as Residential.')),
  );
}
