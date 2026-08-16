import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'if_schedule_setup_screen.dart';

class IfRecommendationScreen extends StatefulWidget {
  const IfRecommendationScreen({
    super.key,
    required this.age,
    required this.bmi,
    required this.healthResult,
  });

  final int age;
  final double bmi;
  final HealthResult healthResult;

  @override
  State<IfRecommendationScreen> createState() => _IfRecommendationScreenState();
}

class _IfRecommendationScreenState extends State<IfRecommendationScreen> {
  String _experience = 'beginner';
  String _schedule = 'regular';
  String _reaction = 'unknown';
  bool _diabetesOrMedication = false;
  bool _pregnantOrBreastfeeding = false;
  bool _eatingDisorder = false;
  bool _kidneyOrLiverCondition = false;

  void _showRecommendation() {
    final unsafe = widget.age < 18 ||
        widget.bmi < 18.5 ||
        _diabetesOrMedication ||
        _pregnantOrBreastfeeding ||
        _eatingDisorder ||
        _kidneyOrLiverCondition ||
        _reaction == 'unwell';

    String? plan;
    String reason;
    if (unsafe) {
      reason =
          'ข้อมูลบางข้ออาจทำให้การอดอาหารไม่เหมาะสม ควรปรึกษาแพทย์หรือนักกำหนดอาหารก่อนเริ่ม';
    } else if (_experience == 'beginner') {
      plan = '16/8';
      reason =
          'เริ่มจากช่วงทาน 8 ชั่วโมงเพื่อให้ร่างกายและกิจวัตรค่อย ๆ ปรับตัว';
    } else if (_experience == 'sixteen') {
      plan = _schedule == 'regular' && _reaction != 'unwell' ? '18/6' : '16/8';
      reason = plan == '18/6'
          ? 'คุณทำ 16/8 ได้ต่อเนื่องและมีตารางชีวิตค่อนข้างสม่ำเสมอ จึงขยับช่วงอดได้อย่างค่อยเป็นค่อยไป'
          : 'ตารางชีวิตที่เปลี่ยนบ่อยอาจทำให้แผนเข้มข้นทำต่อเนื่องยาก จึงแนะนำ 16/8';
    } else {
      plan = _schedule == 'regular' && _reaction == 'comfortable'
          ? '20/4'
          : '18/6';
      reason = plan == '20/4'
          ? 'คุณมีประสบการณ์กับ 18/6 ต่อเนื่อง ตารางชีวิตสม่ำเสมอ และไม่มีอาการผิดปกติ'
          : 'แม้มีประสบการณ์ แต่ 18/6 เหมาะกว่าเมื่อกิจวัตรหรือความสบายระหว่างอดยังไม่คงที่';
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IfRecommendationResultScreen(
          plan: plan,
          reason: reason,
          age: widget.age,
          healthResult: widget.healthResult,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('คำแนะนำ IF')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                children: [
                  Text('ตอบอีกเล็กน้อย',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'เลือกคำตอบที่ตรงกับคุณ เพื่อให้คำแนะนำมีความระมัดระวังมากขึ้น',
                      style: TextStyle(color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 26),
                  const _SectionTitle(number: '1', title: 'ประสบการณ์ทำ IF'),
                  const SizedBox(height: 10),
                  _SelectTile(
                      title: 'ยังไม่เคย หรือทำไม่ถึง 1 เดือน',
                      selected: _experience == 'beginner',
                      onTap: () => setState(() => _experience = 'beginner')),
                  _SelectTile(
                      title: 'ทำ 16/8 ต่อเนื่องอย่างน้อย 1 เดือน',
                      selected: _experience == 'sixteen',
                      onTap: () => setState(() => _experience = 'sixteen')),
                  _SelectTile(
                      title: 'ทำ 18/6 ต่อเนื่องอย่างน้อย 3 เดือน',
                      selected: _experience == 'eighteen',
                      onTap: () => setState(() => _experience = 'eighteen')),
                  const SizedBox(height: 22),
                  const _SectionTitle(number: '2', title: 'ตารางชีวิตของคุณ'),
                  const SizedBox(height: 10),
                  _SelectTile(
                      title: 'เวลานอนและมื้ออาหารค่อนข้างสม่ำเสมอ',
                      selected: _schedule == 'regular',
                      onTap: () => setState(() => _schedule = 'regular')),
                  _SelectTile(
                      title: 'เวลาเปลี่ยนบ่อย หรือทำงานเป็นกะ',
                      selected: _schedule == 'variable',
                      onTap: () => setState(() => _schedule = 'variable')),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                      number: '3', title: 'ความรู้สึกระหว่างอดอาหาร'),
                  const SizedBox(height: 10),
                  _SelectTile(
                      title: 'ยังไม่เคยทำ จึงยังไม่ทราบ',
                      selected: _reaction == 'unknown',
                      onTap: () => setState(() => _reaction = 'unknown')),
                  _SelectTile(
                      title: 'หิวบ้าง แต่ยังทำกิจวัตรได้ตามปกติ',
                      selected: _reaction == 'comfortable',
                      onTap: () => setState(() => _reaction = 'comfortable')),
                  _SelectTile(
                      title: 'เคยเวียนหัว อ่อนแรง หรือหน้ามืด',
                      selected: _reaction == 'unwell',
                      onTap: () => setState(() => _reaction = 'unwell'),
                      warning: true),
                  const SizedBox(height: 22),
                  const _SectionTitle(number: '4', title: 'ตรวจสอบความปลอดภัย'),
                  const SizedBox(height: 8),
                  const Text('เลือกทุกข้อที่ตรงกับคุณ',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 8),
                  _SafetySwitch(
                      title: 'เป็นเบาหวานหรือใช้ยาควบคุมน้ำตาล',
                      value: _diabetesOrMedication,
                      onChanged: (v) =>
                          setState(() => _diabetesOrMedication = v)),
                  _SafetySwitch(
                      title: 'กำลังตั้งครรภ์หรือให้นมบุตร',
                      value: _pregnantOrBreastfeeding,
                      onChanged: (v) =>
                          setState(() => _pregnantOrBreastfeeding = v)),
                  _SafetySwitch(
                      title: 'มีประวัติความผิดปกติด้านการกิน',
                      value: _eatingDisorder,
                      onChanged: (v) => setState(() => _eatingDisorder = v)),
                  _SafetySwitch(
                      title: 'มีโรคไต โรคตับ หรือโรคประจำตัวสำคัญ',
                      value: _kidneyOrLiverCondition,
                      onChanged: (v) =>
                          setState(() => _kidneyOrLiverCondition = v)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton(
                  onPressed: _showRecommendation,
                  child: const Text('ดูแผนที่แนะนำ')),
            ),
          ],
        ),
      ),
    );
  }
}

