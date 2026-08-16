import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'health_onboarding_screen.dart';
import 'main_shell.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _openApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  void _startRegistration(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HealthOnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'FitFast',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: AppColors.navy,
                    ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _startRegistration(context),
                child: const Text('สมัครสมาชิก'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _openApp(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: AppColors.tealDark,
                  side: const BorderSide(color: AppColors.teal, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('เข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
