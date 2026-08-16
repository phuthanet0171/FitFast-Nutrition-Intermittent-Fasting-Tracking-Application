import 'package:flutter/material.dart';

import '../services/health_calculator.dart';
import '../theme/app_theme.dart';
import 'health_summary_screen.dart';

class HealthOnboardingScreen extends StatefulWidget {
  const HealthOnboardingScreen({super.key});

  @override
  State<HealthOnboardingScreen> createState() => _HealthOnboardingScreenState();
}

class _HealthOnboardingScreenState extends State<HealthOnboardingScreen> {
  static const _stepCount = 5;
  final _pageController = PageController();
  int _step = 0;
  int _age = 25;
  String _gender = 'male';
  double _height = 170;
  double _currentWeight = 70;
  double _targetWeight = 65;
  String _activity = 'light';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final result = HealthCalculator.calculate(
      age: _age,
      gender: _gender,
      height: _height,
      weight: _currentWeight,
      activity: _activity,
      experience: 'beginner',
      pregnantOrBreastfeeding: false,
      hasDiabetesOrMedication: false,
      hasEatingDisorderHistory: false,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthSummaryScreen(
          age: _age,
          height: _height,
          currentWeight: _currentWeight,
          targetWeight: _targetWeight,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _stepCount,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '${_step + 1}/$_stepCount',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AgeStep(
                    value: _age,
                    onChanged: (value) => setState(() => _age = value),
                  ),
                  _GenderStep(
                    value: _gender,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  _HeightStep(
                    value: _height,
                    onChanged: (value) => setState(() => _height = value),
                  ),
                  _WeightStep(
                    currentWeight: _currentWeight,
                    targetWeight: _targetWeight,
                    onCurrentChanged: (value) =>
                        setState(() => _currentWeight = value),
                    onTargetChanged: (value) =>
                        setState(() => _targetWeight = value),
                  ),
                  _ActivityStep(
                    value: _activity,
                    onChanged: (value) => setState(() => _activity = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: FilledButton(
                onPressed: _next,
                child: Text(
                    _step == _stepCount - 1 ? 'คำนวณเป้าหมายของฉัน' : 'ถัดไป'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AppColors.mint, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.tealDark, size: 32),
          ),
          const SizedBox(height: 22),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 9),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 38),
          child,
        ],
      ),
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      icon: Icons.cake_outlined,
      title: 'คุณอายุเท่าไร?',
      description: 'อายุช่วยให้เราประเมินพลังงานพื้นฐานได้เหมาะสมขึ้น',
      child: _SliderCard(
        valueText: '$value',
        unit: 'ปี',
        child: Slider(
          value: value.toDouble(),
          min: 18,
          max: 80,
          divisions: 62,
          label: '$value ปี',
          onChanged: (newValue) => onChanged(newValue.round()),
        ),
      ),
    );
  }
}

class _GenderStep extends StatelessWidget {
  const _GenderStep({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      icon: Icons.people_alt_outlined,
      title: 'เลือกเพศของคุณ',
      description: 'ข้อมูลนี้ใช้เฉพาะในการคำนวณ BMR ตามสูตรมาตรฐาน',
      child: Row(
        children: [
          Expanded(
            child: _ChoiceCard(
              icon: Icons.male_rounded,
              title: 'ชาย',
              selected: value == 'male',
              onTap: () => onChanged('male'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ChoiceCard(
              icon: Icons.female_rounded,
              title: 'หญิง',
              selected: value == 'female',
              onTap: () => onChanged('female'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeightStep extends StatelessWidget {
  const _HeightStep({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      icon: Icons.height_rounded,
      title: 'ส่วนสูงของคุณ',
      description: 'เลื่อนเพื่อเลือกส่วนสูง โดยไม่ต้องพิมพ์ตัวเลข',
      child: _SliderCard(
        valueText: value.round().toString(),
        unit: 'ซม.',
        child: Slider(
          value: value,
          min: 130,
          max: 210,
          divisions: 80,
          label: '${value.round()} ซม.',
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _WeightStep extends StatelessWidget {
  const _WeightStep({
    required this.currentWeight,
    required this.targetWeight,
    required this.onCurrentChanged,
    required this.onTargetChanged,
  });

  final double currentWeight;
  final double targetWeight;
  final ValueChanged<double> onCurrentChanged;
  final ValueChanged<double> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      icon: Icons.monitor_weight_outlined,
      title: 'เป้าหมายน้ำหนักของคุณ',
      description: 'เลือกน้ำหนักปัจจุบันและน้ำหนักที่ต้องการไปให้ถึง',
      child: Column(
        children: [
          _CompactSliderCard(
            label: 'น้ำหนักปัจจุบัน',
            value: currentWeight,
            onChanged: onCurrentChanged,
          ),
          const SizedBox(height: 14),
          _CompactSliderCard(
            label: 'น้ำหนักเป้าหมาย',
            value: targetWeight,
            color: AppColors.orange,
            onChanged: onTargetChanged,
          ),
        ],
      ),
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        'sedentary',
        Icons.chair_alt_outlined,
        'กิจกรรมน้อย',
        'นั่งทำงานเป็นส่วนใหญ่ ไม่ค่อยออกกำลังกาย'
      ),
      (
        'light',
        Icons.directions_walk_rounded,
        'กิจกรรมเบา',
        'ออกกำลังกายประมาณ 1–3 วันต่อสัปดาห์'
      ),
      (
        'moderate',
        Icons.directions_run_rounded,
        'กิจกรรมปานกลาง',
        'ออกกำลังกายประมาณ 3–5 วันต่อสัปดาห์'
      ),
      (
        'high',
        Icons.fitness_center_rounded,
        'กิจกรรมสูง',
        'ออกกำลังกายหนักประมาณ 6–7 วันต่อสัปดาห์'
      ),
    ];

    return _StepLayout(
      icon: Icons.bolt_rounded,
      title: 'คุณเคลื่อนไหวมากแค่ไหน?',
      description: 'เลือกระดับที่ใกล้เคียงกับชีวิตประจำวันมากที่สุด',
      child: Column(
        children: options.map((option) {
          final selected = value == option.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: selected ? AppColors.mint : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onChanged(option.$1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected ? AppColors.teal : AppColors.border,
                        width: selected ? 2 : 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: selected ? Colors.white : AppColors.surface,
                            borderRadius: BorderRadius.circular(15)),
                        child: Icon(option.$2,
                            color: selected
                                ? AppColors.tealDark
                                : AppColors.muted),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option.$3,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(option.$4,
                                style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    height: 1.35)),
                          ],
                        ),
                      ),
                      Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: selected ? AppColors.teal : AppColors.border),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard(
      {required this.valueText, required this.unit, required this.child});
  final String valueText;
  final String unit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(valueText,
                    style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: AppColors.navy,
                        height: 1)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(unit,
                      style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _CompactSliderCard extends StatelessWidget {
  const _CompactSliderCard(
      {required this.label,
      required this.value,
      required this.onChanged,
      this.color = AppColors.teal});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${value.toStringAsFixed(1)} กก.',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w900)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context)
                  .copyWith(activeTrackColor: color, thumbColor: color),
              child: Slider(
                value: value,
                min: 40,
                max: 180,
                divisions: 280,
                label: '${value.toStringAsFixed(1)} กก.',
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(
      {required this.icon,
      required this.title,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 176,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: selected ? AppColors.teal : AppColors.border,
                width: selected ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 56,
                  color: selected ? AppColors.tealDark : AppColors.muted),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
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
