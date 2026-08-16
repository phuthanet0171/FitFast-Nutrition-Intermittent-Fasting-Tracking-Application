import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../theme/app_theme.dart';
import 'if_schedule_setup_screen.dart';

class IfManualPlanScreen extends StatefulWidget {
  const IfManualPlanScreen({
    super.key,
    required this.age,
    required this.healthResult,
  });

  final int age;
  final HealthResult healthResult;

  @override
  State<IfManualPlanScreen> createState() => _IfManualPlanScreenState();
}

class _IfManualPlanScreenState extends State<IfManualPlanScreen> {
  String? _selectedPlan;

  void _finish() {
    if (_selectedPlan == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IfScheduleSetupScreen(
          plan: _selectedPlan!,
          healthResult: widget.healthResult,
          age: widget.age,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const plans = [
      (
        '16/8',
        16,
        8,
        'เหมาะสำหรับผู้เริ่มต้น',
        'เริ่มง่ายและเข้ากับชีวิตประจำวันได้มากกว่า',
        AppColors.teal
      ),
      (
        '18/6',
        18,
        6,
        'สำหรับผู้มีประสบการณ์',
        'เหมาะเมื่อทำ 16/8 ได้สม่ำเสมอแล้ว',
        AppColors.blue
      ),
      (
        '20/4',
        20,
        4,
        'รูปแบบเข้มข้น',
        'ควรมีประสบการณ์และติดตามอาการของร่างกาย',
        AppColors.orange
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกรูปแบบ IF')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  Text('เลือกแผนที่เข้ากับคุณ',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('คุณสามารถเปลี่ยนแผนภายหลังได้จากหน้า IF',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  ...plans.map((plan) {
                    final selected = _selectedPlan == plan.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Material(
                        color: selected
                            ? plan.$6.withValues(alpha: .08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: () => setState(() => _selectedPlan = plan.$1),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: selected ? plan.$6 : AppColors.border,
                                  width: selected ? 2 : 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 7),
                                      decoration: BoxDecoration(
                                          color: plan.$6,
                                          borderRadius:
                                              BorderRadius.circular(99)),
                                      child: Text(plan.$1,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900)),
                                    ),
                                    const Spacer(),
                                    Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: selected
                                            ? plan.$6
                                            : AppColors.border),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                        child: _HourValue(
                                            value: '${plan.$2}',
                                            label: 'ชั่วโมงอด')),
                                    Container(
                                        width: 1,
                                        height: 42,
                                        color: AppColors.border),
                                    Expanded(
                                        child: _HourValue(
                                            value: '${plan.$3}',
                                            label: 'ชั่วโมงทาน')),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Text(plan.$4,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(plan.$5,
                                    style: const TextStyle(
                                        color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                  onPressed: _selectedPlan == null ? null : _finish,
                  child: const Text('ยืนยันและเริ่มใช้ FitFast')),
            ),
          ],
        ),
      ),
    );
  }
}

class _HourValue extends StatelessWidget {
  const _HourValue({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}
