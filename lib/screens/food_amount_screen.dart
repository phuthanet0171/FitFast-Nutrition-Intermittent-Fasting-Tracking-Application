import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/food_serving.dart';
import '../models/meal_entry.dart';
import '../services/food_catalog_service.dart';
import '../theme/app_theme.dart';
import '../widgets/food_photo.dart';
import 'food_components_screen.dart';

class FoodAmountScreen extends StatefulWidget {
  const FoodAmountScreen({
    super.key,
    required this.food,
    required this.initialMealType,
    required this.dateKey,
    this.existingEntry,
    this.draft = false,
    this.initialGrams,
  });

  final FoodItem food;
  final MealType initialMealType;
  final String dateKey;
  final MealEntry? existingEntry;
  final bool draft;
  final double? initialGrams;

  @override
  State<FoodAmountScreen> createState() => _FoodAmountScreenState();
}

class _FoodAmountScreenState extends State<FoodAmountScreen> {
  late final TextEditingController _quantity;
  late final MealType _meal;
  List<FoodServing> _units = [];
  FoodServing? _unit;
  MealEntry? _detailedEntry;
  bool _loadingUnits = true;

  double get _amount => double.tryParse(_quantity.text) ?? 0;
  double get _grams => _amount * (_unit?.grams ?? 1);
  bool get _standardValid => _grams.isFinite && _grams >= 1 && _grams <= 5000;
  bool get _valid => _detailedEntry != null || _standardValid;

  @override
  void initState() {
    super.initState();
    _meal = widget.existingEntry?.mealType ?? widget.initialMealType;
    _detailedEntry =
        widget.existingEntry?.isDetailed == true ? widget.existingEntry : null;
    final initial = widget.existingEntry?.grams ?? widget.initialGrams ?? 100;
    _quantity =
        TextEditingController(text: _formatAmount(initial, grams: true));
    _loadUnits();
  }

  String _formatAmount(double value, {bool grams = false}) {
    final whole = value == value.roundToDouble();
    return value.toStringAsFixed(whole ? 0 : (grams ? 1 : 2));
  }

  Future<void> _loadUnits() async {
    final units =
        await FoodCatalogService.instance.loadVerifiedServings(widget.food.id);
    if (!mounted) return;
    setState(() {
      _units = units
          .where((unit) =>
              unit.grams.isFinite && unit.grams > 0 && unit.grams <= 5000)
          .toList();
      _loadingUnits = false;
    });
  }

  void _setAmount(double amount) {
    setState(
        () => _quantity.text = _formatAmount(amount, grams: _unit == null));
  }

  Future<void> _openComponents() async {
    final entry = await Navigator.of(context).push<MealEntry>(MaterialPageRoute(
      builder: (_) => FoodComponentsScreen(
        parentFood: widget.food,
        mealType: _meal,
        dateKey: widget.dateKey,
        existingEntry: _detailedEntry,
      ),
    ));
    if (entry != null && mounted) {
      setState(() => _detailedEntry = entry);
    }
  }

  Future<void> _useStandard() async {
    if (_detailedEntry == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('เปลี่ยนเป็นแบบมาตรฐาน?'),
            content: const Text(
                'ส่วนประกอบที่ปรับไว้จะถูกนำออก และระบบจะคำนวณจากน้ำหนักรวมของเมนูแทน'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('ยกเลิก')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('เปลี่ยน')),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      setState(() {
        _detailedEntry = null;
        _unit = null;
        _quantity.text = '100';
      });
    }
  }

