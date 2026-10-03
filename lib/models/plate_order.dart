/// Eggs people commonly add to a rice plate, with their catalogue codes.
enum EggStyle {
  fried('ไข่ดาว', 'DOH14011'),
  omelet('ไข่เจียว', 'H4'),
  boiled('ไข่ต้ม', 'H18');

  const EggStyle(this.label, this.foodCode);

  final String label;
  final String foodCode;

  static EggStyle? fromName(String? name) {
    for (final style in values) {
      if (style.name == name) return style;
    }
    return null;
  }
}

/// A rice plate with eggs added, e.g. ข้าวกะเพราไก่ + ไข่ดาว 2 ฟอง.
class PlateOrder {
  const PlateOrder({
    this.unitLabel,
    this.size = 1,
    this.amount = 1,
    this.egg,
    this.eggCount = 0,
  });

  /// The plate unit and size chosen, so editing shows the same choice.
  final String? unitLabel;
  final int size;
  final double amount;
  final EggStyle? egg;
  final int eggCount;

  bool get hasEgg => egg != null && eggCount > 0;

  PlateOrder copyWith({
    String? unitLabel,
    int? size,
    double? amount,
    EggStyle? Function()? egg,
    int? eggCount,
  }) =>
      PlateOrder(
        unitLabel: unitLabel ?? this.unitLabel,
        size: size ?? this.size,
        amount: amount ?? this.amount,
        egg: egg == null ? this.egg : egg(),
        eggCount: eggCount ?? this.eggCount,
      );

  Map<String, dynamic> toJson() => {
        'unit': unitLabel,
        'size': size,
        'amount': amount,
        'egg': egg?.name,
        'eggCount': eggCount,
      };

  factory PlateOrder.fromJson(Map<String, dynamic> json) => PlateOrder(
        unitLabel: json['unit'] as String?,
        size: (json['size'] as num?)?.toInt() ?? 1,
        amount: (json['amount'] as num?)?.toDouble() ?? 1,
        egg: EggStyle.fromName(json['egg'] as String?),
        eggCount: (json['eggCount'] as num?)?.toInt() ?? 0,
      );
}
