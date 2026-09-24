import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_nutrition_record.dart';
import '../models/health_result.dart';
import '../services/nutrition_history_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.healthResult,
    this.refreshVersion = 0,
  });

  final HealthResult? healthResult;
  final int refreshVersion;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = _dateOnly(DateTime.now());
  DailyNutritionRecord? _record;
  bool _loading = true;
  Timer? _midnightTimer;

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool get _isToday => _selectedDate == _dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDate(_selectedDate);
    _scheduleMidnightRefresh();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.healthResult != widget.healthResult && _isToday) {
      _loadDate(_selectedDate);
    }
    if (oldWidget.refreshVersion != widget.refreshVersion && _isToday) {
      _loadDate(_selectedDate);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final today = _dateOnly(DateTime.now());
      if (_isToday || _selectedDate.isAfter(today)) {
        _selectedDate = today;
        _loadDate(today);
      }
      _scheduleMidnightRefresh();
    }
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      final today = _dateOnly(DateTime.now());
      setState(() => _selectedDate = today);
      _loadDate(today);
      _scheduleMidnightRefresh();
    });
  }

  Future<void> _loadDate(DateTime date) async {
    setState(() => _loading = true);
    final today = _dateOnly(DateTime.now());
    final record = date == today
        ? await NutritionHistoryService.instance
            .loadOrCreateToday(widget.healthResult)
        : await NutritionHistoryService.instance.load(date);
    if (!mounted || date != _selectedDate) return;
    setState(() {
      _record = record;
      _loading = false;
    });
  }

  Future<void> _chooseDate() async {
    final today = _dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(today) ? today : _selectedDate,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      helpText: 'เลือกวันที่ต้องการดู',
      cancelText: 'ยกเลิก',
      confirmText: 'ดูข้อมูล',
    );
    if (selected == null) return;
    setState(() => _selectedDate = _dateOnly(selected));
    await _loadDate(_selectedDate);
  }

  String _dateLabel(DateTime date) {
    if (date == _dateOnly(DateTime.now())) return 'วันนี้';
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _loadDate(_selectedDate),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isToday
                            ? 'วันนี้ไปให้ถึงเป้าหมายกัน'
                            : 'ประวัติโภชนาการ',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isToday
                            ? 'ข้อมูลวันนี้จะเริ่มใหม่อัตโนมัติเวลา 00:00'
                            : 'ข้อมูลที่บันทึกไว้ในวันที่เลือก',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _chooseDate,
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: Text(_dateLabel(_selectedDate)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(42),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_record == null)
              _NoHistoryCard(
                dateLabel: _dateLabel(_selectedDate),
                onBackToToday: () {
                  final today = _dateOnly(DateTime.now());
                  setState(() => _selectedDate = today);
                  _loadDate(today);
                },
              )
            else
              _EnergyCard(record: _record!, isToday: _isToday),
          ],
        ),
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({required this.record, required this.isToday});

  final DailyNutritionRecord record;
  final bool isToday;

  double _progress(double value, double target) {
    if (target <= 0) return 0;
    return (value / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final calorieProgress = _progress(record.calories, record.calorieTarget);
    final remainingCalories =
        (record.calorieTarget - record.calories).clamp(0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isToday ? 'พลังงานวันนี้' : 'สรุปสารอาหาร',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _DailyStatusBadge(record: record),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: calorieProgress,
                          strokeWidth: 13,
                          backgroundColor: AppColors.border,
                          color: AppColors.orange,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            record.calories > record.calorieTarget
                                ? 'เกินเป้าหมาย'
                                : 'คงเหลือ',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            child: Text(
                              record.calories > record.calorieTarget
                                  ? '${(record.calories - record.calorieTarget).round()}'
                                  : '${remainingCalories.round()}',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 31,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    children: [
                      _EnergyLine(
                        icon: Icons.flag_rounded,
                        label: 'เป้าหมาย',
                        value: '${record.calorieTarget.round()}',
                      ),
                      const SizedBox(height: 18),
                      _EnergyLine(
                        icon: Icons.restaurant_rounded,
                        label: 'อาหาร',
                        value: '${record.calories.round()}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _NutrientBar(
                      width: width,
                      label: 'คาร์บ',
                      consumed: record.carbs,
                      target: record.carbTarget,
                      unit: 'ก.',
                      color: AppColors.teal,
                    ),
                    _NutrientBar(
                      width: width,
                      label: 'โปรตีน',
                      consumed: record.protein,
                      target: record.proteinTarget,
                      unit: 'ก.',
                      color: AppColors.blue,
                    ),
                    _NutrientBar(
                      width: width,
                      label: 'ไขมัน',
                      consumed: record.fat,
                      target: record.fatTarget,
                      unit: 'ก.',
                      color: const Color(0xFFFFC34D),
                    ),
                    _NutrientBar(
                      width: width,
                      label: 'น้ำตาล',
                      consumed: record.sugar,
                      target: record.sugarLimit.clamp(0, 24).toDouble(),
                      unit: 'ก.',
                      color: AppColors.orange,
                      isLimit: true,
                    ),
                    _NutrientBar(
                      width: width,
                      label: 'โซเดียม',
                      consumed: record.sodium,
                      target: record.sodiumLimit,
                      unit: 'มก.',
                      color: const Color(0xFF8C72D9),
                      isLimit: true,
                    ),
                  ],
                );
              },
            ),
            if (!record.sugarDataComplete || !record.sodiumDataComplete) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'อาหารบางรายการไม่มีข้อมูลน้ำตาลหรือโซเดียม '
                        'ยอดรวมวันนี้อาจต่ำกว่าค่าจริง',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            _DailySummary(record: record),
          ],
        ),
      ),
    );
  }
}

