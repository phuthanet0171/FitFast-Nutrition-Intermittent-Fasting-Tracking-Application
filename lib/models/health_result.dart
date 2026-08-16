class HealthResult {
  const HealthResult({
    required this.bmi,
    required this.bmr,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.sodium,
    required this.recommendedPlan,
    required this.recommendationReason,
    required this.isFastingSuitable,
  });

  final double bmi;
  final double bmr;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double sodium;
  final String recommendedPlan;
  final String recommendationReason;
  final bool isFastingSuitable;
}
