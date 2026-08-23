import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/property.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';
import '../../widgets/filter_row.dart';
import '../../widgets/property_card.dart';
import '../../widgets/view_toggle.dart';
import 'schedule_viewing_screen.dart';

/// The one reusable results screen behind every leaf of the taxonomy —
/// Villas for Sale, Apartments, Offices for Rent, Industrial Land, and
/// so on. It is parameterised by category/listingType/propertyType and
/// calls [MockData.filterListings], which stands in for
/// `GET /properties?category=...&listing_type=...&property_type=...`
/// from the architecture doc. Swapping the mock call for a real HTTP
/// call is the only change needed to go live — no screen gets rebuilt
/// per property type.
class PropertyResultsScreen extends StatefulWidget {
  final String title;
  final List<String> breadcrumbPath;
  final String category;
  final String? listingType;
  final String propertyType;

  /// Bedrooms/Price/Location for Villa & Apartment; Price/Location only
  /// for Land, per the filter rule in the architecture doc.
  final List<String> filterLabels;

  /// Whether this results screen should default to a "Region: All Oman"
  /// filter (Commercial/Industrial) instead of the Muscat-default chips.
  final bool nationwide;

  /// Whether cards in this results screen offer "Schedule a Viewing" —
  /// true for residential Buy results, false elsewhere.
  final bool allowScheduling;

  const PropertyResultsScreen({
    super.key,
    required this.title,
    required this.breadcrumbPath,
    required this.category,
    required this.propertyType,
    required this.filterLabels,
    this.listingType,
    this.nationwide = false,
    this.allowScheduling = false,
  });

  @override
  State<PropertyResultsScreen> createState() => _PropertyResultsScreenState();
}

class _PropertyResultsScreenState extends State<PropertyResultsScreen> {
  ResultsView _view = ResultsView.list;

  @override
  Widget build(BuildContext context) {
    final results = MockData.filterListings(
      category: widget.category,
      listingType: widget.listingType,
      propertyType: widget.propertyType,
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Breadcrumb(path: widget.breadcrumbPath),
              ViewToggle(value: _view, onChanged: (v) => setState(() => _view = v)),
              const SizedBox(height: 12),
              if (widget.nationwide) ...[
                const RegionFilterBar(label: 'Region: All Oman (Muscat, Dhofar, Al Batinah...)'),
                const SizedBox(height: 10),
              ],
              FilterRow(filters: widget.filterLabels),
              const SizedBox(height: 14),
              Expanded(
                child: _view == ResultsView.list
                    ? _ListView(results: results, allowScheduling: widget.allowScheduling)
                    : _MapPlaceholder(results: results),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Property> results;
  final bool allowScheduling;
  const _ListView({required this.results, required this.allowScheduling});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const _EmptyState();
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final property = results[i];
        return PropertyCard(
          property: property,
          onScheduleViewing: allowScheduling
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScheduleViewingScreen(property: property)),
                  )
              : null,
        );
      },
    );
  }
}

/// Map view is a visual placeholder in this frontend-only scaffold — wire
/// up google_maps_flutter or a Mapbox widget here once the backend can
/// supply GET /properties/:id/availability-style coordinates.
class _MapPlaceholder extends StatelessWidget {
  final List<Property> results;
  const _MapPlaceholder({required this.results});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Container(color: const Color(0xFFE7E9DE)),
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          for (var i = 0; i < results.length; i++)
            Positioned(
              left: 40.0 + (i * 70) % 200,
              top: 60.0 + (i * 95) % 260,
              child: _MapPin(label: results[i].formattedPrice, alt: i.isOdd),
            ),
          Positioned(
            right: 14,
            bottom: 14,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location_rounded, color: AppColors.teal, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  final bool alt;
  const _MapPin({required this.label, required this.alt});

  @override
  Widget build(BuildContext context) {
    final color = alt ? AppColors.terra : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFD5C4)
      ..strokeWidth = 2;
    for (double y = 0; y < size.height; y += 70) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.mute),
            const SizedBox(height: 12),
            Text(
              'No verified listings match these filters yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mute, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
