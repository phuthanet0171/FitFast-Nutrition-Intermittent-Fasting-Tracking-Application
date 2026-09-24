class HealthResult {
  const HealthResult({
    required this.bmi,
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.sodium,
    required this.recommendedPlan,
    required this.recommendationReason,
    required this.isFastingSuitable,
    required this.weightGoal,
    required this.usesTeenSafetyMode,
  });

  final double bmi;
  final double bmr;
  final double tdee;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double sodium;
  final String recommendedPlan;
  final String recommendationReason;
  final bool isFastingSuitable;
  final String weightGoal;
  final bool usesTeenSafetyMode;
}
