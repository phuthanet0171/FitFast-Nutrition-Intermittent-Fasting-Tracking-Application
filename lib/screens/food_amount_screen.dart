import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/food_serving.dart';
import '../models/health_result.dart';
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
    this.healthResult,
  });

  /// Popped instead of a [MealEntry] when the user deletes [existingEntry].
  static const deleteResult = 'delete';

  final FoodItem food;
  final MealType initialMealType;
  final String dateKey;
  final MealEntry? existingEntry;
  final bool draft;
  final double? initialGrams;
  final HealthResult? healthResult;

  @override
  State<FoodAmountScreen> createState() => _FoodAmountScreenState();
}

class _FoodAmountScreenState extends State<FoodAmountScreen> {
  static const _sizeLabels = ['เล็ก', 'ปกติ', 'ใหญ่'];

  late final TextEditingController _quantity;
  List<FoodServing> _units = [];
  FoodServing? _unit;
  int _sizeIndex = 1;
  bool _weighedWithInedible = false;
  MealEntry? _detailedEntry;
  bool _loadingUnits = true;

  double get _amount => double.tryParse(_quantity.text) ?? 0;

  double get _unitGrams {
    final unit = _unit;
    if (unit == null) return 1;
    final sizes = unit.sizeGrams;
    return sizes[_sizeIndex.clamp(0, sizes.length - 1)];
  }

  /// Grams of the edible part, which is what the nutrient values describe.
  double get _grams {
    final grams = _amount * _unitGrams;
    if (_unit == null && _weighedWithInedible && widget.food.hasInediblePart) {
      return grams * widget.food.ediblePortionPercent! / 100;
    }
    return grams;
  }

  bool get _standardValid => _grams.isFinite && _grams >= 1 && _grams <= 5000;
  bool get _valid => _detailedEntry != null || _standardValid;
  bool get _usesDefaultAmount =>
      widget.existingEntry == null && widget.initialGrams == null;

  @override
  void initState() {
    super.initState();
    _detailedEntry =
        widget.existingEntry?.isDetailed == true ? widget.existingEntry : null;
    final initial = widget.existingEntry?.grams ?? widget.initialGrams ?? 100;
    _quantity =
        TextEditingController(text: _formatAmount(initial, grams: true));
    if (widget.food.servings.isNotEmpty) {
      _applyUnits(widget.food.servings);
    } else {
      _loadUnits();
    }
  }

  String _formatAmount(double value, {bool grams = false}) {
    final whole = value == value.roundToDouble();
    return value.toStringAsFixed(whole ? 0 : (grams ? 1 : 2));
  }

  Future<void> _loadUnits() async {
    final units =
        await FoodCatalogService.instance.loadVerifiedServings(widget.food.id);
    if (!mounted) return;
    setState(() => _applyUnits(units));
  }

  void _applyUnits(List<FoodServing> units) {
    _units = FoodServing.sorted(units);
    _loadingUnits = false;
    // People estimate household portions better than grams, so a new entry
    // starts from one default serving when a verified serving exists.
    if (_usesDefaultAmount && _units.isNotEmpty && _unit == null) {
      _unit = _units.first;
      _quantity.text = '1';
    }
  }

  void _selectUnit(FoodServing? unit) {
    setState(() {
      _unit = unit;
      _sizeIndex = 1;
      _quantity.text = unit == null ? '100' : '1';
    });
  }

  void _setAmount(double amount) {
    setState(
        () => _quantity.text = _formatAmount(amount, grams: _unit == null));
  }

  void _step(int direction) {
    final step = _unit == null ? 10.0 : .5;
    final minimum = _unit == null ? 1.0 : .5;
    final current = _amount.isFinite ? _amount : 0;
    _setAmount((current + direction * step).clamp(minimum, 5000).toDouble());
  }

