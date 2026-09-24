import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../services/meal_history_service.dart';
import '../theme/app_theme.dart';
import 'food_amount_screen.dart';
import 'food_search_screen.dart';

class FoodComponentsScreen extends StatefulWidget {
  const FoodComponentsScreen({
    super.key,
    required this.parentFood,
    required this.mealType,
    required this.dateKey,
    this.existingEntry,
  });

  final FoodItem parentFood;
  final MealType mealType;
  final String dateKey;
  final MealEntry? existingEntry;

  @override
  State<FoodComponentsScreen> createState() => _FoodComponentsScreenState();
}

class _FoodComponentsScreenState extends State<FoodComponentsScreen> {
  late final List<MealComponent> _components =
      List.of(widget.existingEntry?.components ?? const []);
  bool _reusedPrevious = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousComposition();
  }

  Future<void> _loadPreviousComposition() async {
    if (_components.isNotEmpty || widget.existingEntry != null) return;
    final previous = await MealHistoryService.instance
        .loadLatestDetailedForFood(widget.parentFood.id);
    if (!mounted || previous == null || _components.isNotEmpty) return;
    setState(() {
      _components.addAll(previous.components);
      _reusedPrevious = true;
    });
  }

  MealEntry get _preview => MealEntry.fromComponents(
        parentFood: widget.parentFood,
        mealType: widget.mealType,
        dateKey: widget.dateKey,
        components: _components,
        existingId: widget.existingEntry?.id,
        existingCreatedAt: widget.existingEntry?.createdAt,
      );

  Future<void> _add([String initialQuery = '']) async {
    final food = await Navigator.of(context).push<FoodItem>(MaterialPageRoute(
      builder: (_) => FoodSearchScreen(
        mealType: widget.mealType,
        dateKey: widget.dateKey,
        componentPicker: true,
        initialQuery: initialQuery,
      ),
    ));
    if (food == null || !mounted) return;
    if (food.id == widget.parentFood.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'กรุณาเลือกอาหารย่อย เช่น ข้าวหรือเนื้อไก่ ไม่เลือกเมนูทั้งจานซ้ำ'),
      ));
      return;
    }
    final portion =
        await Navigator.of(context).push<MealEntry>(MaterialPageRoute(
      builder: (_) => FoodAmountScreen(
        food: food,
        initialMealType: widget.mealType,
        dateKey: widget.dateKey,
        draft: true,
      ),
    ));
    if (portion == null || !mounted) return;
    final component = MealComponent.fromFood(food, portion.grams);
    setState(() {
      final existing =
          _components.indexWhere((item) => item.foodId == component.foodId);
      if (existing < 0) {
        _components.add(component);
      } else {
        _components[existing] = MealComponent.fromFood(
            food, _components[existing].grams + component.grams);
      }
      _reusedPrevious = false;
    });
  }

  Future<void> _edit(int index) async {
    final component = _components[index];
    final food = component.toFoodItem();
    final portion =
        await Navigator.of(context).push<MealEntry>(MaterialPageRoute(
      builder: (_) => FoodAmountScreen(
        food: food,
        initialMealType: widget.mealType,
        dateKey: widget.dateKey,
        draft: true,
        initialGrams: component.grams,
      ),
    ));
    if (portion == null || !mounted) return;
    setState(
        () => _components[index] = MealComponent.fromFood(food, portion.grams));
  }

  void _remove(int index) {
    final removed = _components.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('นำ ${removed.foodName} ออกแล้ว'),
      action: SnackBarAction(
        label: 'เลิกทำ',
        onPressed: () => setState(() => _components.insert(
            index.clamp(0, _components.length).toInt(), removed)),
      ),
    ));
  }

  void _save() {
    if (_components.isEmpty) return;
    Navigator.of(context).pop(_preview);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('ปรับส่วนประกอบ')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: _components.isEmpty ? null : _save,
          child: Text(_components.isEmpty
              ? 'เพิ่มส่วนประกอบก่อนบันทึก'
              : 'ใช้ส่วนประกอบ ${_components.length} รายการ'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(widget.parentFood.nameTh,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text(
            'ชั่งเฉพาะส่วนที่รับประทานแล้วเพิ่มทีละรายการ เช่น ข้าว ไก่ และน้ำจิ้ม',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (_reusedPrevious) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Icon(Icons.history, color: AppColors.tealDark),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'นำส่วนประกอบครั้งล่าสุดมาให้แล้ว คุณแก้น้ำหนักก่อนบันทึกได้')),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final query in ['ข้าว', 'ไก่', 'น้ำจิ้ม', 'ผัก'])
              ActionChip(
                avatar: const Icon(Icons.add, size: 17),
                label: Text(query),
                onPressed: () => _add(query),
              ),
          ]),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.search),
            label: const Text('ค้นหาส่วนประกอบอื่น'),
          ),
          const SizedBox(height: 20),
          if (_components.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(children: [
                Icon(Icons.rice_bowl_outlined,
                    size: 40, color: AppColors.tealDark),
                SizedBox(height: 10),
                Text('ยังไม่มีส่วนประกอบ',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text('เริ่มจากข้าวหรือเนื้อสัตว์ที่อยู่ในจาน',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
              ]),
            )
          else ...[
            Text('ส่วนประกอบ', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                for (var index = 0; index < _components.length; index++) ...[
                  ListTile(
                    title: Text(_components[index].foodName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${_components[index].grams.toStringAsFixed(1)} กรัม · ${_components[index].calories.round()} kcal'),
                    onTap: () => _edit(index),
                    trailing: IconButton(
                      tooltip: 'นำออก',
                      onPressed: () => _remove(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                  if (index != _components.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รวมทั้งจาน'),
                    const SizedBox(height: 4),
                    Text('${preview.calories.round()} kcal',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.tealDark)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 14, runSpacing: 6, children: [
                      Text('คาร์บ ${preview.carbs.toStringAsFixed(1)} ก.'),
                      Text('โปรตีน ${preview.protein.toStringAsFixed(1)} ก.'),
                      Text('ไขมัน ${preview.fat.toStringAsFixed(1)} ก.'),
                    ]),
                  ]),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'ผลลัพธ์ขึ้นอยู่กับอาหารที่เลือกและน้ำหนักที่ชั่งได้จริง ค่าจากร้านอาหารยังเป็นค่าประมาณ',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
