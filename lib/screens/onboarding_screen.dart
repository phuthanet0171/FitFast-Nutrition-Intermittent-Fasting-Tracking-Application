import 'package:flutter/material.dart';

import '../models/nutrition_result.dart';
import '../models/user_profile.dart';
import '../services/nutrition_calculator.dart';
import 'fasting_plan_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _targetWeight = TextEditingController();

  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.sedentary;

  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    _height.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  double? _toDouble(String value) => double.tryParse(value.trim());

  String? _requiredNumber(String? value, {double min = 1, double max = 999}) {
    final number = _toDouble(value ?? '');
    if (number == null) return 'กรุณากรอกเป็นตัวเลข';
    if (number < min || number > max) return 'กรุณากรอกค่าระหว่าง $min - $max';
    return null;
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    final profile = UserProfile(
      age: int.parse(_age.text.trim()),
      gender: _gender,
      currentWeightKg: double.parse(_weight.text.trim()),
      heightCm: double.parse(_height.text.trim()),
      targetWeightKg: double.parse(_targetWeight.text.trim()),
      activityLevel: _activityLevel,
    );

    final NutritionResult nutrition = NutritionCalculator.calculate(profile);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FastingPlanScreen(
          profile: profile,
          nutrition: nutrition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FastWise')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'ข้อมูลพื้นฐานของคุณ',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('ใช้เพื่อประมาณ BMI พลังงาน และสารอาหารต่อวัน'),
              const SizedBox(height: 24),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'อายุ',
                  suffixText: 'ปี',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _requiredNumber(v, min: 18, max: 100),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gender>(
                initialValue: _gender,
                decoration: const InputDecoration(
                  labelText: 'เพศ',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: Gender.male, child: Text('ชาย')),
                  DropdownMenuItem(value: Gender.female, child: Text('หญิง')),
                ],
                onChanged: (value) => setState(() => _gender = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'น้ำหนักปัจจุบัน',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _requiredNumber(v, min: 30, max: 300),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _height,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'ส่วนสูง',
                  suffixText: 'cm',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _requiredNumber(v, min: 120, max: 230),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetWeight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'น้ำหนักเป้าหมาย',
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => _requiredNumber(v, min: 30, max: 300),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ActivityLevel>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(
                  labelText: 'ระดับกิจกรรมประจำวัน',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ActivityLevel.sedentary,
                    child: Text('น้อยมาก / นั่งเป็นส่วนใหญ่'),
                  ),
                  DropdownMenuItem(
                    value: ActivityLevel.light,
                    child: Text('กิจกรรมเบา'),
                  ),
                  DropdownMenuItem(
                    value: ActivityLevel.moderate,
                    child: Text('กิจกรรมปานกลาง'),
                  ),
                  DropdownMenuItem(
                    value: ActivityLevel.veryActive,
                    child: Text('กิจกรรมสูง'),
                  ),
                ],
                onChanged: (value) => setState(() => _activityLevel = value!),
              ),
              const SizedBox(height: 12),
              Text(
                'หมายเหตุ: ค่าพลังงานและสารอาหารเป็นค่าประมาณสำหรับต้นแบบ ไม่ใช่คำแนะนำทางการแพทย์',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _continue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('คำนวณและเลือกแผน IF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
