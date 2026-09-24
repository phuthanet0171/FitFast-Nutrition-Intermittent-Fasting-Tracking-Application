import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../theme/app_theme.dart';
import 'if_interest_screen.dart';

class HealthSummaryScreen extends StatelessWidget {
  const HealthSummaryScreen({
    super.key,
    required this.age,
    required this.height,
    required this.currentWeight,
    required this.targetWeight,
    required this.result,
  });

  final int age;
  final double height;
  final double currentWeight;
  final double targetWeight;
  final HealthResult result;

  String get _bmiLabel {
    if (result.bmi < 18.5) return 'ต่ำกว่าเกณฑ์';
    if (result.bmi < 25) return 'อยู่ในเกณฑ์ทั่วไป';
    if (result.bmi < 30) return 'สูงกว่าเกณฑ์';
    return 'สูงมากกว่าเกณฑ์';
  }

  String get _goalLabel => switch (result.weightGoal) {
        'lose' => 'ลดน้ำหนัก',
        'gain' => 'เพิ่มน้ำหนัก',
        _ => 'รักษาน้ำหนัก',
      };

  void _continue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IfInterestScreen(
          age: age,
          bmi: result.bmi,
          healthResult: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เป้าหมายของคุณ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.tealDark]),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.white),
                  SizedBox(height: 16),
                  Text('แผนสุขภาพพร้อมแล้ว!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('FitFast คำนวณจากข้อมูลและระดับกิจกรรมของคุณ',
                      style: TextStyle(color: Color(0xFFD7F5ED), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _MetricCard(
                        label: 'BMI',
                        value: result.bmi.toStringAsFixed(1),
                        detail: _bmiLabel,
                        color: AppColors.orange)),
                const SizedBox(width: 12),
                Expanded(
                    child: _MetricCard(
                        label: 'BMR',
                        value: result.bmr.round().toString(),
                        detail: 'kcal/วัน',
                        color: AppColors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mint,
                  child: Icon(Icons.flag_rounded, color: AppColors.tealDark),
                ),
                title: const Text('เป้าหมายที่เลือก'),
                trailing: Text(_goalLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            if (result.usesTeenSafetyMode) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.health_and_safety_outlined,
                        color: AppColors.orange),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'สำหรับอายุ 16–17 ปี ระบบใช้เป้าหมายรักษาน้ำหนัก '
                        'และจะไม่เปิดคำแนะนำ IF อัตโนมัติ',
                        style: TextStyle(fontSize: 12, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                          color: AppColors.mint, shape: BoxShape.circle),
                      child: const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.tealDark),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                        child: Text('พลังงานแนะนำต่อวัน',
                            style: TextStyle(fontWeight: FontWeight.w700))),
                    Text('${result.calories.round()} kcal',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('เป้าหมายสารอาหาร',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _NutrientRow(
                        label: 'โปรตีน',
                        value: '${result.protein.round()} กรัม',
                        color: AppColors.blue),
                    _NutrientRow(
                        label: 'คาร์โบไฮเดรต',
                        value: '${result.carbs.round()} กรัม',
                        color: AppColors.teal),
                    _NutrientRow(
                        label: 'ไขมัน',
                        value: '${result.fat.round()} กรัม',
                        color: const Color(0xFFFFC34D),
                        divider: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ProfileValue(label: 'อายุ', value: '$age ปี'),
                    _ProfileValue(
                        label: 'ส่วนสูง', value: '${height.round()} ซม.'),
                    _ProfileValue(
                        label: 'เป้าหมาย',
                        value: '${targetWeight.toStringAsFixed(1)} กก.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: () => _continue(context),
                child: const Text('ถัดไป')),
            const SizedBox(height: 12),
            const Text(
              'ค่าที่แสดงเป็นการประมาณเบื้องต้น ไม่ใช่คำวินิจฉัยทางการแพทย์',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.detail,
      required this.color});
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow(
      {required this.label,
      required this.value,
      required this.color,
      this.divider = true});
  final String label;
  final String value;
  final Color color;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        if (divider) const Divider(height: 26),
      ],
    );
  }
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
