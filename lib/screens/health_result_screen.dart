import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class HealthResultScreen extends StatefulWidget {
  const HealthResultScreen(
      {super.key, required this.displayName, required this.result});
  final String displayName;
  final HealthResult result;

  @override
  State<HealthResultScreen> createState() => _HealthResultScreenState();
}

class _HealthResultScreenState extends State<HealthResultScreen> {
  String? _selectedPlan;
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    if (widget.result.isFastingSuitable) {
      _selectedPlan = widget.result.recommendedPlan;
    }
  }

  Future<void> _selectTime() async {
    final value = await showTimePicker(
        context: context,
        initialTime: _startTime,
        helpText: 'เลือกเวลาเริ่มอดอาหาร');
    if (value != null) setState(() => _startTime = value);
  }

  void _openDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      appBar: AppBar(title: const Text('เป้าหมายสุขภาพ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Text('แผนของ ${widget.displayName} พร้อมแล้ว',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _Value(
                                label: 'BMI',
                                value: result.bmi.toStringAsFixed(1))),
                        Expanded(
                            child: _Value(
                                label: 'BMR',
                                value: '${result.bmr.round()} kcal')),
                      ],
                    ),
                    const Divider(height: 30),
                    _Value(
                        label: 'พลังงานที่ควรได้รับต่อวัน',
                        value: '${result.calories.round()} kcal',
                        large: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _Row(
                        label: 'โปรตีน',
                        value: '${result.protein.round()} กรัม'),
                    _Row(
                        label: 'คาร์โบไฮเดรต',
                        value: '${result.carbs.round()} กรัม'),
                    _Row(label: 'ไขมัน', value: '${result.fat.round()} กรัม'),
                    _Row(
                        label: 'น้ำตาลสูงสุด',
                        value: '${result.sugar.round()} กรัม'),
                    _Row(
                        label: 'โซเดียมสูงสุด',
                        value: '${result.sodium.round()} มก.',
                        divider: false),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('แผน IF ที่แนะนำ',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: result.isFastingSuitable
                    ? AppColors.mint
                    : AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                      result.isFastingSuitable
                          ? Icons.auto_awesome_rounded
                          : Icons.health_and_safety_outlined,
                      color: result.isFastingSuitable
                          ? AppColors.tealDark
                          : AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.recommendedPlan,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(result.recommendationReason,
                            style: const TextStyle(
                                color: AppColors.muted, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (result.isFastingSuitable) ...[
              const SizedBox(height: 18),
              ...['16/8', '18/6', '20/4'].map(
                (plan) => Card(
                  child: ListTile(
                    onTap: () => setState(() => _selectedPlan = plan),
                    leading: Icon(
                      _selectedPlan == plan
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: AppColors.teal,
                    ),
                    title: Text(plan,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(switch (plan) {
                      '16/8' => 'เหมาะสำหรับผู้เริ่มต้น',
                      '18/6' => 'สำหรับผู้ที่ปรับตัวกับ 16/8 ได้แล้ว',
                      _ => 'แผนเข้มข้นสำหรับผู้มีประสบการณ์',
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  onTap: _selectTime,
                  leading:
                      const Icon(Icons.schedule_rounded, color: AppColors.teal),
                  title: const Text('เวลาเริ่มอดอาหาร'),
                  subtitle: Text(_startTime.format(context),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _openDashboard,
              child: Text(result.isFastingSuitable
                  ? 'ยืนยันแผนและไปหน้า Dashboard'
                  : 'ไปหน้า Dashboard โดยยังไม่เปิด IF'),
            ),
            const SizedBox(height: 14),
            const Text(
              'ค่าที่แสดงเป็นค่าประมาณสำหรับช่วยวางแผนทั่วไป ไม่ใช่การวินิจฉัยหรือคำแนะนำทางการแพทย์',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.large = false});
  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: large ? 28 : 21, fontWeight: FontWeight.w900)),
        ],
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.divider = true});
  final String label;
  final String value;
  final bool divider;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800))
          ]),
          if (divider) const Divider(height: 24),
        ],
      );
}
