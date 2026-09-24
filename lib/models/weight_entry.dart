class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.note = '',
  });

  final String id;
  final DateTime date;
  final double weight;
  final String note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'note': note,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['id'] as String? ?? '',
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
      );
}
