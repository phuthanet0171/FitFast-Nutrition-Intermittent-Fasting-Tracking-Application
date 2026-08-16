enum Gender { male, female }

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  veryActive,
}

class UserProfile {
  const UserProfile({
    required this.age,
    required this.gender,
    required this.currentWeightKg,
    required this.heightCm,
    required this.targetWeightKg,
    required this.activityLevel,
  });

  final int age;
  final Gender gender;
  final double currentWeightKg;
  final double heightCm;
  final double targetWeightKg;
  final ActivityLevel activityLevel;
}
