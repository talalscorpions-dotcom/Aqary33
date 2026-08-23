import 'package:flutter/material.dart';
import '../models/property.dart';
import '../theme/app_theme.dart';

/// A single listing card — used on every results screen and on the
/// Home screen's "Featured near you" section, per the component reuse
/// table in the Properties Module Architecture doc.
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final VoidCallback? onScheduleViewing;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.onScheduleViewing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageHeader(property: property),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.formattedPrice,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tealDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.title,
                      style: const TextStyle(fontSize: 13, color: AppColors.mute),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if (property.areaSqm != null)
                          _MetaChip(icon: Icons.straighten_rounded, label: '${property.areaSqm!.toInt()} m²'),
                        if (property.bedrooms != null)
                          _MetaChip(icon: Icons.bed_rounded, label: '${property.bedrooms} beds'),
                        if (property.bathrooms != null)
                          _MetaChip(icon: Icons.bathtub_rounded, label: '${property.bathrooms} baths'),
                      ],
                    ),
                    if (onScheduleViewing != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onScheduleViewing,
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: const Text('Schedule a Viewing'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageHeader extends StatelessWidget {
  final Property property;
  const _ImageHeader({required this.property});

  @override
  Widget build(BuildContext context) {
    final verified = property.status == VerificationStatus.verified;
    return SizedBox(
      height: 150,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: property.imageGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    verified ? Icons.verified_rounded : Icons.hourglass_bottom_rounded,
                    size: 13,
                    color: verified ? AppColors.tealDark : AppColors.terra,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    verified ? 'Verified' : 'Pending',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: verified ? AppColors.tealDark : AppColors.terra,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: Colors.black.withOpacity(0.28),
              child: const Icon(Icons.favorite_border_rounded, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.mute),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.mute)),
      ],
    );
  }
}
