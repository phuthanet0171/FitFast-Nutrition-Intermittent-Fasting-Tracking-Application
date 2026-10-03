import 'package:flutter/material.dart';

import '../models/food_item.dart';
import '../models/food_serving.dart';
import '../models/health_result.dart';
import '../models/meal_entry.dart';
import '../models/plate_order.dart';
import '../services/food_catalog_service.dart';
import '../services/household_units.dart';
import '../services/plate_order_calculator.dart';
import '../theme/app_theme.dart';
import '../widgets/food_photo.dart';
import 'food_components_screen.dart';

/// Chooses how much of one food was eaten, in household units (ฟอง, ทัพพี,
/// จาน) rather than grams, and for rice plates the way it was ordered.
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

  /// Choosing one component of a dish: only the amount is asked for.
  final bool draft;
  final double? initialGrams;
  final HealthResult? healthResult;

  @override
  State<FoodAmountScreen> createState() => _FoodAmountScreenState();
}

class _FoodAmountScreenState extends State<FoodAmountScreen> {
  final _quantity = TextEditingController();

  /// Nutrients per 100 g. For an edited entry this is its saved snapshot,
  /// or the catalogue dish when an ordered plate is recalculated.
  late FoodItem _food;
  late FoodItem _unitSource;
  List<FoodServing> _units = const [];
  FoodServing? _unit;
  int _size = 1;
  bool _touched = false;

  /// Components the user listed by hand.
  MealEntry? _customEntry;
  PlateOrder _order = const PlateOrder();
  PlateOrder? _savedOrder;
  final _eggs = <EggStyle, FoodItem>{};

  double get _amount => double.tryParse(_quantity.text.trim()) ?? 0;

  double get _unitGrams {
    final unit = _unit;
    if (unit == null) return 1;
    final sizes = unit.sizeGrams;
    return sizes[_size.clamp(0, sizes.length - 1)];
  }

  double get _grams => _amount * _unitGrams;
  bool get _validAmount => _grams.isFinite && _grams >= 1 && _grams <= 5000;

  /// Mixed dishes can be broken into components; single foods cannot.
  bool get _isDish =>
      const {'T', 'DOH11', 'DOH14', 'S'}
          .contains(HouseholdUnits.foodGroup(_food.foodCode)) ||
      PlateOrderCalculator.isRicePlate(_food, _unit);

