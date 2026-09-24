class HealthProfile {
  const HealthProfile({
    required this.age,
    required this.gender,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.activity,
    required this.weightGoal,
    required this.updatedAt,
  });

  final int age;
  final String gender;
  final double height;
  final double currentWeight;
  final double targetWeight;
  final String activity;
  final String weightGoal;
  final DateTime updatedAt;

  String get genderLabel => gender == 'male' ? 'ชาย' : 'หญิง';

  String get goalLabel => switch (weightGoal) {
        'lose' => 'ลดน้ำหนัก',
        'gain' => 'เพิ่มน้ำหนัก',
        _ => 'รักษาน้ำหนัก',
      };

  String get activityLabel => switch (activity) {
        'sedentary' => 'กิจกรรมน้อย',
        'moderate' => 'กิจกรรมปานกลาง',
        'high' => 'กิจกรรมสูง',
        _ => 'กิจกรรมเบา',
      };

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'height': height,
        'currentWeight': currentWeight,
        'targetWeight': targetWeight,
        'activity': activity,
        'weightGoal': weightGoal,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
        age: (json['age'] as num?)?.toInt() ?? 0,
        gender: json['gender'] as String? ?? 'male',
        height: (json['height'] as num?)?.toDouble() ?? 0,
        currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 0,
        targetWeight: (json['targetWeight'] as num?)?.toDouble() ?? 0,
        activity: json['activity'] as String? ?? 'light',
        weightGoal: json['weightGoal'] as String? ?? 'maintain',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  HealthProfile copyWith({
    double? currentWeight,
    double? targetWeight,
    DateTime? updatedAt,
  }) =>
      HealthProfile(
        age: age,
        gender: gender,
        height: height,
        currentWeight: currentWeight ?? this.currentWeight,
        targetWeight: targetWeight ?? this.targetWeight,
        activity: activity,
        weightGoal: weightGoal,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
