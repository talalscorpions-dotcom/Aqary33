import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../onboarding/forgot_password_screen.dart';
import 'admin_mfa_enroll_screen.dart';
import 'admin_shell.dart';

/// Gate in front of the whole admin panel (Dashboard, Approvals, Leads).
/// Previously the "Trust & Verification" tile on [HomeScreen] opened
/// [PendingApprovalsScreen] directly with no authentication at all — this
/// screen is that missing gate. Maps to POST /admin/auth/login in the real
/// backend; staff accounts are provisioned separately from buyer/seller
/// sign-up, so there's no "Create account" link here.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _mfaCode = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _mfaCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.tealDark, Color(0xFF0A2422)]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.tealDark.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 18),
              Text('AQARY Admin',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(fontSize: 22)),
              const SizedBox(height: 8),
              const Text(
                'Staff sign-in to review listings, respond to leads, and see platform activity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.mute, height: 1.4),
              ),
              const SizedBox(height: 28),
              _Field(
                label: 'Admin Email',
                hint: 'admin@aqary.om',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _Field(
                label: 'Password',
                hint: '••••••••',
                controller: _password,
                obscure: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim())),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.tealDark),
                    ),
                  ),
                ),
              ),
              _Field(
                label: 'Authenticator Code',
                hint: '6-digit code',
                controller: _mfaCode,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDark),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Sign In  →'),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Staff accounts only. Buyers and sellers use the regular Log In.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.mute),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminMfaEnrollScreen()),
                  ),
                  child: const Text(
                    'First time signing in? Set up MFA',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.tealDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.adminLogIn(
        email: _email.text.trim(),
        password: _password.text,
        mfaCode: _mfaCode.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Check your connection.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

String? _validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Required';
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  return ok ? null : 'Enter a valid email address';
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
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
            validator: validator ??
                (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
