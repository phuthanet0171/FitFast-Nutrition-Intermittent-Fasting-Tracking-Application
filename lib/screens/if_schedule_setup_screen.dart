import 'package:flutter/material.dart';

import '../models/fasting_settings.dart';
import '../models/health_result.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class IfScheduleSetupScreen extends StatefulWidget {
  const IfScheduleSetupScreen({
    super.key,
    required this.plan,
    required this.age,
    required this.healthResult,
  });

  final String plan;
  final int age;
  final HealthResult healthResult;

  @override
  State<IfScheduleSetupScreen> createState() => _IfScheduleSetupScreenState();
}

class _IfScheduleSetupScreenState extends State<IfScheduleSetupScreen> {
  TimeOfDay? _fastingStart;
  bool _notificationsEnabled = false;
  bool _saving = false;

  int get _fastingHours => int.tryParse(widget.plan.split('/').first) ?? 16;
  int get _eatingHours => 24 - _fastingHours;

  TimeOfDay? get _eatingStart {
    final fastingStart = _fastingStart;
    if (fastingStart == null) return null;
    final totalMinutes =
        (fastingStart.hour * 60 + fastingStart.minute + _fastingHours * 60) %
            (24 * 60);
    return TimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }

  Future<void> _pickFastingStart() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _fastingStart ?? TimeOfDay.now(),
      helpText: 'เลือกเวลาเริ่มอดอาหาร',
      confirmText: 'ยืนยัน',
      cancelText: 'ยกเลิก',
    );
    if (value != null) setState(() => _fastingStart = value);
  }

  Future<void> _pickEatingStart() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _eatingStart ?? TimeOfDay.now(),
      helpText: 'เลือกเวลาเริ่มรับประทาน',
      confirmText: 'ยืนยัน',
      cancelText: 'ยกเลิก',
    );
    if (value == null) return;
    var totalMinutes = value.hour * 60 + value.minute - _fastingHours * 60;
    totalMinutes %= 24 * 60;
    if (totalMinutes < 0) totalMinutes += 24 * 60;
    setState(() {
      _fastingStart = TimeOfDay(
        hour: totalMinutes ~/ 60,
        minute: totalMinutes % 60,
      );
    });
  }

  Future<void> _continue() async {
    final fastingStart = _fastingStart;
    if (fastingStart == null || _saving) return;
    setState(() => _saving = true);

    var notificationsEnabled = _notificationsEnabled;
    if (notificationsEnabled) {
      notificationsEnabled =
          await NotificationService.instance.requestPermission();
    }

    final settings = FastingSettings(
      plan: widget.plan,
      fastingStartHour: fastingStart.hour,
      fastingStartMinute: fastingStart.minute,
      notificationsEnabled: notificationsEnabled,
    );

    await NotificationService.instance.scheduleFastingReminders(settings);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(
          fastingSettings: settings,
          healthResult: widget.healthResult,
          age: widget.age,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final eatingStart = _eatingStart;
    return Scaffold(
      appBar: AppBar(title: const Text('กำหนดเวลา IF')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded,
                            color: AppColors.tealDark, size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('แผน ${widget.plan}',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text(
                                'อด $_fastingHours ชั่วโมง • กินได้ $_eatingHours ชั่วโมง',
                                style:
                                    const TextStyle(color: AppColors.tealDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text('เลือกเวลาที่เหมาะกับคุณ',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'เลือกเวลาเริ่มอดหรือเริ่มกินเพียงอย่างเดียว ระบบจะคำนวณอีกเวลาให้เอง',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SetupTimeCard(
                          icon: Icons.lock_clock_outlined,
                          label: 'เริ่มอด',
                          value: _fastingStart?.format(context) ?? 'เลือกเวลา',
                          color: AppColors.navy,
                          onTap: _pickFastingStart,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SetupTimeCard(
                          icon: Icons.restaurant_rounded,
                          label: 'เริ่มกิน',
                          value: eatingStart?.format(context) ?? 'เลือกเวลา',
                          color: AppColors.orange,
                          onTap: _pickEatingStart,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                      secondary: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.tealDark,
                      ),
                      title: const Text(
                        'แจ้งเตือนเวลาเริ่มกินและเริ่มอด',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text('แจ้งเตือนทุกวันตามเวลาที่เลือก'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                onPressed: _fastingStart == null || _saving ? null : _continue,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('บันทึกและเริ่มใช้แผน IF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupTimeCard extends StatelessWidget {
  const _SetupTimeCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 14),
              Text(label, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
