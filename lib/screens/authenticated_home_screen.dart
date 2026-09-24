import 'package:flutter/material.dart';

import '../models/health_profile.dart';
import '../services/cloud_profile_service.dart';
import '../services/fasting_settings_service.dart';
import '../services/health_calculator.dart';
import '../services/health_profile_service.dart';
import 'health_onboarding_screen.dart';
import 'main_shell.dart';

class AuthenticatedHomeScreen extends StatefulWidget {
  const AuthenticatedHomeScreen({super.key});
  @override
  State<AuthenticatedHomeScreen> createState() =>
      _AuthenticatedHomeScreenState();
}

class _AuthenticatedHomeScreenState extends State<AuthenticatedHomeScreen> {
  late final Future<HealthProfile?> _profile = _prepareProfile();

  Future<HealthProfile?> _prepareProfile() async {
    await CloudProfileService.instance.syncUsernameFromMetadata();
    return HealthProfileService.instance.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<HealthProfile?>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final profile = snapshot.data;
          if (profile == null) return const HealthOnboardingScreen();
          return FutureBuilder(
            future: FastingSettingsService.instance.load(),
            builder: (context, fastingSnapshot) {
              if (fastingSnapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              final result = HealthCalculator.calculate(
                age: profile.age,
                gender: profile.gender,
                height: profile.height,
                weight: profile.currentWeight,
                targetWeight: profile.targetWeight,
                activity: profile.activity,
                experience: 'beginner',
                pregnantOrBreastfeeding: false,
                hasDiabetesOrMedication: false,
                hasEatingDisorderHistory: false,
                weightGoal: profile.weightGoal,
              );
              return MainShell(
                healthResult: result,
                age: profile.age,
                fastingSettings: fastingSnapshot.data,
              );
            },
          );
        },
      );
}
