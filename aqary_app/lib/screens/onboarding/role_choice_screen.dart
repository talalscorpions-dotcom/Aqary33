import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';
import 'signup_form_screen.dart';

enum AccountRole { purchase, sell }

/// "Are you using AQARY to purchase or sell?" — Step 1 of 2 in sign-up.
/// The answer decides whether [SignUpFormScreen] also asks for an Agent
/// Licence and Photo ID, per the Statement of Work's onboarding scope.
class RoleChoiceScreen extends StatefulWidget {
  const RoleChoiceScreen({super.key});

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  AccountRole _role = AccountRole.purchase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Breadcrumb(path: ['Step 1 of 2']),
              Text(
                'Are you using AQARY to purchase or sell?',
                style: AppTextStyles.heading.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 6),
              const Text('This decides what we ask for next.', style: TextStyle(fontSize: 12, color: AppColors.mute)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.volunteer_activism_rounded,
                      title: 'Purchase',
                      subtitle: "I'm searching for property to buy or rent",
                      gradient: const [Color(0xFF17706C), AppColors.tealDark],
                      selected: _role == AccountRole.purchase,
                      onTap: () => setState(() => _role = AccountRole.purchase),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.sell_rounded,
                      title: 'Sell',
                      subtitle: "I'm an owner or licensed agent listing property",
                      gradient: const [AppColors.gold, Color(0xFF9C6A2A)],
                      selected: _role == AccountRole.sell,
                      onTap: () => setState(() => _role = AccountRole.sell),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignUpFormScreen(role: _role)),
                ),
                child: const Text('Continue  →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.tealTint : AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.teal : AppColors.line, width: selected ? 2 : 1.2),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: AppColors.mute, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
