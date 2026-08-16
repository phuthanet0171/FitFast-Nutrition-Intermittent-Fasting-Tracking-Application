class FastingPlan {
  const FastingPlan({
    required this.name,
    required this.fastingHours,
    required this.eatingHours,
    required this.description,
  });

  final String name;
  final int fastingHours;
  final int eatingHours;
  final String description;
}

const fastingPlans = <FastingPlan>[
  FastingPlan(
    name: '16/8',
    fastingHours: 16,
    eatingHours: 8,
    description: 'เหมาะสำหรับผู้เริ่มต้น',
  ),
  FastingPlan(
    name: '18/6',
    fastingHours: 18,
    eatingHours: 6,
    description: 'เหมาะสำหรับผู้ที่ต้องการความเข้มข้นขึ้น',
  ),
  FastingPlan(
    name: '20/4',
    fastingHours: 20,
    eatingHours: 4,
    description: 'เหมาะสำหรับผู้มีประสบการณ์',
  ),
];
