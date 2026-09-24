class FoodServing {
  const FoodServing({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
  });

  final int id;
  final int foodId;
  final String label;
  final double grams;

  factory FoodServing.fromJson(Map<String, dynamic> json) => FoodServing(
        id: (json['id'] as num).toInt(),
        foodId: (json['food_id'] as num).toInt(),
        label: json['label'] as String? ?? 'หน่วยบริโภค',
        grams: (json['grams'] as num).toDouble(),
      );
}
