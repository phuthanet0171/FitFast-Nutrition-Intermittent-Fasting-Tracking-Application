import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get key => name;

  String get label => switch (this) {
        MealType.breakfast => 'อาหารเช้า',
        MealType.lunch => 'อาหารกลางวัน',
        MealType.dinner => 'อาหารเย็น',
        MealType.snack => 'ของว่าง',
      };

  static MealType fromKey(String value) => MealType.values.firstWhere(
        (type) => type.key == value,
        orElse: () => MealType.snack,
      );
}

class MealEntry {
  const MealEntry({
    required this.id,
    required this.dateKey,
    required this.mealType,
    required this.foodId,
    required this.foodCode,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.sodium,
    required this.hasSugarData,
    required this.hasSodiumData,
    required this.createdAt,
    this.components = const [],
  });

  final String id;
  final String dateKey;
  final MealType mealType;
  final int foodId;
  final String foodCode;
  final String foodName;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double sodium;
  final bool hasSugarData;
  final bool hasSodiumData;
  final DateTime createdAt;
  final List<MealComponent> components;

  bool get isDetailed => components.isNotEmpty;

  factory MealEntry.fromFood({
    required FoodItem food,
    required MealType mealType,
    required double grams,
    required String dateKey,
    String? existingId,
    DateTime? existingCreatedAt,
  }) {
    final multiplier = grams / 100;
    final now = DateTime.now();
    return MealEntry(
      id: existingId ?? '${now.microsecondsSinceEpoch}_${food.id}',
      dateKey: dateKey,
      mealType: mealType,
      foodId: food.id,
      foodCode: food.foodCode,
      foodName: food.nameTh,
      grams: grams,
      calories: food.energyKcalPer100g * multiplier,
      protein: food.proteinGPer100g * multiplier,
      carbs: food.carbsGPer100g * multiplier,
      fat: food.fatGPer100g * multiplier,
      sugar: (food.sugarGPer100g ?? 0) * multiplier,
      sodium: (food.sodiumMgPer100g ?? 0) * multiplier,
      hasSugarData: food.sugarGPer100g != null,
      hasSodiumData: food.sodiumMgPer100g != null,
      createdAt: existingCreatedAt ?? now,
      components: const [],
    );
  }

  factory MealEntry.fromComponents({
    required FoodItem parentFood,
    required MealType mealType,
    required String dateKey,
    required List<MealComponent> components,
    String? existingId,
    DateTime? existingCreatedAt,
  }) {
    final now = DateTime.now();
    return MealEntry(
      id: existingId ?? '${now.microsecondsSinceEpoch}_${parentFood.id}',
      dateKey: dateKey,
      mealType: mealType,
      foodId: parentFood.id,
      foodCode: parentFood.foodCode,
      foodName: parentFood.nameTh,
      grams: components.fold(0, (sum, item) => sum + item.grams),
      calories: components.fold(0, (sum, item) => sum + item.calories),
      protein: components.fold(0, (sum, item) => sum + item.protein),
      carbs: components.fold(0, (sum, item) => sum + item.carbs),
      fat: components.fold(0, (sum, item) => sum + item.fat),
      sugar: components.fold(0, (sum, item) => sum + item.sugar),
      sodium: components.fold(0, (sum, item) => sum + item.sodium),
      hasSugarData: components.every((item) => item.hasSugarData),
      hasSodiumData: components.every((item) => item.hasSodiumData),
      createdAt: existingCreatedAt ?? now,
      components: List.unmodifiable(components),
    );
  }

