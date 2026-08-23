import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Maps to PATCH /properties/:id/verify. Every submission — listing,
/// vendor profile, or seller account — passes through a screen like this
/// before it can go live, per the core trust differentiator in the
/// AQARY pitch materials.
class ReviewListingScreen extends StatelessWidget {
  const ReviewListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Listing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            const Text('Submitted 2 hours ago · Talal Al Balushi', style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 16),
            _ListingPreview(),
            const SizedBox(height: 20),
            Text('SUBMITTED DOCUMENTS', style: AppTextStyles.kicker),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(child: _DocThumb(icon: Icons.description_rounded, label: 'Title Deed')),
                SizedBox(width: 9),
                Expanded(child: _DocThumb(icon: Icons.photo_library_rounded, label: 'Photos (5)')),
                SizedBox(width: 9),
                Expanded(child: _DocThumb(icon: Icons.badge_rounded, label: 'Owner ID')),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.tealTint, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: AppColors.tealDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Title deed name matches the submitting account. No duplicate listing found for this plot number.',
                      style: TextStyle(fontSize: 12, color: AppColors.tealDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _decide(context, approved: false),
                    icon: const Icon(Icons.cancel_rounded, size: 17, color: AppColors.danger),
                    label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEAC2C2))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _decide(context, approved: true),
                    icon: const Icon(Icons.check_circle_rounded, size: 17),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _decide(BuildContext context, {required bool approved}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approved ? 'Listing approved and published.' : 'Listing rejected.'),
        backgroundColor: approved ? AppColors.tealDark : AppColors.danger,
      ),
    );
    Navigator.pop(context);
  }
}

class _ListingPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.teal, AppColors.terra]),
            ),
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hourglass_bottom_rounded, size: 12, color: AppColors.terra),
                    SizedBox(width: 4),
                    Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.terra)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OMR 185,000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
                const SizedBox(height: 4),
                const Text('4BR Villa — Madinat Al Ilam, Muscat', style: TextStyle(fontSize: 12.5, color: AppColors.mute)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  children: const [
                    _MetaText(icon: Icons.straighten_rounded, label: '420 m²'),
                    _MetaText(icon: Icons.bed_rounded, label: '4 beds'),
                    _MetaText(icon: Icons.bathtub_rounded, label: '5 baths'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaText({required this.icon, required this.label});

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

class _DocThumb extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DocThumb({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE3D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.mute),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.mute)),
        ],
      ),
    );
  }
}