  Future<void> _openComponents() async {
    final entry = await Navigator.of(context).push<MealEntry>(MaterialPageRoute(
      builder: (_) => FoodComponentsScreen(
        parentFood: widget.food,
        mealType: widget.initialMealType,
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
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                  child: const Text('เปลี่ยน')),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) {
      setState(() {
        _detailedEntry = null;
        _unit = _units.isEmpty ? null : _units.first;
        _sizeIndex = 1;
        _quantity.text = _unit == null ? '100' : '1';
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
      mealType: widget.initialMealType,
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
    final food = widget.food;
    final factor = _standardValid ? _grams / 100 : 0.0;
    final nutrition = detailed != null
        ? _Nutrition(
            calories: detailed.calories,
            protein: detailed.protein,
            carbs: detailed.carbs,
            fat: detailed.fat,
            sugar: detailed.hasSugarData ? detailed.sugar : null,
            sodium: detailed.hasSodiumData ? detailed.sodium : null,
          )
        : _Nutrition(
            calories: food.energyKcalPer100g * factor,
            protein: food.proteinGPer100g * factor,
            carbs: food.carbsGPer100g * factor,
            fat: food.fatGPer100g * factor,
            sugar: food.sugarGPer100g == null
                ? null
                : food.sugarGPer100g! * factor,
            sodium: food.sodiumMgPer100g == null
                ? null
                : food.sodiumMgPer100g! * factor,
          );
    final saveLabel = widget.draft
        ? 'ใช้ปริมาณนี้'
        : widget.existingEntry == null
            ? 'บันทึก'
            : 'บันทึกการแก้ไข';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.draft
            ? 'ระบุปริมาณส่วนประกอบ'
            : widget.existingEntry == null
                ? 'บันทึกอาหาร'
                : 'แก้ไขรายการ'),
        actions: [
          if (widget.existingEntry != null && !widget.draft)
            IconButton(
              tooltip: 'ลบรายการนี้',
              onPressed: () =>
                  Navigator.of(context).pop(FoodAmountScreen.deleteResult),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: _valid ? _save : null,
          child: Text(_valid
              ? '$saveLabel · ${nutrition.calories.round()} kcal'
              : saveLabel),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(children: [
            FoodPhoto(url: food.imageUrl, foodCode: food.foodCode, size: 68),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.displayName,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    widget.draft
                        ? '${food.energyKcalPer100g.round()} kcal ต่อ 100 กรัม'
                        : widget.initialMealType.label,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (food.imageUrl != null && food.imageCredit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        food.imageCredit!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 10),
                      ),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          if (detailed == null) ...[
            _buildStandardAmount(context),
            if (!widget.draft) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openComponents,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('แยกส่วนประกอบเพื่อความแม่นยำ'),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'เหมาะกับเมนูหลายส่วน เช่น ข้าวมันไก่ ข้าวราดแกง',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ],
          ] else
            _buildDetailedCard(context, detailed),
          const SizedBox(height: 16),
          _NutritionPanel(
            nutrition: nutrition,
            target: widget.draft ? null : widget.healthResult,
          ),
        ],
      ),
    );
  }

  Widget _buildStandardAmount(BuildContext context) {
    final unit = _unit;
    return _Section(
      title: 'กินไปเท่าไหร่?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_units.isNotEmpty || _loadingUnits) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final serving in _units)
                ChoiceChip(
                  label:
                      Text('${serving.label} · ${serving.isEstimate ? '≈' : ''}'
                          '${_formatAmount(serving.grams)} ก.'),
                  selected: unit?.id == serving.id,
                  onSelected: (_) => _selectUnit(serving),
                ),
              ChoiceChip(
                label: const Text('กรัม'),
                selected: unit == null,
                onSelected: (_) => _selectUnit(null),
              ),
            ]),
            if (_loadingUnits)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 14),
          ],
          if (unit != null && unit.hasSizeRange) ...[
            Text('ขนาด${unit.noun}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final (index, grams) in unit.sizeGrams.indexed)
                    ButtonSegment(
                      value: index,
                      label: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_sizeLabels[index]),
                        Text('${grams.round()} ก.',
                            style: const TextStyle(fontSize: 11)),
                      ]),
                    ),
                ],
                selected: {_sizeIndex},
                onSelectionChanged: (values) =>
                    setState(() => _sizeIndex = values.first),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(children: [
            IconButton.filledTonal(
              tooltip: 'ลดปริมาณ',
              onPressed: () => _step(-1),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _quantity,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: unit == null ? 'กรัม' : 'จำนวน (${unit.noun})',
                  errorText: _standardValid ? null : 'ปริมาณรวม 1–5,000 กรัม',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              tooltip: 'เพิ่มปริมาณ',
              onPressed: () => _step(1),
              icon: const Icon(Icons.add),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (unit == null)
              for (final amount in const <double>[50, 100, 150, 200])
                ActionChip(
                  label: Text('${_formatAmount(amount)} ก.'),
                  onPressed: () => _setAmount(amount),
                )
            else
              for (final (amount, label) in <(double, String)>[
                (.5, 'ครึ่ง${unit.noun}'),
                (1, '1 ${unit.noun}'),
                (1.5, '1½ ${unit.noun}'),
                (2, '2 ${unit.noun}'),
              ])
                ActionChip(
                  label: Text(label),
                  onPressed: () => _setAmount(amount),
                ),
          ]),
          if (unit == null && widget.food.hasInediblePart) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _weighedWithInedible,
              onChanged: (value) =>
                  setState(() => _weighedWithInedible = value),
              title: const Text('น้ำหนักนี้รวมกระดูกหรือเปลือก'),
              subtitle: Text('ระบบจะคิดเฉพาะส่วนที่กินได้ '
                  '${widget.food.ediblePortionPercent!.round()}% ของน้ำหนัก'),
            ),
          ],
          if (unit != null ||
              (_weighedWithInedible && widget.food.hasInediblePart))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _standardValid
                    ? unit == null
                        ? 'ส่วนที่กินได้ ≈ ${_formatAmount(_grams, grams: true)} กรัม'
                        : 'รวม ≈ ${_formatAmount(_grams, grams: true)} กรัม'
                    : 'ตรวจสอบปริมาณที่เลือก',
                style: const TextStyle(
                    color: AppColors.tealDark, fontWeight: FontWeight.w700),
              ),
            ),
          if (unit != null && unit.sourceName != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                unit.isEstimate
                    ? 'ค่าประมาณจากเมนูกลุ่มเดียวกัน · ${unit.sourceName}'
                    : 'ที่มา: ${unit.sourceName}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          if (!_loadingUnits && _units.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'เมนูนี้ยังไม่มีหน่วยจาน/ทัพพีที่มีแหล่งอ้างอิง จึงใช้หน่วยกรัม',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedCard(BuildContext context, MealEntry entry) => _Section(
        title: 'แยกส่วนประกอบ · ${entry.components.length} รายการ',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final component in entry.components)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(component.foodName)),
                Text('${component.grams.toStringAsFixed(1)} ก.',
                    style: const TextStyle(color: AppColors.muted)),
              ]),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openComponents,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('แก้ไขส่วนประกอบ'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _useStandard,
              child: const Text('กลับไปใช้ปริมาณรวมแบบมาตรฐาน'),
            ),
          ),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );
}

