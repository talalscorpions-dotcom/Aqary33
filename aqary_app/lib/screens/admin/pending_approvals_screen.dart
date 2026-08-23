import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'review_listing_screen.dart';

class _ApprovalItem {
  final String type;
  final String name;
  final String detail;
  final String timeAgo;
  const _ApprovalItem(this.type, this.name, this.detail, this.timeAgo);
}

/// Maps to GET /admin/approvals?status=pending — the Trust & Verification
/// panel referenced in Section 3.7 of the Statement of Work.
class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({super.key});

  static const _items = [
    _ApprovalItem('LISTING', '4BR Villa — Madinat Al Ilam, Muscat', 'Submitted by Talal Al Balushi · Title deed attached', '2h ago'),
    _ApprovalItem('SELLER', 'Fatma Al Rawahi', 'Agent licence + ID uploaded · First submission', '5h ago'),
    _ApprovalItem('VENDOR', 'Al Rustaq Construction', 'Trade licence #OM-4471 · Contractor profile', '1d ago'),
    _ApprovalItem('LISTING', 'Industrial Plot — Sohar Free Zone', 'Submitted by Sohar Coast Developers', '1d ago'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          children: [
            const Text('14 items awaiting review', style: TextStyle(fontSize: 12, color: AppColors.mute)),
            const SizedBox(height: 16),
            for (final item in _items) _ApprovalCard(item: item),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Approvals'),
          NavigationDestination(icon: Icon(Icons.list_alt_rounded), label: 'All Listings'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final _ApprovalItem item;
  const _ApprovalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.tealTint, borderRadius: BorderRadius.circular(20)),
                child: Text(item.type, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.teal, letterSpacing: 0.4)),
              ),
              Text(item.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.mute)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(item.detail, style: const TextStyle(fontSize: 11, color: AppColors.mute, height: 1.4)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewListingScreen())),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
              child: const Text('Review  →', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
