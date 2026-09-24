class FoodItem {
  const FoodItem({
    this.imageUrl,
    required this.id,
    required this.foodCode,
    required this.nameTh,
    required this.nameEn,
    required this.energyKcalPer100g,
    required this.proteinGPer100g,
    required this.carbsGPer100g,
    required this.fatGPer100g,
    required this.sugarGPer100g,
    required this.sodiumMgPer100g,
  });

  final int id;
  final String? imageUrl;
  final String foodCode;
  final String nameTh;
  final String? nameEn;
  final double energyKcalPer100g;
  final double proteinGPer100g;
  final double carbsGPer100g;
  final double fatGPer100g;
  final double? sugarGPer100g;
  final double? sodiumMgPer100g;

  static double _number(dynamic value) => (value as num?)?.toDouble() ?? 0;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    double? optionalNumber(String key) => (json[key] as num?)?.toDouble();
    return FoodItem(
      imageUrl: json['image_url'] as String?,
      id: (json['id'] as num).toInt(),
      foodCode: json['food_code'] as String? ?? '',
      nameTh: json['name_th'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      energyKcalPer100g: _number(json['energy_kcal_per_100g']),
      proteinGPer100g: _number(json['protein_g_per_100g']),
      carbsGPer100g: _number(json['carbs_g_per_100g']),
      fatGPer100g: _number(json['fat_g_per_100g']),
      sugarGPer100g: optionalNumber('sugar_g_per_100g'),
      sodiumMgPer100g: optionalNumber('sodium_mg_per_100g'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'food_code': foodCode,
        'name_th': nameTh,
        'name_en': nameEn,
        'energy_kcal_per_100g': energyKcalPer100g,
        'protein_g_per_100g': proteinGPer100g,
        'carbs_g_per_100g': carbsGPer100g,
        'fat_g_per_100g': fatGPer100g,
        'sugar_g_per_100g': sugarGPer100g,
        'sodium_mg_per_100g': sodiumMgPer100g,
      };
}
