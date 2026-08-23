import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/breadcrumb.dart';
import '../home/home_screen.dart';
import 'role_choice_screen.dart';

/// Step 2 of sign-up. A Purchase account asks for phone, email, and
/// password. A Sell account asks for the same fields plus an Agent
/// Licence and Photo ID upload, then routes to verification instead of
/// activating immediately — matching Section 3.1 of the Statement of Work.
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
              Breadcrumb(path: ['Step 2 of 2', _isSeller ? 'Seller / agent account' : 'Purchase account']),
              const SizedBox(height: 4),
              _Field(label: 'Phone Number', hint: '+968 9xxx xxxx', controller: _phone, keyboardType: TextInputType.phone),
              _Field(label: 'Username (Email Address)', hint: 'you@example.com', controller: _email, keyboardType: TextInputType.emailAddress),
              _Field(label: 'Password', hint: '••••••••', controller: _password, obscure: true),
              _Field(label: 'Re-enter Password', hint: '••••••••', controller: _confirm, obscure: true),
              if (_isSeller) ...[
                const SizedBox(height: 8),
                Text('VERIFICATION — REQUIRED FOR SELLERS', style: AppTextStyles.kicker),
                const SizedBox(height: 10),
                const _UploadBox(icon: Icons.badge_rounded, label: 'Upload Agent Licence — required if listing on behalf of others'),
                const SizedBox(height: 10),
                const _UploadBox(icon: Icons.camera_alt_rounded, label: 'Upload a Photo ID (Civil ID or Passport)'),
              ],
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _submit,
                child: Text(_isSeller ? 'Submit for Verification  →' : 'Create Account  →'),
              ),
              const SizedBox(height: 14),
              Center(
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(fontSize: 12, color: AppColors.mute),
                    children: [
                      TextSpan(text: 'Log In', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppColors.mute, height: 1.4)),
        ],
      ),
    );
  }
}
