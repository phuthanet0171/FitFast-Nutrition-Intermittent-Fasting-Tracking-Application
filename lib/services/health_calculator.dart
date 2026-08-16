import 'dart:math';

import '../models/health_result.dart';

class HealthCalculator {
  static HealthResult calculate({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activity,
    required String experience,
    required bool pregnantOrBreastfeeding,
    required bool hasDiabetesOrMedication,
    required bool hasEatingDisorderHistory,
  }) {
    final bmi = weight / pow(height / 100, 2);
    final genderValue = gender == 'male' ? 5 : -161;
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + genderValue;
    final activityFactor = switch (activity) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'high' => 1.725,
      _ => 1.2,
    };
    final calories = bmr * activityFactor;
    final hasSafetyRisk = age < 18 ||
        bmi < 18.5 ||
        pregnantOrBreastfeeding ||
        hasDiabetesOrMedication ||
        hasEatingDisorderHistory;

    late final String plan;
    late final String reason;
    if (hasSafetyRisk) {
      plan = 'ยังไม่แนะนำให้เริ่ม IF';
      reason = 'พบปัจจัยที่ควรปรึกษาแพทย์หรือนักกำหนดอาหารก่อนเริ่ม IF';
    } else if (experience == 'beginner') {
      plan = '16/8';
      reason =
          'เหมาะสำหรับผู้เริ่มต้น เพราะมีช่วงรับประทาน 8 ชั่วโมงและปรับตัวง่ายกว่า';
    } else if (experience == 'intermediate') {
      plan = '18/6';
      reason =
          'เหมาะกับผู้ที่ทำ 16/8 ได้สม่ำเสมอและต้องการเพิ่มช่วงอดอย่างค่อยเป็นค่อยไป';
    } else {
      plan = '20/4';
      reason = 'เป็นแผนเข้มข้นสำหรับผู้มีประสบการณ์ ควรหยุดเมื่อมีอาการผิดปกติ';
    }

    return HealthResult(
      bmi: bmi,
      bmr: bmr,
      calories: calories,
      protein: (calories * .25) / 4,
      carbs: (calories * .45) / 4,
      fat: (calories * .30) / 9,
      sugar: ((calories * .10) / 4).clamp(0, 24).toDouble(),
      sodium: 2000,
      recommendedPlan: plan,
      recommendationReason: reason,
      isFastingSuitable: !hasSafetyRisk,
    );
  }
}
