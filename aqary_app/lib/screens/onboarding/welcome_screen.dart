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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF17706C), AppColors.tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.tealDark.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 18),
              const Text('عقاري', style: TextStyle(fontSize: 17, color: AppColors.gold)),
              const SizedBox(height: 4),
              Text('Welcome to AQARY', textAlign: TextAlign.center, style: AppTextStyles.heading.copyWith(fontSize: 26)),
              const SizedBox(height: 12),
              const Text(
                'From land to living, in one platform — verified properties, vendors, and financing across Oman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.mute, height: 1.5),
              ),
              const SizedBox(height: 34),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleChoiceScreen())),
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
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
      ),
    );
  }
}
