import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../services/notification_service.dart';
import '../services/fasting_settings_service.dart';
import '../theme/app_theme.dart';
import 'if_setup_method_screen.dart';
import 'main_shell.dart';

class IfInterestScreen extends StatefulWidget {
  const IfInterestScreen({
    super.key,
    required this.age,
    required this.bmi,
    required this.healthResult,
  });

  final int age;
  final double bmi;
  final HealthResult healthResult;

  @override
  State<IfInterestScreen> createState() => _IfInterestScreenState();
}

class _IfInterestScreenState extends State<IfInterestScreen> {
  bool? _wantsIf;

  bool get _isTeen => widget.age < 18;

  Future<void> _continue() async {
    if (_isTeen) {
      await NotificationService.instance.cancelFastingReminders();
      await FastingSettingsService.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainShell(
            healthResult: widget.healthResult,
            age: widget.age,
          ),
        ),
        (route) => false,
      );
      return;
    }
    if (_wantsIf == null) return;
    if (_wantsIf == false) {
      await NotificationService.instance.cancelFastingReminders();
      await FastingSettingsService.instance.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainShell(
            healthResult: widget.healthResult,
            age: widget.age,
          ),
        ),
        (route) => false,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IfSetupMethodScreen(
          age: widget.age,
          bmi: widget.bmi,
          healthResult: widget.healthResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า IF')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                    color: AppColors.mint, shape: BoxShape.circle),
                child: const Icon(Icons.timer_outlined,
                    color: AppColors.tealDark, size: 38),
              ),
              const SizedBox(height: 24),
              Text(
                  _isTeen
                      ? 'เริ่มดูแลสุขภาพอย่างเหมาะสม'
                      : 'คุณต้องการทำ IF ไหม?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                _isTeen
                    ? 'สำหรับอายุ 16–17 ปี FitFast จะเน้นโภชนาการที่สมดุลและไม่เปิดแผน IF อัตโนมัติ'
                    : 'คุณสามารถใช้ระบบโภชนาการของ FitFast ได้\nแม้จะไม่เลือกทำ Intermittent Fasting',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 34),
              if (!_isTeen) ...[
                _AnswerCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'ต้องการทำ IF',
                  description: 'ช่วยเลือกหรือตั้งค่าแผนการอดอาหาร',
                  selected: _wantsIf == true,
                  onTap: () => setState(() => _wantsIf = true),
                ),
                const SizedBox(height: 14),
              ],
              _AnswerCard(
                icon: _isTeen
                    ? Icons.health_and_safety_outlined
                    : Icons.restaurant_menu_rounded,
                title:
                    _isTeen ? 'ใช้ระบบโภชนาการโดยไม่เปิด IF' : 'ยังไม่ต้องการ',
                description: _isTeen
                    ? 'บันทึกอาหารและติดตามสุขภาพได้ตามปกติ'
                    : 'เริ่มบันทึกอาหารและติดตามสุขภาพได้เลย',
                selected: _isTeen || _wantsIf == false,
                onTap: () => setState(() => _wantsIf = false),
              ),
              const Spacer(),
              FilledButton(
                  onPressed: _isTeen || _wantsIf != null ? _continue : null,
                  child: Text(_isTeen || _wantsIf == false
                      ? 'เริ่มใช้ FitFast'
                      : 'ถัดไป')),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard(
      {required this.icon,
      required this.title,
      required this.description,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: selected ? AppColors.teal : AppColors.border,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.surface,
                    borderRadius: BorderRadius.circular(17)),
                child: Icon(icon,
                    color: selected ? AppColors.tealDark : AppColors.muted),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.teal : AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}
