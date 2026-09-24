import 'dart:async';
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../services/food_catalog_service.dart';
import '../services/food_preference_service.dart';
import '../widgets/food_photo.dart';
import 'food_amount_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen(
      {super.key,
      required this.mealType,
      required this.dateKey,
      this.componentPicker = false,
      this.initialQuery = ''});
  final MealType mealType;
  final String dateKey;
  final bool componentPicker;
  final String initialQuery;
  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  late final TextEditingController _query;
  Timer? _timer;
  List<FoodItem> _foods = [], _recent = [], _favorites = [];
  int _tab = 0, _request = 0;
  bool _loading = true, _opening = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    _search();
    _preferences();
  }

  Future<void> _preferences() async {
    try {
      final recent = await FoodPreferenceService.instance.loadRecent();
      final favorites = await FoodPreferenceService.instance.loadFavorites();
      if (mounted) {
        setState(() {
          _recent = recent;
          _favorites = favorites;
        });
      }
    } catch (_) {/* Search remains available without saved preferences. */}
  }

  Future<void> _search() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final foods = await FoodCatalogService.instance.search(_query.text);
      if (mounted && request == _request) {
        setState(() {
          _foods = foods;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'โหลดอาหารไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองอีกครั้ง';
        });
      }
    }
  }

  Future<void> _select(FoodItem food) async {
    if (_opening) return;
    if (widget.componentPicker) {
      Navigator.of(context).pop(food);
      return;
    }
    _opening = true;
    final entry = await Navigator.of(context).push<MealEntry>(MaterialPageRoute(
        builder: (_) => FoodAmountScreen(
            food: food,
            initialMealType: widget.mealType,
            dateKey: widget.dateKey)));
    _opening = false;
    if (entry == null || !mounted) return;
    unawaited(FoodPreferenceService.instance
        .addRecent(food)
        .then<void>((_) {}, onError: (Object _) {}));
    Navigator.of(context).pop(entry);
  }

  Future<void> _favorite(FoodItem food) async {
    try {
      final items = await FoodPreferenceService.instance.toggleFavorite(food);
      if (mounted) setState(() => _favorites = items);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ยังบันทึกรายการโปรดไม่ได้')));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _tab == 0
        ? _foods
        : _tab == 1
            ? _recent
            : _favorites;
    final items = _tab == 0
        ? source
        : source
            .where((f) =>
                f.nameTh.contains(_query.text.trim()) ||
                (f.nameEn ?? '')
                    .toLowerCase()
                    .contains(_query.text.trim().toLowerCase()))
            .toList();
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.componentPicker
                ? 'เลือกส่วนประกอบ'
                : 'เพิ่ม${widget.mealType.label}')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                  controller: _query,
                  decoration: InputDecoration(
                      hintText: 'ค้นหาอาหาร เช่น ข้าว ไข่ กะเพรา',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                          tooltip: 'ล้างคำค้น',
                          onPressed: () {
                            _query.clear();
                            _search();
                          },
                          icon: const Icon(Icons.close))),
                  onChanged: (_) {
                    _timer?.cancel();
                    ++_request;
                    setState(() {});
                    _timer = Timer(const Duration(milliseconds: 350), _search);
                  })),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(spacing: 8, children: [
                for (final (index, label)
                    in ['ค้นหาอาหาร', 'ล่าสุด', 'รายการโปรด'].indexed)
                  ChoiceChip(
                      label: Text(label),
                      selected: _tab == index,
                      onSelected: (_) => setState(() => _tab = index)),
              ])),
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(widget.componentPicker
                  ? 'เลือกอาหารหนึ่งรายการ แล้วระบุปริมาณที่รับประทาน'
                  : 'แตะอาหารเพื่อเลือกปริมาณก่อนบันทึก')),
          Expanded(
              child: _tab == 0 && _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tab == 0 && _error != null
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_error!, textAlign: TextAlign.center),
                                    TextButton(
                                        onPressed: _search,
                                        child: const Text('ลองอีกครั้ง'))
                                  ])))
                      : items.isEmpty
                          ? const Center(child: Text('ยังไม่มีรายการอาหาร'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                              itemCount: items.length,
                              separatorBuilder: (_, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final food = items[index];
                                final favorite =
                                    _favorites.any((f) => f.id == food.id);
                                return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 10),
                                    leading: FoodPhoto(url: food.imageUrl),
                                    title: Text(food.nameTh,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    subtitle: Text(
                                        '${food.energyKcalPer100g.round()} kcal / 100 กรัม'),
                                    onTap: () => _select(food),
                                    trailing: IconButton(
                                        tooltip: favorite
                                            ? 'นำออกจากรายการโปรด'
                                            : 'เพิ่มรายการโปรด',
                                        onPressed: () => _favorite(food),
                                        icon: Icon(favorite
                                            ? Icons.favorite
                                            : Icons.favorite_border)));
                              })),
        ]));
  }
}