class _Nutrition {
  const _Nutrition({
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
}

class _NutritionPanel extends StatelessWidget {
  const _NutritionPanel({required this.nutrition, required this.target});

  final _Nutrition nutrition;
  final HealthResult? target;

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    final share = target == null || target.calories <= 0
        ? null
        : nutrition.calories / target.calories;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('สารอาหารตามปริมาณที่เลือก',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 4),
        Text('${nutrition.calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.tealDark)),
        if (share != null)
          Text(
            'ประมาณ ${(share * 100).round()}% ของพลังงานทั้งวัน '
            '(เป้าหมาย ${target!.calories.round()} kcal)',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        const SizedBox(height: 16),
        _MacroRow(
          label: 'คาร์บ',
          value: nutrition.carbs,
          target: target?.carbs,
          color: AppColors.teal,
        ),
        _MacroRow(
          label: 'โปรตีน',
          value: nutrition.protein,
          target: target?.protein,
          color: AppColors.blue,
        ),
        _MacroRow(
          label: 'ไขมัน',
          value: nutrition.fat,
          target: target?.fat,
          color: AppColors.amber,
        ),
        const Divider(height: 22),
        Row(children: [
          Expanded(
            child: _MinorNutrient(
              label: 'น้ำตาล',
              value: nutrition.sugar,
              unit: 'ก.',
            ),
          ),
          Expanded(
            child: _MinorNutrient(
              label: 'โซเดียม',
              value: nutrition.sodium,
              unit: 'มก.',
            ),
          ),
        ]),
      ]),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final double value;
  final double? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final target = this.target;
    final progress =
        target == null || target <= 0 ? null : (value / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(
            target == null
                ? '${value.toStringAsFixed(1)} ก.'
                : '${value.toStringAsFixed(1)} / ${target.round()} ก.',
            style: const TextStyle(fontSize: 13),
          ),
        ]),
        if (progress != null) ...[
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: color,
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ]),
    );
  }
}

class _MinorNutrient extends StatelessWidget {
  const _MinorNutrient({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(
            value == null
                ? 'ไม่มีข้อมูล'
                : '${value!.toStringAsFixed(value! >= 100 ? 0 : 1)} $unit',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      );
}
