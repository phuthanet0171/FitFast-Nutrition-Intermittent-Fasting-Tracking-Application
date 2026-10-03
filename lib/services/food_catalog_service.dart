import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_item.dart';
import '../models/food_serving.dart';
import 'food_search.dart';

/// The food catalogue is small (about 1,200 foods), so it is downloaded once,
/// kept on the device and searched locally. Local search can match Thai
/// names in any word order and without tone marks, which PostgREST ILIKE
/// cannot, and it keeps working offline.
class FoodCatalogService {
  FoodCatalogService._();

  static final instance = FoodCatalogService._();

  static const _cacheKey = 'fitfast_food_catalog_v2';
  static const _cacheSavedAtKey = 'fitfast_food_catalog_v2_saved_at';
  static const _refreshAfter = Duration(hours: 24);
  static const _pageSize = 1000;
  // Tried in order, so older databases without the newer columns still load.
  static const _columnSets = [
    'id, food_code, name_th, name_en, common_name_th, search_aliases, '
        'image_url, image_credit, energy_kcal_per_100g, protein_g_per_100g, '
        'carbs_g_per_100g, fat_g_per_100g, sugar_g_per_100g, '
        'sodium_mg_per_100g, edible_portion_percent, food_servings(*)',
    '*, food_servings(*)',
    '*',
  ];

  // Created on first use, so looking up servings never needs local storage.
  late final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  SupabaseClient get _client => Supabase.instance.client;

  FoodSearch? _search;
  DateTime? _loadedAt;
  Future<FoodSearch>? _loading;

  Future<List<FoodItem>> search(
    String query, {
    Set<int> preferIds = const {},
  }) async {
    final search = await _catalog();
    return query.trim().isEmpty
        ? search.suggestions(preferIds: preferIds)
        : search.search(query, preferIds: preferIds);
  }

  /// Forgets the in-memory copy so the next search downloads the catalogue.
  void invalidate() {
    _search = null;
    _loadedAt = null;
  }

  /// The catalogue copy of a food when the catalogue is already loaded.
  /// Logged entries keep only a nutrient snapshot, so screens use this to
  /// find the food's household units again.
  FoodItem? cachedFood(int id) => _search?.byId(id);

  /// Loads the catalogue in the background; screens that show logged foods
  /// call this so [cachedFood] works without a search first.
  Future<bool> warmUp() async {
    try {
      await _catalog();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// A food by its catalogue code, e.g. "A11" for ข้าวสวย, or null when the
  /// catalogue cannot be loaded.
  Future<FoodItem?> foodByCode(String code) async {
    try {
      return (await _catalog()).byCode(code);
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  void debugSetFoods(List<FoodItem> foods) {
    _search = FoodSearch(foods);
    _loadedAt = DateTime.now();
  }

  Future<FoodSearch> _catalog() {
    final loaded = _search;
    final stale = _loadedAt == null ||
        DateTime.now().difference(_loadedAt!) > _refreshAfter;
    if (loaded != null) {
      if (stale) unawaited(_refresh().then<void>((_) {}, onError: (_) {}));
      return Future.value(loaded);
    }
    return _loading ??= _loadInitial().whenComplete(() => _loading = null);
  }

  Future<FoodSearch> _loadInitial() async {
    final cached = await _readCache();
    if (cached != null) {
      _search = FoodSearch(cached.foods);
      _loadedAt = cached.savedAt;
      // Show the saved copy at once, and pick up catalogue edits (new foods,
      // names or units) in the background once per app session.
      unawaited(_refresh().then<void>((_) {}, onError: (_) {}));
      return _search!;
    }
    return _refresh();
  }

  Future<FoodSearch> _refresh() async {
    final foods = await _download();
    _search = FoodSearch(foods);
    _loadedAt = DateTime.now();
    await _writeCache(foods);
    return _search!;
  }

  Future<List<FoodItem>> _download() async {
    PostgrestException? lastError;
    for (final columns in _columnSets) {
      try {
        final foods = <FoodItem>[];
        for (var from = 0;; from += _pageSize) {
          final rows = await _client
              .from('foods_catalog')
              .select(columns)
              .eq('is_usable', true)
              .order('id')
              .range(from, from + _pageSize - 1);
          foods.addAll((rows as List).map((row) =>
              FoodItem.fromJson(Map<String, dynamic>.from(row as Map))));
          if (rows.length < _pageSize) break;
        }
        return foods;
      } on PostgrestException catch (error) {
        lastError = error;
      }
    }
    throw lastError!;
  }

  Future<({List<FoodItem> foods, DateTime savedAt})?> _readCache() async {
    try {
      final source = await _preferences.getString(_cacheKey);
      final savedAt = DateTime.tryParse(
          await _preferences.getString(_cacheSavedAtKey) ?? '');
      if (source == null || savedAt == null) return null;
      final foods = (jsonDecode(source) as List)
          .map((item) =>
              FoodItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      return foods.isEmpty ? null : (foods: foods, savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<FoodItem> foods) async {
    try {
      await _preferences.setString(
          _cacheKey, jsonEncode([for (final food in foods) food.toJson()]));
      await _preferences.setString(
          _cacheSavedAtKey, DateTime.now().toIso8601String());
    } catch (_) {
      // The catalogue still works from memory for this session.
    }
  }

  Future<List<FoodServing>> loadVerifiedServings(int foodId) async {
    try {
      // '*' keeps working before and after the phase 2 serving columns exist.
      final rows = await _client
          .from('food_servings')
          .select()
          .eq('food_id', foodId)
          .eq('verified', true)
          .gt('grams', 0);
      return FoodServing.sorted((rows as List).map((row) =>
          FoodServing.fromJson(Map<String, dynamic>.from(row as Map))));
    } catch (_) {
      // The gram input remains available while the optional serving table
      // has not been created or has no verified rows.
      return [];
    }
  }
}
