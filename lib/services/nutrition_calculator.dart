import '../models/nutrition_result.dart';
import '../models/user_profile.dart';

class NutritionCalculator {
  const NutritionCalculator._();

  static NutritionResult calculate(UserProfile profile) {
    final heightM = profile.heightCm / 100;
    final bmi = profile.currentWeightKg / (heightM * heightM);

    // Mifflin-St Jeor resting energy equation.
    final sexAdjustment = profile.gender == Gender.male ? 5.0 : -161.0;
    final bmr = (10 * profile.currentWeightKg) +
        (6.25 * profile.heightCm) -
        (5 * profile.age) +
        sexAdjustment;

    // Prototype activity multipliers. These are estimates, not measurements.
    final activityFactor = switch (profile.activityLevel) {
      ActivityLevel.sedentary => 1.20,
      ActivityLevel.light => 1.35,
      ActivityLevel.moderate => 1.50,
      ActivityLevel.veryActive => 1.70,
    };

    final maintenance = bmr * activityFactor;

    // Conservative MVP rule: infer goal direction from target weight.
    // Keep this easy to replace after validation with a nutrition expert/advisor.
    final difference = profile.targetWeightKg - profile.currentWeightKg;
    final estimatedCalories = difference < -0.5
        ? maintenance * 0.90
        : difference > 0.5
            ? maintenance * 1.05
            : maintenance;

    // Configurable prototype macro split: Protein 25%, Carbs 45%, Fat 30%.
    final proteinGrams = (estimatedCalories * 0.25) / 4;
    final carbsGrams = (estimatedCalories * 0.45) / 4;
    final fatGrams = (estimatedCalories * 0.30) / 9;

    // WHO: free sugars <10% of total energy; sodium <2,000 mg/day for adults.
    final freeSugarLimitGrams =
        ((estimatedCalories * 0.10) / 4).clamp(0, 24).toDouble();
    const sodiumLimitMg = 2000.0;

    return NutritionResult(
      bmi: bmi,
      bmr: bmr,
      estimatedCalories: estimatedCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      freeSugarLimitGrams: freeSugarLimitGrams,
      sodiumLimitMg: sodiumLimitMg,
    );
  }
}
