import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'main_shell.dart';

class HealthResult {
  const HealthResult({
    required this.bmi,
    required this.bmr,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.sodium,
    required this.recommendedPlan,
    required this.recommendationReason,
    required this.isFastingSuitable,
  });

  final double bmi;
  final double bmr;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final double sodium;
  final String recommendedPlan;
  final String recommendationReason;
  final bool isFastingSuitable;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 58,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Fast Fit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'กินดี • ทำ IF • ไปถึงเป้าหมาย',
                style: TextStyle(
                  color: Color(0xFFD7F5ED),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 42),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = true;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(
          displayName: _isRegister ? _nameController.text.trim() : 'ผู้ใช้งาน',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 30),
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.teal,
                size: 40,
              ),
            ),
            const SizedBox(height: 26),
            Text(
              _isRegister ? 'สร้างบัญชี Fast Fit' : 'ยินดีต้อนรับกลับมา',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isRegister
                  ? 'เริ่มตั้งเป้าหมายสุขภาพที่เหมาะกับคุณ'
                  : 'เข้าสู่ระบบเพื่อดูข้อมูลสุขภาพของคุณ',
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: 'ชื่อที่ต้องการให้แสดง',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกชื่อ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'อีเมล',
                      icon: Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          !value.contains('@')) {
                        return 'กรุณากรอกอีเมลให้ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    decoration: _inputDecoration(
                      label: 'รหัสผ่าน',
                      icon: Icons.lock_outline_rounded,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _continue,
                    child: Text(
                      _isRegister ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isRegister = !_isRegister;
                });
              },
              child: Text(
                _isRegister
                    ? 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'
                    : 'ยังไม่มีบัญชี? สมัครสมาชิก',
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ขณะนี้เป็นหน้าต้นแบบ ยังไม่ได้เชื่อมต่อฐานข้อมูลผู้ใช้',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    super.key,
    required this.displayName,
  });

  final String displayName;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _currentWeightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  String _gender = 'male';
  String _activity = 'light';
  String _experience = 'beginner';

  bool _pregnantOrBreastfeeding = false;
  bool _hasDiabetesOrMedication = false;
  bool _hasEatingDisorderHistory = false;

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  String? _validateNumber(
    String? value, {
    required double minimum,
    required double maximum,
    required String message,
  }) {
    final number = double.tryParse(value ?? '');

    if (number == null || number < minimum || number > maximum) {
      return message;
    }

    return null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final age = int.parse(_ageController.text);
    final height = double.parse(_heightController.text);
    final weight = double.parse(_currentWeightController.text);

    final bmi = weight / pow(height / 100, 2);

    // Mifflin–St Jeor
    final genderValue = _gender == 'male' ? 5 : -161;
    final bmr = (10 * weight) + (6.25 * height) - (5 * age) + genderValue;

    final activityFactor = switch (_activity) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'high' => 1.725,
      _ => 1.2,
    };

    final calories = bmr * activityFactor;

    // สัดส่วนต้นแบบ: คาร์บ 45%, โปรตีน 25%, ไขมัน 30%
    final carbs = (calories * 0.45) / 4;
    final protein = (calories * 0.25) / 4;
    final fat = (calories * 0.30) / 9;

    // น้ำตาลอิสระไม่เกิน 10% ของพลังงาน
    final sugar = ((calories * 0.10) / 4).clamp(0, 24).toDouble();

    const sodium = 2000.0;

    final hasSafetyRisk = age < 18 ||
        bmi < 18.5 ||
        _pregnantOrBreastfeeding ||
        _hasDiabetesOrMedication ||
        _hasEatingDisorderHistory;

    String recommendedPlan;
    String reason;

    if (hasSafetyRisk) {
      recommendedPlan = 'ยังไม่แนะนำให้เริ่ม IF';
      reason =
          'ข้อมูลของคุณมีปัจจัยที่ควรปรึกษาแพทย์หรือนักกำหนดอาหารก่อนเริ่ม IF';
    } else if (_experience == 'beginner') {
      recommendedPlan = '16/8';
      reason =
          'เหมาะสำหรับผู้เริ่มต้น เพราะมีช่วงรับประทาน 8 ชั่วโมงและปรับตัวง่ายกว่า';
    } else if (_experience == 'intermediate') {
      recommendedPlan = '18/6';
      reason =
          'เหมาะกับผู้ที่ทำ 16/8 ได้สม่ำเสมอและต้องการเพิ่มช่วงอดอย่างค่อยเป็นค่อยไป';
    } else {
      recommendedPlan = '20/4';
      reason =
          'เลือกได้สำหรับผู้มีประสบการณ์ แต่เป็นแผนเข้มข้นและควรหยุดเมื่อมีอาการผิดปกติ';
    }

    final result = HealthResult(
      bmi: bmi,
      bmr: bmr,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugar: sugar,
      sodium: sodium,
      recommendedPlan: recommendedPlan,
      recommendationReason: reason,
      isFastingSuitable: !hasSafetyRisk,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HealthResultScreen(
          displayName: widget.displayName,
          result: result,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลสุขภาพ'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Text(
                'มาทำความรู้จักคุณกัน',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'ข้อมูลนี้ใช้ประมาณค่าพลังงานและแนะนำแผนเริ่มต้น',
                style: TextStyle(
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  label: 'อายุ',
                  icon: Icons.cake_outlined,
                  suffix: 'ปี',
                ),
                validator: (value) => _validateNumber(
                  value,
                  minimum: 13,
                  maximum: 100,
                  message: 'กรุณากรอกอายุ 13–100 ปี',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _inputDecoration(
                  label: 'เพศสำหรับใช้คำนวณ BMR',
                  icon: Icons.people_outline_rounded,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'male',
                    child: Text('ชาย'),
                  ),
                  DropdownMenuItem(
                    value: 'female',
                    child: Text('หญิง'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: 'ส่วนสูง',
                  icon: Icons.height_rounded,
                  suffix: 'ซม.',
                ),
                validator: (value) => _validateNumber(
                  value,
                  minimum: 100,
                  maximum: 230,
                  message: 'กรุณากรอกส่วนสูง 100–230 ซม.',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _currentWeightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: 'น้ำหนักปัจจุบัน',
                  icon: Icons.monitor_weight_outlined,
                  suffix: 'กก.',
                ),
                validator: (value) => _validateNumber(
                  value,
                  minimum: 30,
                  maximum: 300,
                  message: 'กรุณากรอกน้ำหนัก 30–300 กก.',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _targetWeightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  label: 'น้ำหนักเป้าหมาย',
                  icon: Icons.flag_outlined,
                  suffix: 'กก.',
                ),
                validator: (value) => _validateNumber(
                  value,
                  minimum: 30,
                  maximum: 300,
                  message: 'กรุณากรอกน้ำหนักเป้าหมาย 30–300 กก.',
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration: _inputDecoration(
                  label: 'ระดับกิจกรรม',
                  icon: Icons.directions_walk_rounded,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'sedentary',
                    child: Text('น้อย — นั่งทำงานเป็นส่วนใหญ่'),
                  ),
                  DropdownMenuItem(
                    value: 'light',
                    child: Text('เบา — ออกกำลังกาย 1–3 วัน/สัปดาห์'),
                  ),
                  DropdownMenuItem(
                    value: 'moderate',
                    child: Text('ปานกลาง — 3–5 วัน/สัปดาห์'),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text('สูง — 6–7 วัน/สัปดาห์'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _activity = value!;
                  });
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _experience,
                decoration: _inputDecoration(
                  label: 'ประสบการณ์ทำ IF',
                  icon: Icons.timer_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'beginner',
                    child: Text('ยังไม่เคย หรือเพิ่งเริ่ม'),
                  ),
                  DropdownMenuItem(
                    value: 'intermediate',
                    child: Text('เคยทำ 16/8 สม่ำเสมอ'),
                  ),
                  DropdownMenuItem(
                    value: 'experienced',
                    child: Text('มีประสบการณ์มากกว่า 6 เดือน'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _experience = value!;
                  });
                },
              ),
              const SizedBox(height: 26),
              Text(
                'ตรวจสอบความเหมาะสมก่อนเริ่ม IF',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'เลือกเฉพาะข้อที่ตรงกับคุณ',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              _SafetySwitch(
                title: 'กำลังตั้งครรภ์หรือให้นมบุตร',
                value: _pregnantOrBreastfeeding,
                onChanged: (value) {
                  setState(() {
                    _pregnantOrBreastfeeding = value;
                  });
                },
              ),
              _SafetySwitch(
                title: 'เป็นเบาหวานหรือใช้ยาควบคุมน้ำตาล',
                value: _hasDiabetesOrMedication,
                onChanged: (value) {
                  setState(() {
                    _hasDiabetesOrMedication = value;
                  });
                },
              ),
              _SafetySwitch(
                title: 'มีประวัติความผิดปกติด้านการกิน',
                value: _hasEatingDisorderHistory,
                onChanged: (value) {
                  setState(() {
                    _hasEatingDisorderHistory = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _calculate,
                child: const Text('คำนวณเป้าหมายของฉัน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthResultScreen extends StatefulWidget {
  const HealthResultScreen({
    super.key,
    required this.displayName,
    required this.result,
  });

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
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'เลือกเวลาเริ่มอดอาหาร',
      confirmText: 'ยืนยัน',
      cancelText: 'ยกเลิก',
    );

    if (selected != null) {
      setState(() {
        _startTime = selected;
      });
    }
  }

  void _openDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainShell(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เป้าหมายสุขภาพ'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Text(
              'แผนของ ${widget.displayName} พร้อมแล้ว',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ResultValue(
                            label: 'BMI',
                            value: result.bmi.toStringAsFixed(1),
                          ),
                        ),
                        Expanded(
                          child: _ResultValue(
                            label: 'BMR',
                            value: '${result.bmr.round()} kcal',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 30),
                    _ResultValue(
                      label: 'พลังงานที่ควรได้รับต่อวัน',
                      value: '${result.calories.round()} kcal',
                      large: true,
                    ),
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
                    _NutrientRow(
                      label: 'โปรตีน',
                      value: '${result.protein.round()} กรัม',
                    ),
                    _NutrientRow(
                      label: 'คาร์โบไฮเดรต',
                      value: '${result.carbs.round()} กรัม',
                    ),
                    _NutrientRow(
                      label: 'ไขมัน',
                      value: '${result.fat.round()} กรัม',
                    ),
                    _NutrientRow(
                      label: 'น้ำตาลสูงสุด',
                      value: '${result.sugar.round()} กรัม',
                    ),
                    _NutrientRow(
                      label: 'โซเดียมสูงสุด',
                      value: '${result.sodium.round()} มก.',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'แผน IF ที่แนะนำ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                        : AppColors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.recommendedPlan,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          result.recommendationReason,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.5,
                          ),
                        ),
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
                    onTap: () {
                      setState(() {
                        _selectedPlan = plan;
                      });
                    },
                    leading: Icon(
                      _selectedPlan == plan
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: AppColors.teal,
                    ),
                    title: Text(
                      plan,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      switch (plan) {
                        '16/8' => 'เหมาะสำหรับผู้เริ่มต้น',
                        '18/6' => 'สำหรับผู้ที่ปรับตัวกับ 16/8 ได้แล้ว',
                        _ => 'แผนเข้มข้นสำหรับผู้มีประสบการณ์',
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: ListTile(
                  onTap: _selectTime,
                  leading: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.teal,
                  ),
                  title: const Text('เวลาเริ่มอดอาหาร'),
                  subtitle: Text(
                    _startTime.format(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _openDashboard,
              child: Text(
                result.isFastingSuitable
                    ? 'ยืนยันแผนและไปหน้า Dashboard'
                    : 'ไปหน้า Dashboard โดยยังไม่เปิด IF',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ค่าที่แสดงเป็นค่าประมาณสำหรับช่วยวางแผนทั่วไป ไม่ใช่การวินิจฉัยหรือคำแนะนำทางการแพทย์',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetySwitch extends StatelessWidget {
  const _SafetySwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

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
        title: Text(
          title,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({
    required this.label,
    required this.value,
    this.large = false,
  });

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.navy,
            fontSize: large ? 28 : 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (showDivider) const Divider(height: 24),
      ],
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required IconData icon,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixText: suffix,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}