class IfRecommendationResultScreen extends StatelessWidget {
  const IfRecommendationResultScreen({
    super.key,
    required this.plan,
    required this.reason,
    required this.age,
    required this.healthResult,
  });
  final String? plan;
  final String reason;
  final int age;
  final HealthResult healthResult;

  Future<void> _finish(BuildContext context) async {
    if (plan != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IfScheduleSetupScreen(
            plan: plan!,
            healthResult: healthResult,
            age: age,
          ),
        ),
      );
      return;
    }
    await NotificationService.instance.cancelFastingReminders();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainShell(healthResult: healthResult, age: age),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canFast = plan != null;
    return Scaffold(
      appBar: AppBar(title: const Text('ผลคำแนะนำ')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                    color: canFast ? AppColors.mint : AppColors.orangeSoft,
                    shape: BoxShape.circle),
                child: Icon(
                    canFast
                        ? Icons.auto_awesome_rounded
                        : Icons.health_and_safety_outlined,
                    color: canFast ? AppColors.tealDark : AppColors.orange,
                    size: 45),
              ),
              const SizedBox(height: 24),
              Text(canFast ? 'แผนที่เหมาะกับคุณ' : 'ยังไม่แนะนำให้เริ่ม IF',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
              if (canFast) ...[
                const SizedBox(height: 18),
                Text(plan!,
                    style: const TextStyle(
                        color: AppColors.tealDark,
                        fontSize: 58,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2)),
              ],
              const SizedBox(height: 16),
              Text(reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.6)),
              if (plan == '20/4') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.orangeSoft,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Text(
                      '20/4 เป็นแผนที่จำกัดช่วงรับประทานมาก ควรติดตามพลังงานและสารอาหารให้เพียงพอ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.orange, fontSize: 13)),
                ),
              ],
              const Spacer(),
              FilledButton(
                  onPressed: () => _finish(context),
                  child: Text(canFast
                      ? 'ใช้แผน $plan และเริ่มใช้งาน'
                      : 'เข้าแอปโดยยังไม่เปิด IF')),
              const SizedBox(height: 12),
              const Text(
                  'คำแนะนำนี้เป็นการคัดกรองเบื้องต้น ไม่ใช่คำวินิจฉัยทางการแพทย์',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title});
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.navy, shape: BoxShape.circle),
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800))),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile(
      {required this.title,
      required this.selected,
      required this.onTap,
      this.warning = false});
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? AppColors.orange : AppColors.teal;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? color.withValues(alpha: .09) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: selected ? color : AppColors.border,
                    width: selected ? 2 : 1)),
            child: Row(
              children: [
                Expanded(
                    child: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? color : AppColors.border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SafetySwitch extends StatelessWidget {
  const _SafetySwitch(
      {required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: const TextStyle(fontSize: 14))),
    );
  }
}
