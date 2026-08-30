import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum LeadStatus { newLead, contacted }

class _Lead {
  final String type;
  final String name;
  final String property;
  final String contact;
  final String timeAgo;
  LeadStatus status;
  _Lead({
    required this.type,
    required this.name,
    required this.property,
    required this.contact,
    required this.timeAgo,
    this.status = LeadStatus.newLead,
  });
}

/// The Leads tab body inside [AdminShell]. A lead is any buyer action that
/// asks a seller/agent to follow up — a scheduled viewing (see
/// ScheduleViewingScreen → POST /properties/:id/viewings), a contact
/// enquiry, or financing interest. Maps to GET /admin/leads.
class LeadsBody extends StatefulWidget {
  const LeadsBody({super.key});

  @override
  State<LeadsBody> createState() => _LeadsBodyState();
}

class _LeadsBodyState extends State<LeadsBody> {
  final _leads = [
    _Lead(
        type: 'VIEWING REQUEST',
        name: 'Said Al Harthy',
        property: '4BR Villa — Madinat Al Ilam, Muscat',
        contact: '+968 9123 4567',
        timeAgo: '18m ago'),
    _Lead(
        type: 'CONTACT ENQUIRY',
        name: 'Mariam Al Balushi',
        property: 'Al Rustaq Construction — Contractor',
        contact: 'mariam.b@example.com',
        timeAgo: '1h ago'),
    _Lead(
        type: 'FINANCING INTEREST',
        name: 'Yousuf Al Kindi',
        property: 'Industrial Plot — Sohar Free Zone',
        contact: '+968 9876 5432',
        timeAgo: '3h ago'),
    _Lead(
        type: 'VIEWING REQUEST',
        name: 'Aisha Al Farsi',
        property: '3BR Apartment — Al Khuwair, Muscat',
        contact: '+968 9012 3456',
        timeAgo: '6h ago',
        status: LeadStatus.contacted),
    _Lead(
        type: 'CONTACT ENQUIRY',
        name: 'Khalid Al Balushi',
        property: 'Furniture Vendor — Muscat Home Interiors',
        contact: 'khalid.b@example.com',
        timeAgo: '1d ago',
        status: LeadStatus.contacted),
  ];

  @override
  Widget build(BuildContext context) {
    final newCount = _leads.where((l) => l.status == LeadStatus.newLead).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      children: [
        Text('$newCount new · ${_leads.length} total',
            style: const TextStyle(fontSize: 12, color: AppColors.mute)),
        const SizedBox(height: 16),
        for (final lead in _leads)
          _LeadCard(
            lead: lead,
            onMarkContacted: () =>
                setState(() => lead.status = LeadStatus.contacted),
          ),
      ],
    );
  }
}

class _LeadCard extends StatelessWidget {
  final _Lead lead;
  final VoidCallback onMarkContacted;
  const _LeadCard({required this.lead, required this.onMarkContacted});

  @override
  Widget build(BuildContext context) {
    final isNew = lead.status == LeadStatus.newLead;
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
                child: Text(lead.type,
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: isNew ? AppColors.terra : AppColors.teal,
                        letterSpacing: 0.4)),
              ),
              Text(lead.timeAgo,
                  style: const TextStyle(fontSize: 10, color: AppColors.mute)),
            ],
          ),
          const SizedBox(height: 8),
          Text(lead.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 3),
          Text(lead.property,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.mute, height: 1.4)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.call_outlined, size: 13, color: AppColors.mute),
              const SizedBox(width: 5),
              Text(lead.contact,
                  style: const TextStyle(fontSize: 11, color: AppColors.mute)),
            ],
          ),
          const SizedBox(height: 10),
          if (isNew)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onMarkContacted,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)),
                child: const Text('Mark as Contacted',
                    style: TextStyle(fontSize: 12)),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tealTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 15, color: AppColors.teal),
                  SizedBox(width: 6),
                  Text('Contacted',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
