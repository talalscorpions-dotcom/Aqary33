import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'role_choice_screen.dart';

/// Email + password sign-in against `POST /auth/log-in` in aqary_backend.
/// Previously "Log In" on [WelcomeScreen] skipped straight to [HomeScreen]
/// with no form at all — this is the real screen, with a path into
/// [ForgotPasswordScreen] for account recovery.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
            children: [
              Text('Welcome back', style: AppTextStyles.heading.copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              const Text(
                'Log in to pick up where you left off.',
                style: TextStyle(fontSize: 12.5, color: AppColors.mute),
              ),
              const SizedBox(height: 26),
              _Field(
                label: 'Email Address',
                hint: 'you@example.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              _Field(
                label: 'Password',
                hint: '••••••••',
                controller: _password,
                obscure: _obscure,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 20,
                    color: AppColors.mute,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim())),
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
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Log In  →'),
              ),
              const SizedBox(height: 18),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(fontSize: 12, color: AppColors.mute)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleChoiceScreen())),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.tealDark),
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

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.logIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Welcome back.'), backgroundColor: AppColors.tealDark),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Check your connection.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
  final Widget? suffix;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
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
            validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ],
      ),
    );
  }
}
