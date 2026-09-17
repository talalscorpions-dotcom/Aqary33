import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

/// The Dashboard tab body inside [AdminShell]: platform-wide stats, a
/// leads created-vs-closed trend, and the ten most-clicked listings.
/// Wired to GET /admin/analytics/overview, GET /admin/analytics/leads-timeseries,
/// and GET /admin/analytics/listing-clicks — all real data, no mocks.
class AdminDashboardBody extends StatefulWidget {
  const AdminDashboardBody({super.key});

  @override
  State<AdminDashboardBody> createState() => _AdminDashboardBodyState();
}

class _AdminDashboardBodyState extends State<AdminDashboardBody> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _timeseries = [];
  List<Map<String, dynamic>> _topListings = [];
  String _bucket = 'day';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        AdminService.instance.fetchOverview(),
        AdminService.instance.fetchLeadsTimeseries(bucket: _bucket, days: _daysFor(_bucket)),
        AdminService.instance.fetchTopListings(limit: 10),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as Map<String, dynamic>;
        _timeseries = results[1] as List<Map<String, dynamic>>;
        _topListings = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeBucket(String bucket) async {
    if (bucket == _bucket) return;
    setState(() => _bucket = bucket);
    try {
      final rows = await AdminService.instance.fetchLeadsTimeseries(
          bucket: bucket, days: _daysFor(bucket));
      if (!mounted) return;
      setState(() => _timeseries = rows);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load $bucket trend: $e')),
      );
    }
  }

  static int _daysFor(String bucket) {
    switch (bucket) {
      case 'week':
        return 90;
      case 'month':
        return 365;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 32),
              const SizedBox(height: 10),
              Text('Could not load dashboard data.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.mute)),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final o = _overview!;
    final usersByRole = (o['usersByRole'] as Map<String, dynamic>? ?? {});
    final totalUsers = usersByRole.values.fold<int>(0, (sum, v) => sum + (v as num).toInt());

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        children: [
          Text('PLATFORM OVERVIEW', style: AppTextStyles.kicker),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Total Users',
                  value: _formatCount(totalUsers),
                  sub: '+${o['newSignupsThisWeek']} this week',
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.login_rounded,
                  label: 'Logins Today',
                  value: _formatCount(o['loginsToday'] as int),
                  sub: '${o['activeUsers7d']} active in 7d',
                  color: AppColors.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.groups_rounded,
                  label: 'Leads (30d)',
                  value: _formatCount(o['leadsThisMonth'] as int),
                  sub: '${o['leadsToday']} today · ${o['leadsThisWeek']} this week',
                  color: AppColors.terra,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Leads Closed',
                  value: '${o['leadsClosed']}',
                  sub: '${o['leadsCloseRate']}% close rate',
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.ads_click_rounded,
                  label: 'Contact Clicks',
                  value: _formatCount(o['contactClicks30d'] as int),
                  sub: 'Last 30 days',
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.call_rounded,
                  label: 'Phone Reveals',
                  value: _formatCount(o['phoneReveals30d'] as int),
                  sub: 'Last 30 days',
                  color: AppColors.tealDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending Approvals',
            value: '${o['pendingApprovals']}',
            sub: '${o['totalProperties']} listings · ${o['verifiedProperties']} verified',
            color: AppColors.gold,
            wide: true,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEADS OVER TIME', style: AppTextStyles.kicker),
              _BucketToggle(selected: _bucket, onChanged: _changeBucket),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Created vs. closed, most recent first.',
              style: TextStyle(fontSize: 11.5, color: AppColors.mute)),
          const SizedBox(height: 14),
          _LeadsChart(rows: _timeseries, bucket: _bucket),
          const SizedBox(height: 24),
          Text('TOP 10 LISTINGS BY CLICKS', style: AppTextStyles.kicker),
          const SizedBox(height: 4),
          const Text('Ranked by contact/schedule/phone-reveal clicks.',
              style: TextStyle(fontSize: 11.5, color: AppColors.mute)),
          const SizedBox(height: 14),
          if (_topListings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No listings with clicks yet.',
                    style: TextStyle(fontSize: 12, color: AppColors.mute)),
              ),
            )
          else ...[
            () {
              final maxClicks = _topListings
                  .map((l) => (l['click_count'] as num?)?.toInt() ?? 0)
                  .fold<int>(1, (a, b) => b > a ? b : a);
              return Column(
                children: [
                  for (var i = 0; i < _topListings.length; i++)
                    _RankedRow(rank: i + 1, listing: _topListings[i], maxClicks: maxClicks),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }
}

String _formatCount(int n) {
  final s = n.toString();
  return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _BucketToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _BucketToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = ['day', 'week', 'month'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.tealTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opt in options)
            GestureDetector(
              onTap: () => onChanged(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: opt == selected ? AppColors.teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  opt[0].toUpperCase() + opt.substring(1),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: opt == selected ? Colors.white : AppColors.teal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadsChart extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String bucket;
  const _LeadsChart({required this.rows, required this.bucket});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: const Text('No leads in this period yet.',
            style: TextStyle(fontSize: 12, color: AppColors.mute)),
      );
    }

    final maxCreated = rows
        .map((r) => (r['created'] as num?)?.toInt() ?? 0)
        .fold<int>(1, (a, b) => b > a ? b : a);
    final recent = rows.length > 12 ? rows.sublist(rows.length - 12) : rows;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _legendDot(AppColors.teal, 'Created'),
              const SizedBox(width: 14),
              _legendDot(AppColors.gold, 'Closed'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final row in recent)
                  Expanded(
                    child: _ChartBar(
                      created: (row['created'] as num?)?.toInt() ?? 0,
                      closed: (row['closed'] as num?)?.toInt() ?? 0,
                      maxValue: maxCreated,
                      label: _formatBucketLabel(row['bucket']?.toString(), bucket),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.mute)),
      ],
    );
  }

  static String _formatBucketLabel(String? isoValue, String bucket) {
    if (isoValue == null) return '';
    final date = DateTime.tryParse(isoValue);
    if (date == null) return '';
    switch (bucket) {
      case 'month':
        const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
        return months[date.month - 1];
      case 'week':
        return '${date.day}/${date.month}';
      default:
        return '${date.day}';
    }
  }
}

class _ChartBar extends StatelessWidget {
  final int created;
  final int closed;
  final int maxValue;
  final String label;
  const _ChartBar({
    required this.created,
    required this.closed,
    required this.maxValue,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final createdHeight = maxValue == 0 ? 0.0 : (created / maxValue) * 72;
    final closedHeight = maxValue == 0 ? 0.0 : (closed / maxValue) * 72;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 6,
                height: createdHeight.clamp(2, 72),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 6,
                height: closedHeight.clamp(2, 72),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 8.5, color: AppColors.mute)),
        ],
      ),
    );
  }
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
              style: const TextStyle(fontSize: 10, color: AppColors.mute),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> listing;
  final int maxClicks;
  const _RankedRow(
      {required this.rank, required this.listing, required this.maxClicks});

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    final title = listing['title']?.toString() ?? 'Untitled listing';
    final clicks = (listing['click_count'] as num?)?.toInt() ?? 0;
    final views = (listing['view_count'] as num?)?.toInt() ?? 0;
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 3),
                Text('$views views',
                    style: const TextStyle(fontSize: 10, color: AppColors.mute)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: maxClicks == 0 ? 0 : clicks / maxClicks,
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
          Text(_formatCount(clicks),
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.tealDark)),
        ],
      ),
    );
  }
}
