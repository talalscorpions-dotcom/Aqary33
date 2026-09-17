import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';
import 'signup_form_screen.dart';

enum AccountRole { purchase, sell }

/// Every role AQARY supports, shown as one icon grid instead of a
/// purchase-or-sell choice that then hid four more options behind a text
/// dropdown. Picking a tile both answers "purchase or sell" and — for the
/// four business roles — the seller category in one tap, so
/// [SignUpFormScreen] never re-asks it.
enum RoleOption { buyer, realEstateAgent, marketplaceVendor, maintenanceProvider, development }

extension RoleOptionX on RoleOption {
  String get title {
    switch (this) {
      case RoleOption.buyer:
        return 'Buyer';
      case RoleOption.realEstateAgent:
        return 'Real Estate Agent';
      case RoleOption.marketplaceVendor:
        return 'Marketplace Vendor';
      case RoleOption.maintenanceProvider:
        return 'Maintenance Provider';
      case RoleOption.development:
        return 'Development';
    }
  }

  String get subtitle {
    switch (this) {
      case RoleOption.buyer:
        return "I'm searching for property to buy or rent";
      case RoleOption.realEstateAgent:
        return "I'm an owner or licensed agent listing property";
      case RoleOption.marketplaceVendor:
        return "I sell retail products — furniture, fittings, and more";
      case RoleOption.maintenanceProvider:
        return "I offer a maintenance service — plumbing, AC, and more";
      case RoleOption.development:
        return "I'm a development company, contractor, or architect";
    }
  }

  IconData get icon {
    switch (this) {
      case RoleOption.buyer:
        return Icons.volunteer_activism_rounded;
      case RoleOption.realEstateAgent:
        return Icons.sell_rounded;
      case RoleOption.marketplaceVendor:
        return Icons.storefront_rounded;
      case RoleOption.maintenanceProvider:
        return Icons.build_rounded;
      case RoleOption.development:
        return Icons.apartment_rounded;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case RoleOption.buyer:
        return const [Color(0xFF17706C), AppColors.tealDark];
      case RoleOption.realEstateAgent:
        return const [AppColors.gold, Color(0xFF9C6A2A)];
      case RoleOption.marketplaceVendor:
        return const [AppColors.terra, Color(0xFFB5673A)];
      case RoleOption.maintenanceProvider:
        return const [Color(0xFF3E8C82), AppColors.teal];
      case RoleOption.development:
        return const [Color(0xFF8A8A87), Color(0xFF4A4A47)];
    }
  }

  AccountRole get accountRole => this == RoleOption.buyer ? AccountRole.purchase : AccountRole.sell;

  SellerCategory? get sellerCategory {
    switch (this) {
      case RoleOption.buyer:
        return null;
      case RoleOption.realEstateAgent:
        return SellerCategory.realEstateAgent;
      case RoleOption.marketplaceVendor:
        return SellerCategory.marketplaceRetail;
      case RoleOption.maintenanceProvider:
        return SellerCategory.maintenance;
      case RoleOption.development:
        return SellerCategory.development;
    }
  }
}

/// Step 1 of sign-up — pick a role, tap to continue straight to
/// [SignUpFormScreen]. No separate "Continue" button: a role grid is
/// exactly the kind of choice where tapping the tile IS the decision.
class RoleChoiceScreen extends StatelessWidget {
  const RoleChoiceScreen({super.key});

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
                "What's your role on AQARY?",
                style: AppTextStyles.heading.copyWith(fontSize: 19),
              ),
              const SizedBox(height: 6),
              const Text('This decides what we ask for next.', style: TextStyle(fontSize: 12, color: AppColors.mute)),
              const SizedBox(height: 22),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                  children: [
                    for (final option in RoleOption.values)
                      _RoleTile(
                        option: option,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignUpFormScreen(
                              role: option.accountRole,
                              initialSellerCategory: option.sellerCategory,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final RoleOption option;
  final VoidCallback onTap;

  const _RoleTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: LinearGradient(colors: option.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Icon(option.icon, color: Colors.white, size: 13),
              ),
              const SizedBox(height: 9),
              Text(option.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(option.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.mute, height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}
