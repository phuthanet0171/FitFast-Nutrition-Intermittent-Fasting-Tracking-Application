class NutritionResult {
  const NutritionResult({
    required this.bmi,
    required this.bmr,
    required this.estimatedCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.freeSugarLimitGrams,
    required this.sodiumLimitMg,
  });

  final double bmi;
  final double bmr;
  final double estimatedCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double freeSugarLimitGrams;
  final double sodiumLimitMg;
}
