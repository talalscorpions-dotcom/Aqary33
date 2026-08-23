import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';

/// Reachable from any Buy result (Villa, Apartment, or Land) — it is an
/// action on a single listing, not a new branch of the taxonomy, per the
/// Properties Module Architecture doc. Maps to POST /properties/:id/viewings.
class ScheduleViewingScreen extends StatefulWidget {
  final Property property;
  const ScheduleViewingScreen({super.key, required this.property});

  @override
  State<ScheduleViewingScreen> createState() => _ScheduleViewingScreenState();
}

class _ScheduleViewingScreenState extends State<ScheduleViewingScreen> {
  int _selectedDay = 1;
  int _selectedSlot = 1;

  static const _days = [
    ('SUN', '9'), ('MON', '10'), ('TUE', '11'), ('WED', '12'), ('THU', '13'), ('FRI', '14'),
  ];
  static const _slots = ['9:00 AM', '10:30 AM', '12:00 PM', '2:00 PM', '3:30 PM', '5:00 PM'];

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule a Viewing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            const Breadcrumb(path: ['Properties', 'Residential', 'Buy', 'Schedule']),
            _PropertySummary(property: property),
            const SizedBox(height: 22),
            _SectionLabel(icon: Icons.calendar_month_rounded, label: 'Choose a Date'),
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final picked = i == _selectedDay;
                  final (dow, num) = _days[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = i),
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        color: picked ? AppColors.teal : AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: picked ? AppColors.teal : AppColors.line, width: 1.4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dow, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: picked ? Colors.white70 : AppColors.mute)),
                          const SizedBox(height: 3),
                          Text(num, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: picked ? Colors.white : AppColors.ink)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(icon: Icons.access_time_rounded, label: 'Choose a Time'),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _slots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              itemBuilder: (context, i) {
                final picked = i == _selectedSlot;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = i),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: picked ? AppColors.terra : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: picked ? AppColors.terra : AppColors.line, width: 1.4),
                    ),
                    child: Text(
                      _slots[i],
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: picked ? Colors.white : AppColors.ink),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.tealTint, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.how_to_reg_rounded, size: 16, color: AppColors.tealDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Hosted by a verified seller. You'll get a confirmation and a reminder before the visit.",
                      style: TextStyle(fontSize: 12, color: AppColors.tealDark, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _confirm(context),
              child: const Text('Confirm Viewing Request  →'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm(BuildContext context) {
    // POST /properties/:id/viewings in the real backend.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing request sent for ${_days[_selectedDay].$1} ${_days[_selectedDay].$2}, ${_slots[_selectedSlot]}'),
        backgroundColor: AppColors.tealDark,
      ),
    );
  }
}

class _PropertySummary extends StatelessWidget {
  final Property property;
  const _PropertySummary({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: property.imageGradient),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 3),
                Text(property.formattedPrice, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.terra)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.terra),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.terra, letterSpacing: 0.4),
        ),
      ],
    );
  }
}
