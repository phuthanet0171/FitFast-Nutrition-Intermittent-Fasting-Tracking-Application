import 'package:fitfast/models/food_item.dart';
import 'package:fitfast/models/food_serving.dart';
import 'package:fitfast/models/meal_entry.dart';
import 'package:fitfast/models/plate_order.dart';
import 'package:fitfast/services/household_units.dart';
import 'package:fitfast/services/plate_order_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

FoodItem _food(
  String code,
  String name, {
  int id = 1,
  double kcal = 100,
  double? sugar,
  List<FoodServing> servings = const [],
}) =>
    FoodItem(
      id: id,
      foodCode: code,
      nameTh: name,
      nameEn: null,
      energyKcalPer100g: kcal,
      proteinGPer100g: 10,
      carbsGPer100g: 10,
      fatGPer100g: 10,
      sugarGPer100g: sugar,
      sodiumMgPer100g: null,
      servings: servings,
    );

String? _firstUnit(String code, String name) {
  final unit = HouseholdUnits.forFood(_food(code, name)).firstOrNull;
  return unit == null ? null : '${unit.label}=${unit.grams.round()}';
}

void main() {
  group('household units', () {
    test('everyday foods get the unit people count them in', () {
      expect(_firstUnit('DOH14011', 'ไข่ดาว'), '1 ฟอง=50');
      expect(_firstUnit('H18', 'ไข่ไก่, ต้ม, 10 นาที'), '1 ฟอง=50');
      expect(_firstUnit('H4', 'ไข่ไก่, เจียว (เติมน้ำปลา)'), '1 ฟอง=60');
      expect(_firstUnit('H9', 'ไข่เค็ม'), '1 ฟอง=60');
      expect(_firstUnit('A11', 'ข้าวเจ้า, สุก'), '1 ทัพพี=60');
      expect(_firstUnit('A23', 'ข้าวเหนียว, นึ่ง'), '1 ทัพพี=70');
      expect(_firstUnit('T127', 'ก๋วยเตี๋ยวหมู น้ำ (เส้นใหญ่)'), '1 ชาม=626');
      expect(_firstUnit('T9', 'ก๋วยเตี๋ยว, ผัดไทย'), '1 จาน=359');
      expect(_firstUnit('T39', 'ขนมจีนน้ำยา'), '1 จาน=359');
      expect(_firstUnit('DOH11063', 'ข้าวราดผัดกะเพราไก่'), '1 จาน=359');
      expect(_firstUnit('T21', 'แกงเขียวหวาน, ไก่'), '1 ถ้วย=240');
      expect(_firstUnit('E12', 'กล้วยหอม'), '1 ผล=120');
      expect(_firstUnit('J40', 'นมจืดยูเอชที'), '1 กล่อง (200 มล.)=200');
      expect(_firstUnit('F12', 'ไก่, น่อง, ต้ม'), '1 น่อง=75');
      expect(_firstUnit('G20', 'ปลาทับทิม, นึ่ง'), '1 ช้อนโต๊ะ=15');
    });

    test('ingredients nobody eats by the spoon stay in grams', () {
      expect(_firstUnit('A1', 'ข้าวเจ้า, พันธุ์ต่างๆ, ดิบ'), isNull);
      expect(_firstUnit('Z1', 'แครกเกอร์ รสชีส, ไฮไท'), isNull);
    });

    test('a default measured unit comes first and is not duplicated', () {
      final food = _food('T54', 'ข้าวราดไก่ผัดใบกะเพรา', servings: const [
        FoodServing(
            id: 1, foodId: 1, label: '1 จาน', grams: 397, isDefault: true),
      ]);
      final units = HouseholdUnits.forFood(food);
      expect(units.map((unit) => unit.label), ['1 จาน', '1 ช้อนโต๊ะ']);
      expect(units.first.grams, 397);
    });

    test('rule units come before measured units that are not default', () {
      final food = _food('F12', 'ไก่, น่อง, ต้ม', servings: const [
        FoodServing(id: 1, foodId: 1, label: '1 ช้อนกินข้าว', grams: 15),
      ]);
      expect(HouseholdUnits.forFood(food).map((unit) => unit.label),
          ['1 น่อง', '1 ช้อนกินข้าว']);
    });

    test('logged grams are described in the unit they came from', () {
      final egg = _food('DOH14011', 'ไข่ดาว');
      expect(HouseholdUnits.describe(egg, 100), '2 ฟอง');
      expect(HouseholdUnits.describe(egg, 25), '½ ฟอง');
      expect(HouseholdUnits.describe(egg, 75), '1½ ฟอง');
      expect(HouseholdUnits.describe(egg, 37), '37 ก.');

      final plate = _food('T54', 'ข้าวกะเพราไก่', servings: const [
        FoodServing(
          id: 1,
          foodId: 1,
          label: '1 จาน',
          grams: 400,
          gramsMin: 280,
          gramsMax: 520,
          isDefault: true,
        ),
      ]);
      expect(HouseholdUnits.describe(plate, 460), '1 จาน (ใหญ่)');
      expect(HouseholdUnits.describe(plate, 400), '1 จาน');
    });

    test('amounts read naturally', () {
      expect(HouseholdUnits.formatAmount(.5), '½');
      expect(HouseholdUnits.formatAmount(1), '1');
      expect(HouseholdUnits.formatAmount(2.5), '2½');
      expect(HouseholdUnits.formatAmount(1.25), '1.25');
      expect(HouseholdUnits.formatNumber(150.0), '150');
      expect(HouseholdUnits.formatNumber(12.5), '13');
      expect(HouseholdUnits.formatNumber(1.5), '1.5');
    });
  });

  test('spoons are offered for dishes, rice and vegetables', () {
    List<String> labels(String code, String name) => [
          for (final unit in HouseholdUnits.forFood(_food(code, name)))
            unit.label,
        ];
    expect(labels('A11', 'ข้าวเจ้า, สุก'), ['1 ทัพพี', '1 ช้อนโต๊ะ']);
    expect(labels('D10', 'คะน้า, ผัด'), contains('1 ช้อนโต๊ะ'));
    expect(labels('T54', 'ข้าวกะเพราไก่'), ['1 จาน', '1 ช้อนโต๊ะ']);
    // A measured ช้อนกินข้าว is the same spoon, so it is not shown twice.
    final measured = _food('F12', 'ไก่, น่อง, ต้ม', servings: const [
      FoodServing(id: 1, foodId: 1, label: '1 ช้อนกินข้าว', grams: 15),
    ]);
    expect(HouseholdUnits.forFood(measured).map((unit) => unit.label),
        isNot(contains('1 ช้อนโต๊ะ')));
    // 300 g typed by hand is not shown as 20 spoons.
    expect(HouseholdUnits.describe(_food('T21', 'แกงเขียวหวาน, ไก่'), 45),
        '3 ช้อนโต๊ะ');
    expect(
        HouseholdUnits.describe(_food('T54', 'ข้าวกะเพราไก่'), 300), '300 ก.');
  });

  group('plate orders', () {
    final dish = _food('T54', 'ข้าวกะเพราไก่', id: 54, kcal: 200, sugar: 2);
    final egg = _food('DOH14011', 'ไข่ดาว', id: 99, kcal: 266);

    MealEntry build(PlateOrder order, {FoodItem? withEgg}) =>
        PlateOrderCalculator.build(
          dish: dish,
          plateGrams: 400,
          order: order,
          egg: withEgg,
          mealType: MealType.lunch,
          dateKey: '2026-10-01',
        );

    test('a plate without eggs is an ordinary entry', () {
      final entry = build(const PlateOrder(unitLabel: '1 จาน'), withEgg: egg);
      expect(entry.isDetailed, isFalse);
      expect(entry.calories, 800);
    });

    test('eggs are added as their own component', () {
      // Two fried eggs of 50 g each at 266 kcal / 100 g.
      final entry = build(
        const PlateOrder(egg: EggStyle.fried, eggCount: 2),
        withEgg: egg,
      );
      expect(entry.calories, closeTo(1066, .01));
      expect(entry.components.first.portion, '1 จาน');
      expect(entry.components.last.portion, '2 ฟอง');
    });

    test('the eggs survive saving and loading', () {
      final entry = build(
        const PlateOrder(
            unitLabel: '1 จาน', size: 2, egg: EggStyle.fried, eggCount: 2),
        withEgg: egg,
      );
      final loaded = MealEntry.fromJson(entry.toJson());
      final order = loaded.plateOrder!;
      expect(order.size, 2);
      expect(order.egg, EggStyle.fried);
      expect(order.eggCount, 2);
      expect(loaded.components.first.portion, '1 จาน (ใหญ่)');
      expect(loaded.calories, closeTo(entry.calories, .001));
    });

    test('eggs are offered only on rice plates', () {
      const plate = FoodServing(id: 1, foodId: 1, label: '1 จาน', grams: 359);
      expect(PlateOrderCalculator.isRicePlate(dish, plate), isTrue);
      expect(PlateOrderCalculator.isRicePlate(_food('T205', 'ข้าวผัด'), plate),
          isTrue);
      expect(PlateOrderCalculator.isRicePlate(_food('T9', 'ผัดไทย'), plate),
          isFalse);
    });
  });
}
