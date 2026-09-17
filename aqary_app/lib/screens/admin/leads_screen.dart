import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

/// The Leads tab body inside [AdminShell]. A lead is any buyer/renter
/// action that asks a seller, developer, or service provider to follow
/// up — a scheduled property viewing or a maintenance booking request.
/// Wired to GET /admin/leads, which unions `viewings` and
/// `service_bookings`. Status changes are made by the listing's own
/// owner (PATCH /viewings/:id) rather than admin, so this view is
/// read-only — it's the platform-wide activity feed, not a CRM.
class LeadsBody extends StatefulWidget {
  const LeadsBody({super.key});

  @override
  State<LeadsBody> createState() => _LeadsBodyState();
}

class _LeadsBodyState extends State<LeadsBody> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _leads = [];
  String? _statusFilter;

  static const _statusOptions = [null, 'pending', 'confirmed', 'completed', 'rejected', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final leads = await AdminService.instance.fetchLeads(status: _statusFilter, limit: 100);
      if (!mounted) return;
      setState(() {
        _leads = leads;
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
              Text('Could not load leads.\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.mute)),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final newCount = _leads.where((l) => l['status'] == 'pending').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        children: [
          Text('$newCount pending · ${_leads.length} total',
              style: const TextStyle(fontSize: 12, color: AppColors.mute)),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final status in _statusOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _StatusChip(
                      label: status == null ? 'All' : _statusLabel(status),
                      selected: status == _statusFilter,
                      onTap: () {
                        setState(() => _statusFilter = status);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_leads.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No leads yet.',
                    style: TextStyle(fontSize: 12, color: AppColors.mute)),
              ),
            )
          else
            for (final lead in _leads) _LeadCard(lead: lead),
        ],
      ),
    );
  }
}

String _statusLabel(String status) => status[0].toUpperCase() + status.substring(1);

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : AppColors.tealTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.teal)),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  const _LeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final status = lead['status']?.toString() ?? 'pending';
    final isNew = status == 'pending';
    final leadType = lead['lead_type']?.toString() == 'service_booking'
        ? 'SERVICE BOOKING'
        : 'VIEWING REQUEST';
    final name = lead['requester_name']?.toString() ?? 'Unknown';
    final subject = lead['subject_title']?.toString() ?? '';
    final phone = lead['requester_phone']?.toString();
    final email = lead['requester_email']?.toString();
    final createdAt = DateTime.tryParse(lead['created_at']?.toString() ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isNew ? AppColors.terra.withOpacity(0.4) : AppColors.line,
            width: isNew ? 1.4 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isNew
                      ? AppColors.terra.withOpacity(0.14)
                      : AppColors.tealTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(leadType,
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: isNew ? AppColors.terra : AppColors.teal,
                        letterSpacing: 0.4)),
              ),
              Text(createdAt == null ? '' : _timeAgo(createdAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.mute)),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(subject,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mute, height: 1.4)),
          const SizedBox(height: 6),
          if (phone != null && phone.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.call_outlined, size: 13, color: AppColors.mute),
                const SizedBox(width: 5),
                Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
              ],
            )
          else if (email != null && email.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 13, color: AppColors.mute),
                const SizedBox(width: 5),
                Text(email, style: const TextStyle(fontSize: 11, color: AppColors.mute)),
              ],
            ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_statusIcon(status), size: 15, color: _statusColor(status)),
                const SizedBox(width: 6),
                Text(_statusLabel(status),
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor(status))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.teal;
      case 'confirmed':
        return AppColors.tealDark;
      case 'rejected':
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.terra;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'confirmed':
        return Icons.event_available_rounded;
      case 'rejected':
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
