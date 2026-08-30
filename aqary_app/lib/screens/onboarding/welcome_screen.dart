import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'role_choice_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AspectRatio(
                        // Matches assets/branding/aqary_logo.jpg's native 900×601 crop.
                        aspectRatio: 900 / 601,
                        child: Image.asset(
                          'assets/branding/aqary_logo.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Welcome to AQARY',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading.copyWith(fontSize: 26)),
                    const SizedBox(height: 12),
                    const Text(
                      'From land to living, in one platform — verified properties, vendors, and financing across Oman.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.mute, height: 1.5),
                    ),
                    const SizedBox(height: 34),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RoleChoiceScreen())),
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen())),
                      child: const Text('Log In'),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "By continuing, you agree to AQARY's Terms of Service and Privacy Policy.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: AppColors.mute),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
