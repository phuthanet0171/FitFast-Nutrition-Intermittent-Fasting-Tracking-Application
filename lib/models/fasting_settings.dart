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
