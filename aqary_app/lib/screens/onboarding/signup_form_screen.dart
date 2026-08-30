import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'role_choice_screen.dart';

/// What kind of seller account this is. Each maps to a different set of
/// required verification documents — see [SellerCategoryX.requiresAgentDocs].
enum SellerCategory {
  realEstateAgent,
  marketplaceRetail,
  maintenance,
  development
}

extension SellerCategoryX on SellerCategory {
  String get label {
    switch (this) {
      case SellerCategory.realEstateAgent:
        return 'Real Estate Agent';
      case SellerCategory.marketplaceRetail:
        return 'Marketplace — Retail Vendor';
      case SellerCategory.maintenance:
        return 'Maintenance Provider';
      case SellerCategory.development:
        return 'Development';
    }
  }

  /// Individual agents verify with a licence + personal ID. Every other
  /// seller category is a registered business, so it verifies with its
  /// Commercial Registration and Municipality Approval instead.
  bool get requiresAgentDocs => this == SellerCategory.realEstateAgent;
}

/// What a Marketplace / Retail Vendor sells. Only asked when
/// [SellerCategory.marketplaceRetail] is picked, so AQARY can route their
/// listings under the right retail department.
enum MarketplaceCategory {
  furniture,
  flooring,
  concrete,
  bath,
  gardening,
  pool,
  lighting,
  other
}

extension MarketplaceCategoryX on MarketplaceCategory {
  String get label {
    switch (this) {
      case MarketplaceCategory.furniture:
        return 'Furniture';
      case MarketplaceCategory.flooring:
        return 'Flooring';
      case MarketplaceCategory.concrete:
        return 'Concrete';
      case MarketplaceCategory.bath:
        return 'Bath';
      case MarketplaceCategory.gardening:
        return 'Gardening';
      case MarketplaceCategory.pool:
        return 'Pool';
      case MarketplaceCategory.lighting:
        return 'Lighting';
      case MarketplaceCategory.other:
        return 'Other';
    }
  }
}

/// What trade a Maintenance Provider works in. Only asked when
/// [SellerCategory.maintenance] is picked.
enum MaintenanceCategory {
  plumbing,
  ac,
  gas,
  kitchen,
  electrical,
  painting,
  cleaning,
  other
}

extension MaintenanceCategoryX on MaintenanceCategory {
  String get label {
    switch (this) {
      case MaintenanceCategory.plumbing:
        return 'Plumbing';
      case MaintenanceCategory.ac:
        return 'AC & Cooling';
      case MaintenanceCategory.gas:
        return 'Gas';
      case MaintenanceCategory.kitchen:
        return 'Kitchen';
      case MaintenanceCategory.electrical:
        return 'Electrical';
      case MaintenanceCategory.painting:
        return 'Painting';
      case MaintenanceCategory.cleaning:
        return 'Cleaning';
      case MaintenanceCategory.other:
        return 'Other';
    }
  }
}

/// What kind of development business this is. Only asked when
/// [SellerCategory.development] is picked.
enum DevelopmentCategory { developmentCompany, contractor, architecture, other }

extension DevelopmentCategoryX on DevelopmentCategory {
  String get label {
    switch (this) {
      case DevelopmentCategory.developmentCompany:
        return 'Development Company';
      case DevelopmentCategory.contractor:
        return 'Contractor';
      case DevelopmentCategory.architecture:
        return 'Architecture';
      case DevelopmentCategory.other:
        return 'Other';
    }
  }
}

/// Step 2 of sign-up. A Purchase account asks for phone, email, and
/// password. A Sell account picks its [SellerCategory] first — before
/// any contact fields — since that decides whether it verifies with an
/// Agent Licence + Photo ID or a Commercial Registration + Municipality
/// Approval, then routes to verification instead of activating
/// immediately, matching Section 3.1 of the Statement of Work.
class SignUpFormScreen extends StatefulWidget {
  final AccountRole role;
  const SignUpFormScreen({super.key, required this.role});

  @override
  State<SignUpFormScreen> createState() => _SignUpFormScreenState();
}

