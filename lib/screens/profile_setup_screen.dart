import 'package:flutter/material.dart';

import '../services/health_calculator.dart';
import '../theme/app_theme.dart';
import 'health_result_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.displayName});
  final String displayName;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _targetWeight = TextEditingController();
  String _gender = 'male';
  String _activity = 'light';
  String _experience = 'beginner';
  bool _pregnant = false;
  bool _diabetes = false;
  bool _eatingDisorder = false;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  String? _number(String? value, double min, double max, String message) {
    final parsed = double.tryParse(value ?? '');
    return parsed == null || parsed < min || parsed > max ? message : null;
  }

  InputDecoration _decoration(String label, IconData icon, [String? suffix]) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      );

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    final result = HealthCalculator.calculate(
      age: int.parse(_age.text),
      gender: _gender,
      height: double.parse(_height.text),
      weight: double.parse(_weight.text),
      activity: _activity,
      experience: _experience,
      pregnantOrBreastfeeding: _pregnant,
      hasDiabetesOrMedication: _diabetes,
      hasEatingDisorderHistory: _eatingDisorder,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HealthResultScreen(displayName: widget.displayName, result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลสุขภาพ')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Text('มาทำความรู้จักคุณกัน',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('ข้อมูลนี้ใช้ประมาณค่าพลังงานและแนะนำแผนเริ่มต้น',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: _decoration('อายุ', Icons.cake_outlined, 'ปี'),
                validator: (v) =>
                    _number(v, 13, 100, 'กรุณากรอกอายุ 13–100 ปี'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _decoration(
                    'เพศสำหรับใช้คำนวณ BMR', Icons.people_outline_rounded),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('ชาย')),
                  DropdownMenuItem(value: 'female', child: Text('หญิง')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _height,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration('ส่วนสูง', Icons.height_rounded, 'ซม.'),
                validator: (v) =>
                    _number(v, 100, 230, 'กรุณากรอกส่วนสูง 100–230 ซม.'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration(
                    'น้ำหนักปัจจุบัน', Icons.monitor_weight_outlined, 'กก.'),
                validator: (v) =>
                    _number(v, 30, 300, 'กรุณากรอกน้ำหนัก 30–300 กก.'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _targetWeight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    _decoration('น้ำหนักเป้าหมาย', Icons.flag_outlined, 'กก.'),
                validator: (v) =>
                    _number(v, 30, 300, 'กรุณากรอกน้ำหนักเป้าหมาย 30–300 กก.'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration:
                    _decoration('ระดับกิจกรรม', Icons.directions_walk_rounded),
                items: const [
                  DropdownMenuItem(
                      value: 'sedentary',
                      child: Text('น้อย — นั่งทำงานเป็นส่วนใหญ่')),
                  DropdownMenuItem(
                      value: 'light',
                      child: Text('เบา — ออกกำลังกาย 1–3 วัน/สัปดาห์')),
                  DropdownMenuItem(
                      value: 'moderate',
                      child: Text('ปานกลาง — 3–5 วัน/สัปดาห์')),
                  DropdownMenuItem(
                      value: 'high', child: Text('สูง — 6–7 วัน/สัปดาห์')),
                ],
                onChanged: (v) => setState(() => _activity = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _experience,
                decoration:
                    _decoration('ประสบการณ์ทำ IF', Icons.timer_outlined),
                items: const [
                  DropdownMenuItem(
                      value: 'beginner',
                      child: Text('ยังไม่เคย หรือเพิ่งเริ่ม')),
                  DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('เคยทำ 16/8 สม่ำเสมอ')),
                  DropdownMenuItem(
                      value: 'experienced',
                      child: Text('มีประสบการณ์มากกว่า 6 เดือน')),
                ],
                onChanged: (v) => setState(() => _experience = v!),
              ),
              const SizedBox(height: 26),
              Text('ตรวจสอบความเหมาะสมก่อนเริ่ม IF',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _SafetySwitch(
                title: 'กำลังตั้งครรภ์หรือให้นมบุตร',
                value: _pregnant,
                onChanged: (v) => setState(() => _pregnant = v),
              ),
              _SafetySwitch(
                title: 'เป็นเบาหวานหรือใช้ยาควบคุมน้ำตาล',
                value: _diabetes,
                onChanged: (v) => setState(() => _diabetes = v),
              ),
              _SafetySwitch(
                title: 'มีประวัติความผิดปกติด้านการกิน',
                value: _eatingDisorder,
                onChanged: (v) => setState(() => _eatingDisorder = v),
              ),
              const SizedBox(height: 22),
              FilledButton(
                  onPressed: _calculate,
                  child: const Text('คำนวณเป้าหมายของฉัน')),
            ],
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
