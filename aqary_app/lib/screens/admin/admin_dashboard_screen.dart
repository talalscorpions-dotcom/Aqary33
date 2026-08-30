import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class _RankedListing {
  final String title;
  final String location;
  final int clicks;
  const _RankedListing(this.title, this.location, this.clicks);
}

/// The Dashboard tab body inside [AdminShell]: platform-wide stats plus the
/// ten most-viewed listings. Maps to GET /admin/stats/overview and
/// GET /admin/stats/top-listings?limit=10 — click counts come from the same
/// view-tracking event each listing card already fires on open.
class AdminDashboardBody extends StatelessWidget {
  const AdminDashboardBody({super.key});

  static const _topListings = [
    _RankedListing('4BR Villa — Madinat Al Ilam, Muscat', 'Muscat', 1284),
    _RankedListing('Industrial Plot — Sohar Free Zone', 'Sohar', 998),
    _RankedListing('3BR Apartment — Al Khuwair, Muscat', 'Muscat', 861),
    _RankedListing('Al Rustaq Construction — Contractor', 'Al Rustaq', 742),
    _RankedListing('Beachfront Land — Salalah Corniche', 'Salalah', 705),
    _RankedListing('2BR Apartment — Ruwi, Muscat', 'Muscat', 611),
    _RankedListing('Commercial Shop — Nizwa Souq', 'Nizwa', 548),
    _RankedListing('Farmhouse — Sur Coastal Road', 'Sur', 493),
    _RankedListing('Muscat Home Interiors — Furniture', 'Muscat', 447),
    _RankedListing('5BR Villa — Qurum Heights', 'Muscat', 402),
  ];

  int get _totalClicks =>
      _topListings.fold(0, (sum, l) => sum + l.clicks) + 6284;

  @override
  Widget build(BuildContext context) {
    final maxClicks = _topListings.first.clicks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.ads_click_rounded,
                label: 'Total Ad Clicks',
                value: _formatCount(_totalClicks),
                sub: 'Last 30 days',
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.groups_rounded,
                label: 'New Leads',
                value: '5',
                sub: '2 unread',
                color: AppColors.terra,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.pending_actions_rounded,
          label: 'Pending Approvals',
          value: '14',
          sub: 'Listings, sellers & vendors awaiting review',
          color: AppColors.gold,
          wide: true,
        ),
        const SizedBox(height: 24),
        Text('TOP 10 LISTINGS BY CLICKS', style: AppTextStyles.kicker),
        const SizedBox(height: 4),
        const Text('Ranked by page views in the last 30 days.',
            style: TextStyle(fontSize: 11.5, color: AppColors.mute)),
        const SizedBox(height: 14),
        for (var i = 0; i < _topListings.length; i++)
          _RankedRow(
              rank: i + 1, listing: _topListings[i], maxClicks: maxClicks),
      ],
    );
  }
}

String _formatCount(int n) {
  final s = n.toString();
  return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final bool wide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 16, color: color),
              ),
              if (wide) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mute)),
                ),
                Text(value,
                    style: AppTextStyles.heading.copyWith(fontSize: 20)),
              ],
            ],
          ),
          if (!wide) ...[
            const SizedBox(height: 10),
            Text(value, style: AppTextStyles.heading.copyWith(fontSize: 22)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mute)),
          ],
          const SizedBox(height: 3),
          Text(sub,
              style: const TextStyle(fontSize: 10, color: AppColors.mute)),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final int rank;
  final _RankedListing listing;
  final int maxClicks;
  const _RankedRow(
      {required this.rank, required this.listing, required this.maxClicks});

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTopThree ? AppColors.gold : AppColors.tealTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isTopThree ? Colors.white : AppColors.teal,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: listing.clicks / maxClicks,
                    minHeight: 5,
                    backgroundColor: AppColors.line,
                    valueColor: AlwaysStoppedAnimation(
                        isTopThree ? AppColors.gold : AppColors.teal),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(_formatCount(listing.clicks),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tealDark)),
        ],
      ),
    );
  }
}
