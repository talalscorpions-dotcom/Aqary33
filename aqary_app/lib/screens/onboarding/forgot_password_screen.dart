import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Password recovery, reached from [LoginScreen]'s "Forgot password?" link.
///
/// Deliberately shows the same "if an account exists…" confirmation whether
/// or not the email is registered — this avoids leaking which emails have
/// AQARY accounts (a common account-enumeration mistake).
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _sent = false;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: _sent ? _SentView(email: _email.text.trim(), onResend: _submit) : _formView(),
        ),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text('Forgot your password?', style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          const Text(
            "Enter the email on your account and we'll send a link to reset it.",
            style: TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mute, letterSpacing: 0.3)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: widget.initialEmail.isEmpty,
                  validator: _validateEmail,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Send Reset Link'),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Log In', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    // Always resolves to the same confirmation screen regardless of
    // whether the email is registered — see the class doc; that's the
    // backend's own behavior, not something faked client-side.
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _sent = true;
      });
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

class _SentView extends StatelessWidget {
  final String email;
  final VoidCallback onResend;
  const _SentView({required this.email, required this.onResend});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFF17706C), AppColors.tealDark]),
              boxShadow: [BoxShadow(color: AppColors.tealDark.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 22),
        Text('Check your email', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 21)),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.mute, height: 1.5),
            children: [
              const TextSpan(text: 'If an account exists for '),
              TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
              const TextSpan(text: ", we've sent a link to reset your password. It expires in 30 minutes."),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Log In'),
        ),
        const SizedBox(height: 14),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Didn't get it? ", style: TextStyle(fontSize: 12, color: AppColors.mute)),
              GestureDetector(
                onTap: onResend,
                child: const Text('Resend email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ResetPasswordScreen(initialEmail: email)),
            ),
            child: const Text(
              'I already have a reset code',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.tealDark),
            ),
          ),
        ),
      ],
    );
  }
}

/// Second half of the reset flow — the emailed link would normally deep-link
/// straight here with the token pre-filled; this app has no deep-link
/// handling set up yet, so the token is entered by hand. In dev, the
/// backend logs the reset link (with its token) to the server console
/// instead of actually emailing it — see auth.controller.js::forgotPassword.
class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  bool _submitting = false;
  bool _done = false;

  @override
  void dispose() {
    _token.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Reset Code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: _done ? _DoneView() : _form(),
        ),
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          Text('Set a new password', style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            widget.initialEmail.isEmpty
                ? 'Paste the reset token from the email and choose a new password.'
                : 'Paste the reset token sent to ${widget.initialEmail} and choose a new password.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.mute, height: 1.4),
          ),
          const SizedBox(height: 26),
          _field('RESET TOKEN', 'paste the token here', _token),
          _field('NEW PASSWORD', '••••••••', _newPassword, obscure: true),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController controller, {bool obscure = false}) {
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await AuthService.instance.resetPassword(
        token: _token.text.trim(),
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _done = true;
      });
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

class _DoneView extends StatelessWidget {
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
              gradient: LinearGradient(colors: [Color(0xFF17706C), AppColors.tealDark]),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 22),
        Text('Password updated', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 21)),
        const SizedBox(height: 10),
        const Text(
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.5),
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: () {
            // Reached via LoginScreen -> ForgotPasswordScreen -> here, so
            // two pops lands back on the login form.
            final nav = Navigator.of(context);
            nav.pop();
            nav.pop();
          },
          child: const Text('Back to Log In'),
        ),
      ],
    );
  }
}