class _SignUpFormScreenState extends State<SignUpFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  SellerCategory? _sellerCategory;
  MarketplaceCategory? _marketplaceCategory;
  MaintenanceCategory? _maintenanceCategory;
  DevelopmentCategory? _developmentCategory;

  bool get _isSeller => widget.role == AccountRole.sell;

  @override
  void dispose() {
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            children: [
              Breadcrumb(path: [
                'Step 2 of 2',
                _isSeller
                    ? (_sellerCategory?.label ?? 'Seller account')
                    : 'Purchase account'
              ]),
              const SizedBox(height: 4),
              if (_isSeller) ...[
                Text('SELLER CATEGORY', style: AppTextStyles.kicker),
                const SizedBox(height: 10),
                DropdownButtonFormField<SellerCategory>(
                  value: _sellerCategory,
                  onChanged: (v) => setState(() {
                    _sellerCategory = v;
                    // A sub-category from a previous pick no longer applies
                    // once the seller category changes.
                    _marketplaceCategory = null;
                    _maintenanceCategory = null;
                    _developmentCategory = null;
                  }),
                  validator: (v) => v == null
                      ? 'Select what kind of seller account this is'
                      : null,
                  decoration: const InputDecoration(
                      hintText: 'What are you selling on AQARY?'),
                  items: SellerCategory.values
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.label)))
                      .toList(),
                ),
                if (_sellerCategory == SellerCategory.marketplaceRetail)
                  ..._subCategoryDropdown<MarketplaceCategory>(
                    label: 'MARKETPLACE CATEGORY',
                    hint: 'What do you sell?',
                    value: _marketplaceCategory,
                    items: MarketplaceCategory.values,
                    itemLabel: (c) => c.label,
                    onChanged: (v) => setState(() => _marketplaceCategory = v),
                  ),
                if (_sellerCategory == SellerCategory.maintenance)
                  ..._subCategoryDropdown<MaintenanceCategory>(
                    label: 'MAINTENANCE CATEGORY',
                    hint: 'What service do you provide?',
                    value: _maintenanceCategory,
                    items: MaintenanceCategory.values,
                    itemLabel: (c) => c.label,
                    onChanged: (v) => setState(() => _maintenanceCategory = v),
                  ),
                if (_sellerCategory == SellerCategory.development)
                  ..._subCategoryDropdown<DevelopmentCategory>(
                    label: 'DEVELOPMENT CATEGORY',
                    hint: 'What type of development business is this?',
                    value: _developmentCategory,
                    items: DevelopmentCategory.values,
                    itemLabel: (c) => c.label,
                    onChanged: (v) => setState(() => _developmentCategory = v),
                  ),
                const SizedBox(height: 20),
              ],
              _Field(
                  label: 'Phone Number',
                  hint: '+968 9xxx xxxx',
                  controller: _phone,
                  keyboardType: TextInputType.phone),
              _Field(
                  label: 'Username (Email Address)',
                  hint: 'you@example.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              _Field(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscure: true),
              _Field(
                  label: 'Re-enter Password',
                  hint: '••••••••',
                  controller: _confirm,
                  obscure: true),
              if (_isSeller) ...[
                const SizedBox(height: 8),
                Text('VERIFICATION — REQUIRED FOR SELLERS',
                    style: AppTextStyles.kicker),
                const SizedBox(height: 10),
                if (_sellerCategory == null)
                  const Text(
                    'Pick a category above to see the documents you need to upload.',
                    style: TextStyle(
                        fontSize: 11.5, color: AppColors.mute, height: 1.4),
                  )
                else if (_sellerCategory!.requiresAgentDocs) ...[
                  const _UploadBox(
                      icon: Icons.badge_rounded,
                      label:
                          'Upload Agent Licence — required if listing on behalf of others'),
                  const SizedBox(height: 10),
                  const _UploadBox(
                      icon: Icons.camera_alt_rounded,
                      label: 'Upload a Photo ID (Civil ID or Passport)'),
                ] else ...[
                  const _UploadBox(
                      icon: Icons.receipt_long_rounded,
                      label:
                          'Upload your Commercial Registration (CR) certificate'),
                  const SizedBox(height: 10),
                  const _UploadBox(
                      icon: Icons.verified_rounded,
                      label: 'Upload your Municipality Approval'),
                ],
              ],
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isSeller
                    ? 'Submit for Verification  →'
                    : 'Create Account  →'),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Already have an account? ',
                        style: TextStyle(fontSize: 12, color: AppColors.mute)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tealDark),
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

  /// A labelled dropdown for a seller sub-category (marketplace/maintenance/
  /// development), shared so each one stays a single required field with
  /// consistent spacing and a "select something" validator.
  List<Widget> _subCategoryDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return [
      const SizedBox(height: 16),
      Text(label, style: AppTextStyles.kicker),
      const SizedBox(height: 10),
      DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        validator: (v) => v == null ? 'Required' : null,
        decoration: InputDecoration(hintText: hint),
        items: items
            .map((c) => DropdownMenuItem(value: c, child: Text(itemLabel(c))))
            .toList(),
      ),
    ];
  }

  void _submit() {
    // POST /auth/sign-up in the real backend. Purchase accounts activate
    // immediately; Sell accounts enter the pending-verification queue
    // shown in the admin panel (see PendingApprovalsScreen).
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSeller
            ? 'Submitted for verification — you can browse while we review.'
            : 'Account created — welcome to AQARY.'),
        backgroundColor: AppColors.tealDark,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mute,
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final IconData icon;
  final String label;
  const _UploadBox({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1.4),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.terra),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.mute, height: 1.4)),
        ],
      ),
    );
  }
}