  void _save() {
    if (!_valid) return;
    if (_detailedEntry case final detailed?) {
      Navigator.of(context).pop(detailed);
      return;
    }
    Navigator.of(context).pop(MealEntry.fromFood(
      food: widget.food,
      mealType: _meal,
      grams: _grams,
      dateKey: widget.dateKey,
      existingId: widget.existingEntry?.id,
      existingCreatedAt: widget.existingEntry?.createdAt,
    ));
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailed = _detailedEntry;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.draft ? 'ระบุปริมาณส่วนประกอบ' : 'บันทึกอาหาร')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: _valid ? _save : null,
          child: Text(widget.draft
              ? 'ใช้ปริมาณนี้'
              : widget.existingEntry == null
                  ? 'บันทึกอาหาร'
                  : 'บันทึกการแก้ไข'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            FoodPhoto(url: widget.food.imageUrl, size: 76),
            const SizedBox(width: 16),
            Expanded(
              child: Text(widget.food.nameTh,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          const SizedBox(height: 16),
          Text('${_meal.label} · ${widget.dateKey}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 22),
          if (detailed == null) ...[
            _buildStandardAmount(context),
            if (!widget.draft) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _openComponents,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('ปรับส่วนประกอบเพื่อความแม่นยำ'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'เหมาะกับอาหารหลายส่วน เช่น ข้าวมันไก่ ข้าวราดแกง หรืออาหารที่ปรับข้าวและเนื้อแยกกัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 22),
            _NutritionSummary(
              calories: widget.food.energyKcalPer100g * _grams / 100,
              protein: widget.food.proteinGPer100g * _grams / 100,
              carbs: widget.food.carbsGPer100g * _grams / 100,
              fat: widget.food.fatGPer100g * _grams / 100,
              sugar: widget.food.sugarGPer100g == null
                  ? null
                  : widget.food.sugarGPer100g! * _grams / 100,
              sodium: widget.food.sodiumMgPer100g == null
                  ? null
                  : widget.food.sodiumMgPer100g! * _grams / 100,
            ),
          ] else ...[
            _buildDetailedCard(context, detailed),
            const SizedBox(height: 18),
            _NutritionSummary(
              calories: detailed.calories,
              protein: detailed.protein,
              carbs: detailed.carbs,
              fat: detailed.fat,
              sugar: detailed.hasSugarData ? detailed.sugar : null,
              sodium: detailed.hasSodiumData ? detailed.sodium : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardAmount(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('กินไปเท่าไหร่?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: -1,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'หน่วยบริโภค'),
            items: [
              const DropdownMenuItem(value: -1, child: Text('กรัม')),
              for (final unit in _units)
                DropdownMenuItem(
                  value: unit.id,
                  child: Text('${unit.label} · ${unit.grams} กรัม',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) {
              setState(() {
                _unit = id == -1
                    ? null
                    : _units.firstWhere((unit) => unit.id == id);
                _quantity.text = _unit == null ? '100' : '1';
              });
            },
          ),
          const SizedBox(height: 16),
          Row(children: [
            IconButton.filledTonal(
              tooltip: 'ลดปริมาณ',
              onPressed: () => _setAmount(
                ((_amount.isFinite ? _amount : 0) - (_unit == null ? 10 : .5))
                    .clamp(_unit == null ? 1 : .5, 5000)
                    .toDouble(),
              ),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _quantity,
                textAlign: TextAlign.center,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'จำนวน',
                  errorText: _standardValid ? null : 'ปริมาณรวม 1–5,000 กรัม',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'เพิ่มปริมาณ',
              onPressed: () => _setAmount(
                ((_amount.isFinite ? _amount : 0) + (_unit == null ? 10 : .5))
                    .clamp(1, 5000)
                    .toDouble(),
              ),
              icon: const Icon(Icons.add),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final amount in (_unit == null
                ? <double>[50, 100, 150, 200]
                : <double>[.5, 1, 1.5, 2]))
              ActionChip(
                label: Text(
                    '${_formatAmount(amount)}${_unit == null ? ' กรัม' : ' หน่วย'}'),
                onPressed: () => _setAmount(amount),
              ),
          ]),
          if (_unit != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_standardValid
                  ? 'น้ำหนักรวม ${_grams.toStringAsFixed(1)} กรัม'
                  : 'ตรวจสอบปริมาณที่เลือก'),
            ),
          if (_loadingUnits)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            )
          else if (_units.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'เมนูนี้ยังไม่มีน้ำหนักต่อช้อน/จานที่ยืนยันแล้ว จึงใช้หน่วยกรัมก่อน',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      );

  Widget _buildDetailedCard(BuildContext context, MealEntry entry) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
              child: Text('บันทึกแบบแยกส่วนประกอบ',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            Text('${entry.components.length} รายการ',
                style: const TextStyle(color: AppColors.tealDark)),
          ]),
          const SizedBox(height: 12),
          for (final component in entry.components)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(component.foodName)),
                Text('${component.grams.toStringAsFixed(1)} ก.'),
              ]),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _openComponents,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('แก้ไขส่วนประกอบ'),
            ),
          ),
          TextButton(
            onPressed: _useStandard,
            child: const Text('กลับไปใช้ปริมาณรวมแบบมาตรฐาน'),
          ),
        ]),
      );
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    required this.sodium,
  });

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sugar;
  final double? sodium;

  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(24),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('สารอาหารตามปริมาณที่เลือก'),
            const SizedBox(height: 8),
            Text('${calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark)),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 8, children: [
              Text('คาร์บ ${carbs.toStringAsFixed(1)} ก.'),
              Text('โปรตีน ${protein.toStringAsFixed(1)} ก.'),
              Text('ไขมัน ${fat.toStringAsFixed(1)} ก.'),
            ]),
          ]),
        ),
        ExpansionTile(
          title: const Text('ดูสารอาหารเพิ่มเติม'),
          children: [
            ListTile(
              title: const Text('น้ำตาล'),
              trailing: Text(sugar == null
                  ? 'ไม่มีข้อมูล'
                  : '${sugar!.toStringAsFixed(1)} ก.'),
            ),
            ListTile(
              title: const Text('โซเดียม'),
              trailing: Text(sodium == null
                  ? 'ไม่มีข้อมูล'
                  : '${sodium!.toStringAsFixed(1)} มก.'),
            ),
          ],
        ),
      ]);
}
