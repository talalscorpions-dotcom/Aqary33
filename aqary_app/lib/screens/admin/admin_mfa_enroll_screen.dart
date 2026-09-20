import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// First-time MFA setup for an admin account created via the backend's
/// `npm run create-admin` script. Two steps, matching the two-endpoint
/// backend flow: enroll (email+password -> a secret) then confirm (a
/// 6-digit code from an authenticator app -> MFA turns on). There's no
/// QR renderer here, so the secret is shown as selectable text — paste
/// it into an authenticator app's "enter a setup key manually" option.
class AdminMfaEnrollScreen extends StatefulWidget {
  const AdminMfaEnrollScreen({super.key});

  @override
  State<AdminMfaEnrollScreen> createState() => _AdminMfaEnrollScreenState();
}

class _AdminMfaEnrollScreenState extends State<AdminMfaEnrollScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  bool _submitting = false;
  String? _secret;
  String? _otpauthUrl;
  bool _confirmed = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Admin MFA')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: _confirmed
              ? _ConfirmedView(onDone: () => Navigator.pop(context))
              : (_secret == null ? _step1() : _step2()),
        ),
      ),
    );
  }

  Widget _step1() {
    return Form(
      key: _step1Key,
      child: ListView(
        children: [
          Text('Step 1 of 2', style: AppTextStyles.kicker),
          const SizedBox(height: 6),
          Text('Confirm your account', style: AppTextStyles.heading.copyWith(fontSize: 21)),
          const SizedBox(height: 6),
          const Text(
            'Only works once, before MFA is already enabled — for an admin '
            'account created with `npm run create-admin`.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
          ),
          const SizedBox(height: 24),
          _field('ADMIN EMAIL', 'admin@aqary.om', _emailController, keyboardType: TextInputType.emailAddress),
          _field(
            'PASSWORD',
            '••••••••',
            _passwordController,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 19,
                color: AppColors.mute,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _submitting ? null : _submitStep1,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Continue  →'),
          ),
        ],
      ),
    );
  }

  Widget _step2() {
    return Form(
      key: _step2Key,
      child: ListView(
        children: [
          Text('Step 2 of 2', style: AppTextStyles.kicker),
          const SizedBox(height: 6),
          Text('Add to your authenticator app', style: AppTextStyles.heading.copyWith(fontSize: 21)),
          const SizedBox(height: 6),
          const Text(
            "Open your authenticator app (Google Authenticator, 1Password, etc.), "
            'choose "enter a setup key manually," and paste this secret in:',
            style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
          ),
          const SizedBox(height: 14),
          _copyableBox('Secret', _secret!),
          const SizedBox(height: 10),
          _copyableBox('otpauth URL', _otpauthUrl!),
          const SizedBox(height: 22),
          const Text('THEN ENTER THE 6-DIGIT CODE IT SHOWS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) => (v == null || v.trim().length != 6) ? 'Enter the 6-digit code' : null,
            decoration: const InputDecoration(hintText: '123456'),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: _submitting ? null : _submitStep2,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Confirm & Enable MFA'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller,
      {bool obscure = false, TextInputType? keyboardType, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
          ),
        ],
      ),
    );
  }

  Widget _copyableBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.line)),
          child: SelectableText(value, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        ),
      ],
    );
  }

  void _submitStep1() async {
    if (!(_step1Key.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final result = await AuthService.instance.adminMfaEnroll(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _secret = result.secret;
        _otpauthUrl = result.otpauthUrl;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection.'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _submitStep2() async {
    if (!(_step2Key.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.adminMfaConfirm(
        email: _emailController.text.trim(),
        mfaCode: _codeController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _confirmed = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection.'), backgroundColor: AppColors.danger),
      );
    }
  }
}

class _ConfirmedView extends StatelessWidget {
  final VoidCallback onDone;
  const _ConfirmedView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.tealDark, Color(0xFF0A2422)]),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 22),
        Text('MFA enabled', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 21)),
        const SizedBox(height: 10),
        const Text(
          'You can now sign in with your email, password, and a fresh code from your authenticator app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.5),
        ),
        const SizedBox(height: 28),
        OutlinedButton(onPressed: onDone, child: const Text('Back to Admin Log In')),
      ],
    );
  }
}
