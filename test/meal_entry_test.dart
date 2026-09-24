import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/meal_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editing a meal preserves id and recalculates nutrients', () {
    const food = FoodItem(
      id: 1,
      foodCode: 'T1',
      nameTh: 'อาหารทดสอบ',
      nameEn: null,
      energyKcalPer100g: 100,
      proteinGPer100g: 10,
      carbsGPer100g: 20,
      fatGPer100g: 5,
      sugarGPer100g: null,
      sodiumMgPer100g: 200,
    );
    final original = MealEntry.fromFood(
      food: food,
      mealType: MealType.breakfast,
      grams: 100,
      dateKey: '2026-09-09',
    );
    final edited = MealEntry.fromFood(
      food: original.toFoodItem(),
      mealType: MealType.lunch,
      grams: 200,
      dateKey: original.dateKey,
      existingId: original.id,
      existingCreatedAt: original.createdAt,
    );

    expect(edited.id, original.id);
    expect(edited.mealType, MealType.lunch);
    expect(edited.calories, 200);
    expect(edited.protein, 20);
    expect(edited.hasSugarData, isFalse);
    expect(edited.sodium, 400);
  });

  test('detailed meal sums components and survives json round trip', () {
    const rice = FoodItem(
      id: 10,
      foodCode: 'RICE',
      nameTh: 'ข้าวมันสุก',
      nameEn: null,
      energyKcalPer100g: 180,
      proteinGPer100g: 3,
      carbsGPer100g: 35,
      fatGPer100g: 3,
      sugarGPer100g: 1,
      sodiumMgPer100g: 100,
    );
    const chicken = FoodItem(
      id: 11,
      foodCode: 'CHICKEN',
      nameTh: 'เนื้อไก่สุก',
      nameEn: null,
      energyKcalPer100g: 165,
      proteinGPer100g: 31,
      carbsGPer100g: 0,
      fatGPer100g: 4,
      sugarGPer100g: 0,
      sodiumMgPer100g: 70,
    );
    const parent = FoodItem(
      id: 12,
      foodCode: 'DISH',
      nameTh: 'ข้าวมันไก่',
      nameEn: null,
      energyKcalPer100g: 0,
      proteinGPer100g: 0,
      carbsGPer100g: 0,
      fatGPer100g: 0,
      sugarGPer100g: null,
      sodiumMgPer100g: null,
    );

    final entry = MealEntry.fromComponents(
      parentFood: parent,
      mealType: MealType.lunch,
      dateKey: '2026-09-17',
      components: [
        MealComponent.fromFood(rice, 150),
        MealComponent.fromFood(chicken, 100),
      ],
    );
    final restored = MealEntry.fromJson(entry.toJson());

    expect(entry.grams, 250);
    expect(entry.calories, closeTo(435, .001));
    expect(entry.protein, closeTo(35.5, .001));
    expect(entry.isDetailed, isTrue);
    expect(restored.components, hasLength(2));
    expect(restored.calories, closeTo(435, .001));
    expect(restored.components.first.foodName, 'ข้าวมันสุก');
  });
}
