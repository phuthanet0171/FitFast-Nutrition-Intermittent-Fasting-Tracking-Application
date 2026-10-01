class FoodServing {
  const FoodServing({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
    this.isDefault = false,
    this.isEstimate = false,
    this.gramsMin,
    this.gramsMax,
    this.sourceName,
  });

  final int id;
  final int foodId;
  final String label;
  final double grams;

  /// Shown first when a new entry is logged.
  final bool isDefault;

  /// A group average rather than a weight measured for this exact dish.
  final bool isEstimate;

  /// Lightest and heaviest portions measured by the source, when known.
  final double? gramsMin;
  final double? gramsMax;
  final String? sourceName;

  /// The unit name without a leading "1", e.g. "1 จาน" becomes "จาน".
  String get noun => label.replaceFirst(RegExp(r'^1\s*'), '');

  bool get hasSizeRange =>
      gramsMin != null &&
      gramsMax != null &&
      gramsMin! > 0 &&
      gramsMin! < grams &&
      gramsMax! > grams;

  /// Small, regular and large portions. Small and large sit halfway between
  /// the average and the measured extremes, so they stay realistic.
  List<double> get sizeGrams => hasSizeRange
      ? [
          ((gramsMin! + grams) / 2).roundToDouble(),
          grams,
          ((grams + gramsMax!) / 2).roundToDouble(),
        ]
      : [grams];

  factory FoodServing.fromJson(Map<String, dynamic> json) {
    double? optional(String key) => (json[key] as num?)?.toDouble();
    return FoodServing(
      id: (json['id'] as num).toInt(),
      foodId: (json['food_id'] as num).toInt(),
      label: json['label'] as String? ?? 'หน่วยบริโภค',
      grams: (json['grams'] as num).toDouble(),
      isDefault: json['is_default'] as bool? ?? false,
      isEstimate: json['is_estimate'] as bool? ?? false,
      gramsMin: optional('grams_min'),
      gramsMax: optional('grams_max'),
      sourceName: json['source_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'food_id': foodId,
        'label': label,
        'grams': grams,
        'is_default': isDefault,
        'is_estimate': isEstimate,
        'grams_min': gramsMin,
        'grams_max': gramsMax,
        'source_name': sourceName,
      };

  /// Default unit first, then measured units before estimates, then by size.
  static List<FoodServing> sorted(Iterable<FoodServing> servings) {
    int rank(FoodServing serving) =>
        (serving.isDefault ? 0 : 2) + (serving.isEstimate ? 1 : 0);
    return servings
        .where((serving) =>
            serving.grams.isFinite &&
            serving.grams > 0 &&
            serving.grams <= 5000)
        .toList()
      ..sort((a, b) {
        final byRank = rank(a).compareTo(rank(b));
        return byRank != 0 ? byRank : a.grams.compareTo(b.grams);
      });
  }
}
