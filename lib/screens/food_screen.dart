import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../models/meal_entry.dart';
import '../services/meal_history_service.dart';
import '../services/nutrition_history_service.dart';
import '../theme/app_theme.dart';
import 'food_amount_screen.dart';
import 'food_search_screen.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen(
      {super.key, this.healthResult, required this.onNutritionChanged});

  final HealthResult? healthResult;
  final VoidCallback onNutritionChanged;

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  List<MealEntry> _entries = [];
  bool _loading = true;

  String get _todayKey => NutritionHistoryService.dateKey(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await MealHistoryService.instance.loadDate(_todayKey);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _add(MealType mealType) async {
    final entry = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
          builder: (_) =>
              FoodSearchScreen(mealType: mealType, dateKey: _todayKey)),
    );
    if (entry == null) return;
    await MealHistoryService.instance.add(entry);
    await _syncDashboard();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('บันทึก ${entry.foodName} แล้ว')));
  }

  Future<void> _delete(MealEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('ลบรายการอาหาร?'),
            content: Text('ต้องการลบ “${entry.foodName}” เท่านั้นใช่ไหม'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('ยกเลิก')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('ลบ')),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    await MealHistoryService.instance.delete(entry);
    await _syncDashboard();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ลบ ${entry.foodName} แล้ว')),
    );
  }

  Future<void> _edit(MealEntry entry) async {
    final updated = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
        builder: (_) => FoodAmountScreen(
          food: entry.toFoodItem(),
          initialMealType: entry.mealType,
          dateKey: entry.dateKey,
          existingEntry: entry,
        ),
      ),
    );
    if (updated == null) return;
    await MealHistoryService.instance.update(updated);
    await _syncDashboard();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('แก้ไข ${updated.foodName} แล้ว')),
    );
  }

  Future<void> _syncDashboard() async {
    final entries = await MealHistoryService.instance.loadDate(_todayKey);
    await NutritionHistoryService.instance.replaceIntake(
      date: DateTime.now(),
      healthResult: widget.healthResult,
      calories: entries.fold<double>(0, (sum, item) => sum + item.calories),
      protein: entries.fold<double>(0, (sum, item) => sum + item.protein),
      carbs: entries.fold<double>(0, (sum, item) => sum + item.carbs),
      fat: entries.fold<double>(0, (sum, item) => sum + item.fat),
      sugar: entries.fold<double>(0, (sum, item) => sum + item.sugar),
      sodium: entries.fold<double>(0, (sum, item) => sum + item.sodium),
      sugarDataComplete: entries.every((item) => item.hasSugarData),
      sodiumDataComplete: entries.every((item) => item.hasSodiumData),
    );
    widget.onNutritionChanged();
  }

  List<MealEntry> _forMeal(MealType type) =>
      _entries.where((entry) => entry.mealType == type).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
          children: [
            Text('มื้ออาหารวันนี้',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 7),
            const Text('เลือกมื้อ ค้นหาอาหาร และระบุปริมาณที่รับประทาน',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()))
            else ...[
              _MealCard(
                  type: MealType.breakfast,
                  icon: Icons.free_breakfast_rounded,
                  color: const Color(0xFFFFB84D),
                  entries: _forMeal(MealType.breakfast),
                  onAdd: () => _add(MealType.breakfast),
                  onEdit: _edit,
                  onDelete: _delete),
              const SizedBox(height: 12),
              _MealCard(
                  type: MealType.lunch,
                  icon: Icons.rice_bowl_rounded,
                  color: AppColors.orange,
                  entries: _forMeal(MealType.lunch),
                  onAdd: () => _add(MealType.lunch),
                  onEdit: _edit,
                  onDelete: _delete),
              const SizedBox(height: 12),
              _MealCard(
                  type: MealType.dinner,
                  icon: Icons.dinner_dining_rounded,
                  color: AppColors.teal,
                  entries: _forMeal(MealType.dinner),
                  onAdd: () => _add(MealType.dinner),
                  onEdit: _edit,
                  onDelete: _delete),
              const SizedBox(height: 12),
              _MealCard(
                  type: MealType.snack,
                  icon: Icons.cookie_outlined,
                  color: AppColors.blue,
                  entries: _forMeal(MealType.snack),
                  onAdd: () => _add(MealType.snack),
                  onEdit: _edit,
                  onDelete: _delete),
            ],
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard(
      {required this.type,
      required this.icon,
      required this.color,
      required this.entries,
      required this.onAdd,
      required this.onEdit,
      required this.onDelete});

  final MealType type;
  final IconData icon;
  final Color color;
  final List<MealEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<MealEntry> onEdit;
  final ValueChanged<MealEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final calories =
        entries.fold<double>(0, (sum, item) => sum + item.calories);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(type.label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                      entries.isEmpty
                          ? 'ยังไม่ได้บันทึก'
                          : '${entries.length} รายการ · ${calories.round()} kcal',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ])),
            IconButton.filledTonal(
                onPressed: onAdd,
                tooltip: 'เพิ่มอาหาร',
                icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 10),
          if (entries.isNotEmpty) ...[
            const Divider(height: 25),
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(entry.foodName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                              entry.isDetailed
                                  ? '${entry.components.length} ส่วนประกอบ · ${entry.calories.round()} kcal'
                                  : '${entry.grams.round()} ก. · ${entry.calories.round()} kcal',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12)),
                        ])),
                    IconButton(
                        onPressed: () => onEdit(entry),
                        tooltip: 'แก้ไขรายการ',
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.tealDark)),
                    IconButton(
                        onPressed: () => onDelete(entry),
                        tooltip: 'ลบรายการ',
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.muted)),
                  ]),
                )),
          ],
        ]),
      ),
    );
  }
}
