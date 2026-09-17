import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_login_screen.dart';
import '../properties/create_listing_screen.dart';
import '../properties/properties_flow.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                        colors: [Color(0xFF17706C), AppColors.tealDark]),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text('AQARY',
                    style: AppTextStyles.heading.copyWith(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Good morning, Talal',
                      style: AppTextStyles.heading.copyWith(fontSize: 21)),
                ),
                const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.terra,
                    child: Text('T',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800))),
              ],
            ),
            const Text('Muscat, Al Khuwair',
                style: TextStyle(fontSize: 12, color: AppColors.mute)),
            if (user != null && user.role != 'buyer') ...[
              const SizedBox(height: 14),
              _RoleBanner(user: user),
            ],
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search land, villas, contractors...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionDot(label: 'AVAILABLE NOW', color: AppColors.teal),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                _ModuleTile(
                  icon: Icons.home_rounded,
                  label: 'Properties',
                  gradient: const [Color(0xFF17706C), AppColors.tealDark],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => buildPropertiesTopScreen(context))),
                ),
                _ModuleTile(
                  icon: Icons.apartment_rounded,
                  label: 'Development & Building',
                  gradient: const [Color(0xFFDE9865), Color(0xFFB5673A)],
                  onTap: () =>
                      _comingSoonToast(context, 'Development & Building'),
                ),
                _ModuleTile(
                  icon: Icons.storefront_rounded,
                  label: 'Market Place',
                  gradient: const [Color(0xFFB5673A), Color(0xFF9C6A2A)],
                  onTap: () => _comingSoonToast(context, 'Market Place'),
                ),
                _ModuleTile(
                  icon: Icons.calculate_rounded,
                  label: 'Loan Calculator',
                  gradient: const [AppColors.gold, Color(0xFF9C6A2A)],
                  onTap: () => _comingSoonToast(context, 'Loan Calculator'),
                ),
                _ModuleTile(
                  icon: Icons.build_rounded,
                  label: 'Maintenance Service',
                  gradient: const [Color(0xFF17706C), AppColors.tealDark],
                  onTap: () => _comingSoonToast(context, 'Maintenance Service'),
                ),
                _ModuleTile(
                  icon: Icons.verified_user_rounded,
                  label: 'Admin Panel',
                  gradient: const [Color(0xFF3E8C82), AppColors.teal],
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminLoginScreen())),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionDot(label: 'COMING SOON', color: AppColors.mute),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: const [
                _ModuleTile(
                    icon: Icons.sync_alt_rounded,
                    label: 'Loan',
                    gradient: [Color(0xFF9E9E9B), Color(0xFF6B6B68)],
                    soon: true),
                _ModuleTile(
                    icon: Icons.account_balance_rounded,
                    label: 'E-Gov',
                    gradient: [Color(0xFF9E9E9B), Color(0xFF6B6B68)],
                    soon: true),
                _ModuleTile(
                    icon: Icons.smart_toy_rounded,
                    label: 'AI Assistant',
                    gradient: [Color(0xFF9E9E9B), Color(0xFF6B6B68)],
                    soon: true),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined), label: 'Explore'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined), label: 'My Build'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Inbox'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  static void _comingSoonToast(BuildContext context, String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '$module — build this screen next, following the Properties pattern.')),
    );
  }
}

/// Everything below is identical for every signed-in role except this
/// banner — the rest of HomeScreen (module grid, nav bar) doesn't yet
/// branch by role at all. A seller/professional account still browses
/// the same "buyer" home; this is the one place role starts to matter.
class _RoleBanner extends StatelessWidget {
  final AppUser user;
  const _RoleBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    final pending = user.verificationStatus == 'pending';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tealTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pending ? Icons.hourglass_top_rounded : Icons.storefront_rounded,
                size: 16,
                color: AppColors.tealDark,
              ),
              const SizedBox(width: 8),
              Text(
                user.role == 'professional' ? 'Professional account' : 'Seller account',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.tealDark),
              ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 6),
            const Text(
              'Pending verification — you can browse while we review your documents.',
              style: TextStyle(fontSize: 12, color: AppColors.mute, height: 1.4),
            ),
          ],
          if (user.role == 'seller') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateListingScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Listing'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionDot extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color == AppColors.mute ? AppColors.mute : AppColors.ink,
                letterSpacing: 0.4)),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final bool soon;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
    this.soon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: soon ? 0.55 : 1,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: soon ? AppColors.mute : AppColors.ink),
              ),
              if (soon) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.tealDark,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('SOON',
                      style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
