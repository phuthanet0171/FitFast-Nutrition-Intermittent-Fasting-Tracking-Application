import 'food_serving.dart';

class FoodItem {
  const FoodItem({
    this.imageUrl,
    this.imageCredit,
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
    this.ediblePortionPercent,
    this.servings = const [],
    this.commonNameTh,
    this.searchAliases,
  });

  final int id;
  final String? imageUrl;

  /// Photographer and licence, shown with the photo (CC BY/BY-SA need it).
  final String? imageCredit;
  final String foodCode;
  final String nameTh;
  final String? nameEn;
  final double energyKcalPer100g;
  final double proteinGPer100g;
  final double carbsGPer100g;
  final double fatGPer100g;
  final double? sugarGPer100g;
  final double? sodiumMgPer100g;

  /// Share of the purchased weight that is eaten, e.g. 60 for a drumstick
  /// with bone. Nutrients are per 100 g of the edible part.
  final double? ediblePortionPercent;

  /// Verified household units, sorted with the default unit first.
  final List<FoodServing> servings;

  /// Everyday name, e.g. "ผัดไทย" for Thai FCD "ก๋วยเตี๋ยว, ผัดไทย".
  final String? commonNameTh;

  /// Comma-separated extra search words (other names, spellings, English).
  final String? searchAliases;

  String get displayName {
    final common = commonNameTh?.trim();
    return common == null || common.isEmpty ? nameTh : common;
  }

  bool get hasInediblePart =>
      ediblePortionPercent != null &&
      ediblePortionPercent! > 0 &&
      ediblePortionPercent! < 100;

  FoodServing? get defaultServing => servings.isEmpty ? null : servings.first;

  static double _number(dynamic value) => (value as num?)?.toDouble() ?? 0;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    double? optionalNumber(String key) => (json[key] as num?)?.toDouble();
    final servings = json['food_servings'] as List<dynamic>? ?? const [];
    return FoodItem(
      imageUrl: json['image_url'] as String?,
      imageCredit: json['image_credit'] as String?,
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
      ediblePortionPercent: optionalNumber('edible_portion_percent'),
      commonNameTh: json['common_name_th'] as String?,
      searchAliases: json['search_aliases'] as String?,
      servings: FoodServing.sorted(servings.map((item) =>
          FoodServing.fromJson(Map<String, dynamic>.from(item as Map)))),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'image_credit': imageCredit,
        'food_code': foodCode,
        'name_th': nameTh,
        'name_en': nameEn,
        'energy_kcal_per_100g': energyKcalPer100g,
        'protein_g_per_100g': proteinGPer100g,
        'carbs_g_per_100g': carbsGPer100g,
        'fat_g_per_100g': fatGPer100g,
        'sugar_g_per_100g': sugarGPer100g,
        'sodium_mg_per_100g': sodiumMgPer100g,
        'edible_portion_percent': ediblePortionPercent,
        'common_name_th': commonNameTh,
        'search_aliases': searchAliases,
        'food_servings': servings.map((serving) => serving.toJson()).toList(),
      };
}