  bool get _ricePlate =>
      !widget.draft &&
      _customEntry == null &&
      PlateOrderCalculator.isRicePlate(_food, _unit);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    final catalog = FoodCatalogService.instance.cachedFood(widget.food.id);
    final sameFood =
        catalog != null && catalog.foodCode == widget.food.foodCode;
    _food = widget.food;
    final order = existing?.plateOrder;
    if (order != null && sameFood) {
      _food = catalog;
      _savedOrder = order;
    } else if (existing?.isDetailed == true) {
      _customEntry = existing;
    }
    _unitSource =
        widget.food.servings.isNotEmpty || !sameFood ? widget.food : catalog;
    _units = HouseholdUnits.forFood(_unitSource);
    _restore();
    if (_unitSource.servings.isEmpty) _loadMeasuredUnits();
    _loadPlateFoods();
  }

  /// Shows the saved amount in the unit it was logged in, or one default
  /// unit for a new entry.
  void _restore() {
    final order = _savedOrder;
    if (order != null) {
      _unit =
          _units.where((unit) => unit.label == order.unitLabel).firstOrNull ??
              _units.where((unit) => unit.shortNoun == 'จาน').firstOrNull;
      _size = order.size;
      _order = order;
      _setQuantity(order.amount);
      return;
    }
    final grams = widget.existingEntry?.grams ?? widget.initialGrams;
    if (grams == null) {
      _unit = _units.firstOrNull;
      _size = 1;
      _setQuantity(_unit == null ? 100 : 1);
      return;
    }
    final found = HouseholdUnits.match(_units, grams);
    _unit = found?.unit;
    _size = found?.size ?? 1;
    _setQuantity(found?.amount ?? grams);
  }

  void _setQuantity(double value) {
    _quantity.text = HouseholdUnits.formatNumber(
        _unit == null ? (value * 10).round() / 10 : value);
  }

  Future<void> _loadMeasuredUnits() async {
    final measured =
        await FoodCatalogService.instance.loadVerifiedServings(_unitSource.id);
    if (!mounted || measured.isEmpty) return;
    setState(() {
      _units = HouseholdUnits.forFood(_unitSource, measured: measured);
      if (!_touched) _restore();
    });
  }

  Future<void> _loadPlateFoods() async {
    if (widget.draft || _customEntry != null) return;
    final plate = _units.where((unit) => unit.shortNoun == 'จาน').firstOrNull;
    if (!PlateOrderCalculator.isRicePlate(_food, plate)) return;
    final catalog = FoodCatalogService.instance;
    final eggs = <EggStyle, FoodItem>{
      for (final style in EggStyle.values)
        if (await catalog.foodByCode(style.foodCode) case final egg?)
          style: egg,
    };
    if (!mounted) return;
    setState(() => _eggs.addAll(eggs));
  }

  void _change(VoidCallback update) => setState(() {
        _touched = true;
        update();
      });

  void _selectUnit(FoodServing? unit) => _change(() {
        _unit = unit;
        _size = 1;
        _setQuantity(unit == null ? 100 : 1);
      });

  void _step(int direction) => _change(() {
        final step = _unit == null ? 10.0 : .5;
        final current = _amount.isFinite ? _amount : 0.0;
        final next = ((current / step).round() + direction) * step;
        _setQuantity(next.clamp(step, 5000).toDouble());
      });

  MealEntry? get _preview {
    if (_customEntry case final custom?) return custom;
    if (!_validAmount) return null;
    final existing = widget.existingEntry;
    if (_ricePlate) {
      return PlateOrderCalculator.build(
        dish: _food,
        plateGrams: _unitGrams,
        order: _order.copyWith(
            unitLabel: _unit!.label, size: _size, amount: _amount),
        egg: _order.egg == null ? null : _eggs[_order.egg],
        mealType: widget.initialMealType,
        dateKey: widget.dateKey,
        existingId: existing?.id,
        existingCreatedAt: existing?.createdAt,
      );
    }
    return MealEntry.fromFood(
      food: _food,
      mealType: widget.initialMealType,
      grams: _grams,
      dateKey: widget.dateKey,
      existingId: existing?.id,
      existingCreatedAt: existing?.createdAt,
    );
  }

  Future<void> _openComponents() async {
    final entry = await Navigator.of(context).push<MealEntry>(MaterialPageRoute(
      builder: (_) => FoodComponentsScreen(
        parentFood: _food,
        mealType: widget.initialMealType,
        dateKey: widget.dateKey,
        existingEntry: _customEntry,
      ),
    ));
    if (entry != null && mounted) setState(() => _customEntry = entry);
  }

  Future<void> _useStandard() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('กลับไปใช้แบบปกติ?'),
            content: const Text(
                'ส่วนประกอบที่ระบุไว้จะถูกนำออก แล้วเลือกปริมาณของเมนูนี้แทน'),
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
    if (!confirmed || !mounted) return;
    setState(() {
      _customEntry = null;
      _unit = _units.firstOrNull;
      _size = 1;
      _setQuantity(_unit == null ? 100 : 1);
    });
    _loadPlateFoods();
  }

  void _showPhoto() {
    final food = _food;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              food.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) =>
                  FoodPhoto(foodCode: food.foodCode, size: 240),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(food.displayName,
                style: Theme.of(dialogContext).textTheme.titleMedium),
          ),
          if (food.imageCredit != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('ภาพ: ${food.imageCredit}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ปิด'),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final custom = _customEntry;
    final saveLabel = widget.draft
        ? 'ใช้ปริมาณนี้'
        : widget.existingEntry == null
            ? 'บันทึก'
            : 'บันทึกการแก้ไข';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.draft
            ? 'ระบุปริมาณ'
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
          onPressed:
              preview == null ? null : () => Navigator.of(context).pop(preview),
          child: Text(preview == null
              ? saveLabel
              : '$saveLabel · ${preview.calories.round()} kcal'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHeader(context),
          const SizedBox(height: 18),
          if (custom != null)
            _buildCustomCard(context, custom)
          else ...[
            _buildAmountCard(context, preview),
            if (_ricePlate && _eggs.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildOrderCard(context),
            ],
            if (!widget.draft && _isDish)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _openComponents,
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: const Text('ระบุส่วนประกอบเอง'),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          _NutritionSummary(
            entry: preview,
            target: widget.draft ? null : widget.healthResult,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final food = _food;
    return Row(children: [
      GestureDetector(
        onTap: food.imageUrl == null ? null : _showPhoto,
        child: FoodPhoto(url: food.imageUrl, foodCode: food.foodCode, size: 64),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.displayName,
                style: Theme.of(context).textTheme.titleLarge),
            if (!widget.draft) ...[
              const SizedBox(height: 2),
              Text(widget.initialMealType.label,
                  style: const TextStyle(color: AppColors.muted)),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _buildAmountCard(BuildContext context, MealEntry? preview) {
    final unit = _unit;
    final showSizes = unit != null && unit.hasSizeRange;
    return _Section(
      title: 'กินไปเท่าไหร่',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_units.isNotEmpty) ...[
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final serving in _units)
                ChoiceChip(
                  label: Text(serving.noun),
                  selected: unit?.id == serving.id,
                  onSelected: (_) => _selectUnit(serving),
                ),
              ChoiceChip(
                label: const Text('กรัม'),
                selected: unit == null,
                onSelected: (_) => _selectUnit(null),
              ),
            ]),
            const SizedBox(height: 16),
          ],
          if (showSizes) ...[
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final (index, label) in HouseholdUnits.sizeLabels.indexed)
                  ButtonSegment(value: index, label: Text(label)),
              ],
              selected: {_size},
              onSelectionChanged: (values) =>
                  _change(() => _size = values.first),
            ),
            const SizedBox(height: 16),
          ],
          Row(children: [
            IconButton.filledTonal(
              tooltip: 'ลดปริมาณ',
              onPressed: () => _step(-1),
              icon: const Icon(Icons.remove_rounded),
            ),
            Expanded(
              child: Column(children: [
                TextField(
                  controller: _quantity,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => _change(() {}),
                ),
                Text(unit == null ? 'กรัม' : unit.shortNoun,
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w600)),
              ]),
            ),
            IconButton.filledTonal(
              tooltip: 'เพิ่มปริมาณ',
              onPressed: () => _step(1),
              icon: const Icon(Icons.add_rounded),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            !_validAmount
                ? 'ระบุปริมาณรวม 1–5,000 กรัม'
                : unit != null
                    ? '≈ ${HouseholdUnits.formatNumber((preview?.grams ?? _grams).roundToDouble())} กรัม'
                    : _units.isEmpty
                        ? 'ดูน้ำหนักได้จากฉลากบนบรรจุภัณฑ์'
                        : 'ไม่รู้น้ำหนัก? เลือกหน่วยด้านบนแทนได้',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _validAmount ? AppColors.muted : AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context) {
    final order = _order;
    return _Section(
      title: 'เพิ่มไข่',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final style in EggStyle.values)
            if (_eggs.containsKey(style))
              ChoiceChip(
                label: Text(style.label),
                selected: order.egg == style,
                onSelected: (selected) => _change(() => _order = selected
                    ? order.copyWith(
                        egg: () => style,
                        eggCount: order.eggCount < 1 ? 1 : order.eggCount)
                    : order.copyWith(egg: () => null, eggCount: 0)),
              ),
        ]),
        if (order.hasEgg)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              Expanded(
                child: Text('${order.egg!.label} ${order.eggCount} ฟอง',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'ลดจำนวนไข่',
                onPressed: () => _change(() => _order = order.eggCount <= 1
                    ? order.copyWith(egg: () => null, eggCount: 0)
                    : order.copyWith(eggCount: order.eggCount - 1)),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              IconButton(
                tooltip: 'เพิ่มจำนวนไข่',
                onPressed: order.eggCount >= 6
                    ? null
                    : () => _change(() =>
                        _order = order.copyWith(eggCount: order.eggCount + 1)),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _buildCustomCard(BuildContext context, MealEntry entry) => _Section(
        title: 'ส่วนประกอบที่ระบุเอง',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final component in entry.components)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(child: Text(component.foodName)),
                Text(
                  component.portion ??
                      HouseholdUnits.describe(
                          component.toFoodItem(), component.grams),
                  style: const TextStyle(color: AppColors.muted),
                ),
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
              child: const Text('กลับไปใช้แบบปกติ'),
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
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({required this.entry, required this.target});

  final MealEntry? entry;
  final HealthResult? target;

  @override
  Widget build(BuildContext context) {
    final entry = this.entry;
    final target = this.target;
    final calories = entry?.calories ?? 0;
    final share = target == null || target.calories <= 0
        ? null
        : calories / target.calories;
    String minor(String label, double? value, bool known, String unit) =>
        value == null || !known
            ? '$label ไม่มีข้อมูล'
            : '$label ${value.toStringAsFixed(value >= 100 ? 0 : 1)} $unit';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${calories.round()} kcal',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.tealDark)),
          const Spacer(),
          if (share != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${(share * 100).round()}% ของวัน',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _MacroTile(
              label: 'คาร์บ',
              value: entry?.carbs ?? 0,
              target: target?.carbs,
              color: AppColors.teal),
          const SizedBox(width: 12),
          _MacroTile(
              label: 'โปรตีน',
              value: entry?.protein ?? 0,
              target: target?.protein,
              color: AppColors.blue),
          const SizedBox(width: 12),
          _MacroTile(
              label: 'ไขมัน',
              value: entry?.fat ?? 0,
              target: target?.fat,
              color: AppColors.amber),
        ]),
        const SizedBox(height: 12),
        Text(
          '${minor('น้ำตาล', entry?.sugar, entry?.hasSugarData ?? false, 'ก.')}'
          '  ·  '
          '${minor('โซเดียม', entry?.sodium, entry?.hasSodiumData ?? false, 'มก.')}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ]),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
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
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(value >= 10 ? 0 : 1)} ก.',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: target == null || target <= 0
                ? 0
                : (value / target).clamp(0.0, 1.0),
            minHeight: 6,
            color: color,
            backgroundColor: Colors.white,
          ),
        ),
      ]),
    );
  }
}
