import 'package:flutter/material.dart';

import '../models/fasting_settings.dart';
import '../models/health_result.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'fasting_timer_screen.dart';
import 'food_screen.dart';
import 'health_onboarding_screen.dart';
import 'if_interest_screen.dart';
import 'if_setup_method_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.fastingSettings,
    this.healthResult,
    this.age,
  });

  final FastingSettings? fastingSettings;
  final HealthResult? healthResult;
  final int? age;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  FastingSettings? _fastingSettings;

  @override
  void initState() {
    super.initState();
    _fastingSettings = widget.fastingSettings;
  }

  void _openIfSetup() {
    final healthResult = widget.healthResult;
    final age = widget.age;
    if (healthResult == null || age == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HealthOnboardingScreen()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IfInterestScreen(
          age: age,
          bmi: healthResult.bmi,
          healthResult: healthResult,
        ),
      ),
    );
  }

  void _openIfMethod() {
    final healthResult = widget.healthResult;
    final age = widget.age;
    if (healthResult == null || age == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HealthOnboardingScreen()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IfSetupMethodScreen(
          age: age,
          bmi: healthResult.bmi,
          healthResult: healthResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(healthResult: widget.healthResult),
      FastingTimerScreen(
        settings: _fastingSettings,
        onSetupRequested: _openIfSetup,
        onChangePlanRequested: _openIfMethod,
        onPlanCancelled: () {
          setState(() => _fastingSettings = null);
        },
        onSettingsChanged: (settings) {
          setState(() => _fastingSettings = settings);
        },
      ),
      const FoodScreen(),
      const _ComingSoonPage(
        icon: Icons.show_chart_rounded,
        title: 'ความก้าวหน้า',
        description: 'ติดตามน้ำหนัก เป้าหมาย และความสม่ำเสมอของคุณ',
      ),
      const _ComingSoonPage(
        icon: Icons.person_rounded,
        title: 'โปรไฟล์',
        description: 'จัดการข้อมูลสุขภาพ เป้าหมาย และการแจ้งเตือน',
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: AppColors.teal,
            selectedIndex: _index,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.tealDark),
                selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined, color: AppColors.tealDark),
                selectedIcon: Icon(Icons.timer_rounded, color: Colors.white),
                label: 'IF',
              ),
              NavigationDestination(
                icon: Icon(Icons.ramen_dining_outlined,
                    color: AppColors.tealDark),
                selectedIcon:
                    Icon(Icons.ramen_dining_rounded, color: Colors.white),
                label: 'Food',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined, color: AppColors.tealDark),
                selectedIcon:
                    Icon(Icons.bar_chart_rounded, color: Colors.white),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded,
                    color: AppColors.tealDark),
                selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 46, color: AppColors.tealDark),
                  ),
                  const SizedBox(height: 22),
                  Text('กำลังเตรียมหน้านี้',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 290,
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
