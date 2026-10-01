import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/food_serving.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _food(List<Map<String, dynamic>> servings) => {
      'id': 295,
      'food_code': 'T54',
      'name_th': 'ข้าวราดไก่ผัดใบกะเพรา',
      'energy_kcal_per_100g': 188,
      'protein_g_per_100g': 8,
      'carbs_g_per_100g': 25,
      'fat_g_per_100g': 6,
      'edible_portion_percent': null,
      'food_servings': servings,
    };

void main() {
  test('servings embedded in a catalog row put the default unit first', () {
    final food = FoodItem.fromJson(_food([
      {'id': 1, 'food_id': 295, 'label': '1 ทัพพี', 'grams': 60},
      {
        'id': 2,
        'food_id': 295,
        'label': '1 จาน',
        'grams': 397,
        'grams_min': 280,
        'grams_max': 512,
        'is_default': true,
        'source_name': 'IJERPH 2023',
      },
    ]));

    final plate = food.defaultServing!;
    expect(plate.label, '1 จาน');
    expect(plate.noun, 'จาน');
    expect(plate.sizeGrams, [339, 397, 455]);
    expect(FoodItem.fromJson(food.toJson()).servings.first.grams, 397);
  });

  test('rows from before the phase 2 columns still parse', () {
    final food = FoodItem.fromJson(_food([
      {'id': 3, 'food_id': 295, 'label': '1 ช้อนกินข้าว', 'grams': 15},
    ]));
    final spoon = food.servings.single;
    expect(spoon.isDefault, isFalse);
    expect(spoon.hasSizeRange, isFalse);
    expect(spoon.sizeGrams, [15]);
    expect(food.hasInediblePart, isFalse);
  });

  test('measured units sort before group estimates', () {
    final sorted = FoodServing.sorted(const [
      FoodServing(
          id: 1, foodId: 1, label: '1 ชาม', grams: 626, isEstimate: true),
      FoodServing(id: 2, foodId: 1, label: '1 ทัพพี', grams: 60),
      FoodServing(id: 3, foodId: 1, label: 'ผิด', grams: 0),
    ]);
    expect(sorted.map((s) => s.label), ['1 ทัพพี', '1 ชาม']);
  });
}
