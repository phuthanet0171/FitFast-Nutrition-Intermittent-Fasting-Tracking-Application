import '../models/food_item.dart';
import '../models/food_serving.dart';
import '../models/meal_entry.dart';
import '../models/plate_order.dart';
import 'household_units.dart';

/// Adds eggs to a rice plate: "ข้าวกะเพราไก่ + ไข่ดาว 2 ฟอง" is saved as
/// one entry with the plate and the eggs as components, using the
/// catalogue egg and its household unit (ฟอง).
class PlateOrderCalculator {
  PlateOrderCalculator._();

  static final _ricePlate =
      RegExp('^ข้าว(?!เหนียว|เกรียบ|โพด|ต้ม|หลาม|เม่า|ตัง|แต๋น|ปุ้น|ซอย)');

  /// A plate of rice with something on top, logged by the plate.
  static bool isRicePlate(FoodItem food, FoodServing? unit) {
    final names = {food.displayName.trim(), food.nameTh.trim()};
    return unit != null &&
        unit.shortNoun == 'จาน' &&
        names.any(_ricePlate.hasMatch) &&
        !names.any((name) => name.contains('เฉพาะข้าว'));
  }

  /// Grams of one egg of [egg] as served (edible part).
  static double eggGrams(FoodItem egg) {
    for (final unit in HouseholdUnits.forFood(egg)) {
      if (unit.shortNoun == 'ฟอง') return unit.grams;
    }
    return 50;
  }

  /// The entry to save: a normal entry without eggs, otherwise the plate
  /// and the eggs as components.
  static MealEntry build({
    required FoodItem dish,
    required double plateGrams,
    required PlateOrder order,
    required MealType mealType,
    required String dateKey,
    FoodItem? egg,
    String? existingId,
    DateTime? existingCreatedAt,
  }) {
    final grams = plateGrams * order.amount;
    if (egg == null || !order.hasEgg) {
      return MealEntry.fromFood(
        food: dish,
        mealType: mealType,
        grams: grams,
        dateKey: dateKey,
        existingId: existingId,
        existingCreatedAt: existingCreatedAt,
      );
    }
    final size =
        order.size == 1 ? '' : ' (${HouseholdUnits.sizeLabels[order.size]})';
    return MealEntry.fromComponents(
      parentFood: dish,
      mealType: mealType,
      dateKey: dateKey,
      components: [
        MealComponent.fromFood(dish, grams,
            portion: '${HouseholdUnits.formatAmount(order.amount)} จาน$size',
            order: order),
        MealComponent.fromFood(egg, eggGrams(egg) * order.eggCount,
            portion: '${order.eggCount} ฟอง'),
      ],
      existingId: existingId,
      existingCreatedAt: existingCreatedAt,
    );
  }
}