class _EnergyLine extends StatelessWidget {
  const _EnergyLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _NutrientBar extends StatelessWidget {
  const _NutrientBar({
    required this.width,
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.color,
    this.isLimit = false,
  });

  final double width;
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final Color color;
  final bool isLimit;

  double get _ratio => target <= 0 ? 0 : consumed / target;

  String get _status {
    if (isLimit) return consumed <= target ? 'อยู่ในเกณฑ์' : 'เกินขีดจำกัด';
    if (consumed == 0) return 'ยังไม่เริ่ม';
    if (_ratio < .9) return 'ยังไม่ถึง';
    if (_ratio <= 1.1) return 'ถึงเป้าหมาย';
    return 'เกินเป้าหมาย';
  }

  @override
  Widget build(BuildContext context) {
    final exceeded = consumed > target;
    final progressColor = exceeded ? AppColors.orange : color;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _status,
                style: TextStyle(
                  color: exceeded ? AppColors.orange : AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _ratio.clamp(0.0, 1.0),
              minHeight: 8,
              color: progressColor,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              '${consumed.round()} / ${target.round()} $unit',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStatusBadge extends StatelessWidget {
  const _DailyStatusBadge({required this.record});

  final DailyNutritionRecord record;

  @override
  Widget build(BuildContext context) {
    final limitsExceeded =
        record.sugar > record.sugarLimit || record.sodium > record.sodiumLimit;
    final reached = record.hasIntake &&
        record.calories >= record.calorieTarget * .9 &&
        record.protein >= record.proteinTarget * .9 &&
        record.carbs >= record.carbTarget * .9 &&
        record.fat >= record.fatTarget * .9 &&
        !limitsExceeded;
    final color = limitsExceeded
        ? AppColors.orange
        : reached
            ? AppColors.teal
            : AppColors.blue;
    final label = limitsExceeded
        ? 'มีค่าเกิน'
        : reached
            ? 'ถึงเป้าหมาย'
            : 'กำลังดำเนินการ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.record});

  final DailyNutritionRecord record;

  @override
  Widget build(BuildContext context) {
    final limitsExceeded =
        record.sugar > record.sugarLimit || record.sodium > record.sodiumLimit;
    final reached = record.hasIntake &&
        record.calories >= record.calorieTarget * .9 &&
        record.protein >= record.proteinTarget * .9 &&
        record.carbs >= record.carbTarget * .9 &&
        record.fat >= record.fatTarget * .9 &&
        !limitsExceeded;

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String message;
    if (!record.hasIntake) {
      icon = Icons.restaurant_menu_rounded;
      color = AppColors.blue;
      title = 'ยังไม่มีข้อมูลอาหาร';
      message = 'เมื่อบันทึกอาหาร ความคืบหน้าจะอัปเดตที่นี่';
    } else if (limitsExceeded) {
      icon = Icons.warning_amber_rounded;
      color = AppColors.orange;
      title = 'มีบางค่าเกินขีดจำกัด';
      message = 'ตรวจสอบน้ำตาลและโซเดียมก่อนเพิ่มมื้อต่อไป';
    } else if (reached) {
      icon = Icons.verified_rounded;
      color = AppColors.teal;
      title = 'ทำถึงเป้าหมายแล้ว';
      message = 'สารอาหารหลักถึงเป้าหมายและค่าจำกัดยังอยู่ในเกณฑ์';
    } else {
      icon = Icons.trending_up_rounded;
      color = AppColors.teal;
      title = 'กำลังไปสู่เป้าหมาย';
      message = 'ดูหลอดด้านบนเพื่อเลือกสารอาหารที่ยังขาดอยู่';
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHistoryCard extends StatelessWidget {
  const _NoHistoryCard({
    required this.dateLabel,
    required this.onBackToToday,
  });

  final String dateLabel;
  final VoidCallback onBackToToday;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 30),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                color: AppColors.muted,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ไม่มีข้อมูลวันที่ $dateLabel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'อาจยังไม่ได้เริ่มบันทึกอาหารในวันนี้',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: onBackToToday,
              icon: const Icon(Icons.today_rounded),
              label: const Text('กลับมาดูวันนี้'),
            ),
          ],
        ),
      ),
    );
  }
}
