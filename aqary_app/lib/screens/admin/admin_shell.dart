import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../onboarding/welcome_screen.dart';
import 'admin_dashboard_screen.dart';
import 'leads_screen.dart';
import 'pending_approvals_screen.dart';

/// The admin panel's home after [AdminLoginScreen] — one Scaffold shared
/// across four tabs, so the bottom nav actually switches screens instead of
/// sitting there decoratively (each tab used to carry its own unused
/// NavigationBar).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _titles = ['Dashboard', 'Pending Approvals', 'Leads', 'Profile'];
  static const _bodies = <Widget>[
    AdminDashboardBody(),
    ApprovalsBody(),
    LeadsBody(),
    _AdminProfileBody(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_titles[_index]), automaticallyImplyLeading: false),
      body: SafeArea(child: _bodies[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Approvals'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Leads'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _AdminProfileBody extends StatelessWidget {
  const _AdminProfileBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.tealDark,
          child: Icon(Icons.admin_panel_settings_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 14),
        Text('AQARY Staff',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 19)),
        const SizedBox(height: 4),
        const Text('admin@aqary.om',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.mute)),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          ),
          icon: const Icon(Icons.logout_rounded,
              size: 17, color: AppColors.danger),
          label:
              const Text('Log Out', style: TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEAC2C2))),
        ),
      ],
    );
  }
}
