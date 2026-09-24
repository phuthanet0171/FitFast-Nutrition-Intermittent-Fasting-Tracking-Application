class FastingSettings {
  const FastingSettings({
    required this.plan,
    required this.fastingStartHour,
    required this.fastingStartMinute,
    this.notificationsEnabled = false,
  });

  final String plan;
  final int fastingStartHour;
  final int fastingStartMinute;
  final bool notificationsEnabled;

  int get fastingHours => int.tryParse(plan.split('/').first) ?? 16;
  int get eatingHours => 24 - fastingHours;

  DateTime get fastingStart => DateTime(
        2000,
        1,
        1,
        fastingStartHour,
        fastingStartMinute,
      );

  DateTime get eatingStart => fastingStart.add(Duration(hours: fastingHours));

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'fastingStartHour': fastingStartHour,
        'fastingStartMinute': fastingStartMinute,
        'notificationsEnabled': notificationsEnabled,
      };

  factory FastingSettings.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as String? ?? '';
    final hour = (json['fastingStartHour'] as num?)?.toInt() ?? -1;
    final minute = (json['fastingStartMinute'] as num?)?.toInt() ?? -1;
    if (!const ['16/8', '18/6', '20/4'].contains(plan) ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      throw const FormatException('Invalid fasting settings');
    }
    return FastingSettings(
      plan: plan,
      fastingStartHour: hour,
      fastingStartMinute: minute,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }

  FastingSettings copyWith({
    String? plan,
    int? fastingStartHour,
    int? fastingStartMinute,
    bool? notificationsEnabled,
  }) {
    return FastingSettings(
      plan: plan ?? this.plan,
      fastingStartHour: fastingStartHour ?? this.fastingStartHour,
      fastingStartMinute: fastingStartMinute ?? this.fastingStartMinute,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
