import 'package:fitfast/services/health_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthCalculator weight goals', () {
    dynamic calculate({
      required int age,
      required String goal,
      double? targetWeight,
    }) {
      return HealthCalculator.calculate(
        age: age,
        gender: 'male',
        height: 170,
        weight: 70,
        targetWeight: targetWeight ??
            (goal == 'lose'
                ? 60
                : goal == 'gain'
                    ? 80
                    : 70),
        activity: 'light',
        experience: 'beginner',
        pregnantOrBreastfeeding: false,
        hasDiabetesOrMedication: false,
        hasEatingDisorderHistory: false,
        weightGoal: goal,
      );
    }

    test('adult calorie targets follow lose maintain gain order', () {
      final lose = calculate(age: 25, goal: 'lose');
      final maintain = calculate(age: 25, goal: 'maintain');
      final gain = calculate(age: 25, goal: 'gain');

      expect(lose.calories, lessThan(maintain.calories));
      expect(maintain.calories, closeTo(maintain.tdee, .001));
      expect(gain.calories, greaterThan(maintain.calories));
    });

    test('teen uses maintenance calories and cannot receive IF plan', () {
      final result = calculate(age: 16, goal: 'lose');

      expect(result.weightGoal, 'maintain');
      expect(result.calories, closeTo(result.tdee, .001));
      expect(result.usesTeenSafetyMode, isTrue);
      expect(result.isFastingSuitable, isFalse);
    });

    test('daily sugar limit never exceeds 24 grams', () {
      final result = calculate(age: 25, goal: 'gain');
      expect(result.sugar, lessThanOrEqualTo(24));
    });

    test('farther adult weight goal adjusts calories more', () {
      final nearLoss = calculate(age: 25, goal: 'lose', targetWeight: 68);
      final farLoss = calculate(age: 25, goal: 'lose', targetWeight: 55);
      final nearGain = calculate(age: 25, goal: 'gain', targetWeight: 72);
      final farGain = calculate(age: 25, goal: 'gain', targetWeight: 85);

      expect(farLoss.calories, lessThan(nearLoss.calories));
      expect(farGain.calories, greaterThan(nearGain.calories));
    });
  });
}