  FoodItem toFoodItem() {
    final multiplier = grams <= 0 ? 1 : 100 / grams;
    return FoodItem(
      id: foodId,
      foodCode: foodCode,
      nameTh: foodName,
      nameEn: null,
      energyKcalPer100g: calories * multiplier,
      proteinGPer100g: protein * multiplier,
      carbsGPer100g: carbs * multiplier,
      fatGPer100g: fat * multiplier,
      sugarGPer100g: hasSugarData ? sugar * multiplier : null,
      sodiumMgPer100g: hasSodiumData ? sodium * multiplier : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'mealType': mealType.key,
        'foodId': foodId,
        'foodCode': foodCode,
        'foodName': foodName,
        'grams': grams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sugar': sugar,
        'sodium': sodium,
        'hasSugarData': hasSugarData,
        'hasSodiumData': hasSodiumData,
        'createdAt': createdAt.toIso8601String(),
        'components': components.map((item) => item.toJson()).toList(),
      };

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return MealEntry(
      id: json['id'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      mealType: MealTypeLabel.fromKey(json['mealType'] as String? ?? ''),
      foodId: (json['foodId'] as num?)?.toInt() ?? 0,
      foodCode: json['foodCode'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      grams: number('grams'),
      calories: number('calories'),
      protein: number('protein'),
      carbs: number('carbs'),
      fat: number('fat'),
      sugar: number('sugar'),
      sodium: number('sodium'),
      hasSugarData: json['hasSugarData'] as bool? ?? false,
      hasSodiumData: json['hasSodiumData'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      components: (json['components'] as List<dynamic>? ?? const [])
          .map((item) =>
              MealComponent.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class MealComponent {
  const MealComponent({
    required this.foodId,
    required this.foodCode,
    required this.foodName,
    required this.grams,
    required this.energyKcalPer100g,
    required this.proteinGPer100g,
    required this.carbsGPer100g,
    required this.fatGPer100g,
    required this.sugarGPer100g,
    required this.sodiumMgPer100g,
  });

  final int foodId;
  final String foodCode;
  final String foodName;
  final double grams;
  final double energyKcalPer100g;
  final double proteinGPer100g;
  final double carbsGPer100g;
  final double fatGPer100g;
  final double? sugarGPer100g;
  final double? sodiumMgPer100g;

  double get _factor => grams / 100;
  double get calories => energyKcalPer100g * _factor;
  double get protein => proteinGPer100g * _factor;
  double get carbs => carbsGPer100g * _factor;
  double get fat => fatGPer100g * _factor;
  double get sugar => (sugarGPer100g ?? 0) * _factor;
  double get sodium => (sodiumMgPer100g ?? 0) * _factor;
  bool get hasSugarData => sugarGPer100g != null;
  bool get hasSodiumData => sodiumMgPer100g != null;

  factory MealComponent.fromFood(FoodItem food, double grams) => MealComponent(
        foodId: food.id,
        foodCode: food.foodCode,
        foodName: food.nameTh,
        grams: grams,
        energyKcalPer100g: food.energyKcalPer100g,
        proteinGPer100g: food.proteinGPer100g,
        carbsGPer100g: food.carbsGPer100g,
        fatGPer100g: food.fatGPer100g,
        sugarGPer100g: food.sugarGPer100g,
        sodiumMgPer100g: food.sodiumMgPer100g,
      );

  FoodItem toFoodItem() => FoodItem(
        id: foodId,
        foodCode: foodCode,
        nameTh: foodName,
        nameEn: null,
        energyKcalPer100g: energyKcalPer100g,
        proteinGPer100g: proteinGPer100g,
        carbsGPer100g: carbsGPer100g,
        fatGPer100g: fatGPer100g,
        sugarGPer100g: sugarGPer100g,
        sodiumMgPer100g: sodiumMgPer100g,
      );

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'foodCode': foodCode,
        'foodName': foodName,
        'grams': grams,
        'energyKcalPer100g': energyKcalPer100g,
        'proteinGPer100g': proteinGPer100g,
        'carbsGPer100g': carbsGPer100g,
        'fatGPer100g': fatGPer100g,
        'sugarGPer100g': sugarGPer100g,
        'sodiumMgPer100g': sodiumMgPer100g,
      };

  factory MealComponent.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    double? optional(String key) => (json[key] as num?)?.toDouble();
    return MealComponent(
      foodId: (json['foodId'] as num?)?.toInt() ?? 0,
      foodCode: json['foodCode'] as String? ?? '',
      foodName: json['foodName'] as String? ?? '',
      grams: number('grams'),
      energyKcalPer100g: number('energyKcalPer100g'),
      proteinGPer100g: number('proteinGPer100g'),
      carbsGPer100g: number('carbsGPer100g'),
      fatGPer100g: number('fatGPer100g'),
      sugarGPer100g: optional('sugarGPer100g'),
      sodiumMgPer100g: optional('sodiumMgPer100g'),
    );
  }
}
