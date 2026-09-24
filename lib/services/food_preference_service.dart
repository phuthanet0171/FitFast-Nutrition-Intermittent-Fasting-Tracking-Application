import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_item.dart';

class FoodPreferenceService {
  FoodPreferenceService._();

  static final instance = FoodPreferenceService._();
  static const _legacyFavoriteKey = 'fitfast_favorite_foods_v1';
  static const _legacyRecentKey = 'fitfast_recent_foods_v1';
  static const _legacyOwnerKey = 'fitfast_food_preferences_v1_owner';
  static const _favoritePrefix = 'fitfast_favorite_foods_v2_';
  static const _recentPrefix = 'fitfast_recent_foods_v2_';
  static const _migratedPrefix = 'fitfast_food_preferences_migrated_';
  // Optional image_url remains compatible with catalogs before the image migration.
  static const _foodColumns = '*';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  String _favoriteKey(String userId) => '$_favoritePrefix$userId';
  String _recentKey(String userId) => '$_recentPrefix$userId';

  Future<List<FoodItem>> loadFavorites() => _load(favorites: true);
  Future<List<FoodItem>> loadRecent() => _load(favorites: false);

  Future<List<FoodItem>> _load({required bool favorites}) async {
    final userId = _userId;
    if (userId == null) {
      return _read(favorites ? _legacyFavoriteKey : _legacyRecentKey);
    }

    final key = favorites ? _favoriteKey(userId) : _recentKey(userId);
    final local = await _read(key);
    try {
      await _ensureLegacyMigrated(userId);
      final cloud = await _loadCloud(userId, favorites: favorites);
      await _write(key, cloud);
      return cloud;
    } catch (_) {
      if (local.isNotEmpty) return local;
      return _readOwnedLegacy(userId, favorites: favorites);
    }
  }

  Future<List<FoodItem>> toggleFavorite(FoodItem food) async {
    final userId = _userId;
    final key = userId == null ? _legacyFavoriteKey : _favoriteKey(userId);
    final foods = await loadFavorites();
    final index = foods.indexWhere((item) => item.id == food.id);
    final isFavorite = index < 0;
    if (isFavorite) {
      foods.insert(0, food);
    } else {
      foods.removeAt(index);
    }
    await _write(key, foods);
    if (userId != null) {
      try {
        await Supabase.instance.client.from('user_food_preferences').upsert({
          'user_id': userId,
          'food_id': food.id,
          'is_favorite': isFavorite,
        }, onConflict: 'user_id,food_id');
      } catch (_) {}
    }
    return foods;
  }

  Future<List<FoodItem>> addRecent(FoodItem food) async {
    final userId = _userId;
    final key = userId == null ? _legacyRecentKey : _recentKey(userId);
    final foods = await loadRecent();
    foods.removeWhere((item) => item.id == food.id);
    foods.insert(0, food);
    if (foods.length > 12) foods.removeRange(12, foods.length);
    await _write(key, foods);
    if (userId != null) {
      try {
        final existing = await Supabase.instance.client
            .from('user_food_preferences')
            .select('use_count')
            .eq('user_id', userId)
            .eq('food_id', food.id)
            .maybeSingle();
        final count = (existing?['use_count'] as num?)?.toInt() ?? 0;
        await Supabase.instance.client.from('user_food_preferences').upsert({
          'user_id': userId,
          'food_id': food.id,
          'last_used_at': DateTime.now().toUtc().toIso8601String(),
          'use_count': count + 1,
        }, onConflict: 'user_id,food_id');
      } catch (_) {}
    }
    return foods;
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) {
      await _preferences.remove(_legacyFavoriteKey);
      await _preferences.remove(_legacyRecentKey);
      return;
    }
    await _preferences.remove(_favoriteKey(userId));
    await _preferences.remove(_recentKey(userId));
  }

  Future<List<FoodItem>> _loadCloud(
    String userId, {
    required bool favorites,
  }) async {
    dynamic request = Supabase.instance.client
        .from('user_food_preferences')
        .select('food_id, last_used_at')
        .eq('user_id', userId);
    if (favorites) request = request.eq('is_favorite', true);
    final preferenceRows = favorites
        ? await request.order('updated_at', ascending: false)
        : await request
            .not('last_used_at', 'is', null)
            .order('last_used_at', ascending: false)
            .limit(12);
    final ids = (preferenceRows as List)
        .map((row) => (row['food_id'] as num).toInt())
        .toList();
    if (ids.isEmpty) return [];

    final foodRows = await Supabase.instance.client
        .from('foods_catalog')
        .select(_foodColumns)
        .inFilter('id', ids)
        .eq('is_usable', true);
    final foodsById = <int, FoodItem>{
      for (final row in foodRows)
        (row['id'] as num).toInt():
            FoodItem.fromJson(Map<String, dynamic>.from(row as Map)),
    };
    return ids.map((id) => foodsById[id]).whereType<FoodItem>().toList();
  }

  Future<void> _ensureLegacyMigrated(String userId) async {
    final migrated =
        await _preferences.getBool('$_migratedPrefix$userId') ?? false;
    if (migrated) return;
    final remote = await Supabase.instance.client
        .from('user_food_preferences')
        .select('food_id')
        .eq('user_id', userId)
        .limit(1);
    if (remote.isNotEmpty) {
      await _preferences.setBool('$_migratedPrefix$userId', true);
      return;
    }

    final owner = await _preferences.getString(_legacyOwnerKey);
    if (owner != null && owner != userId) {
      await _preferences.setBool('$_migratedPrefix$userId', true);
      return;
    }
    final favorites = await _read(_legacyFavoriteKey);
    final recent = await _read(_legacyRecentKey);
    final rows = <int, Map<String, dynamic>>{};
    for (final food in favorites) {
      rows[food.id] = {
        'user_id': userId,
        'food_id': food.id,
        'is_favorite': true,
      };
    }
    final now = DateTime.now().toUtc();
    for (var index = 0; index < recent.length; index++) {
      final food = recent[index];
      rows.putIfAbsent(
          food.id,
          () => {
                'user_id': userId,
                'food_id': food.id,
                'is_favorite': false,
              });
      rows[food.id]!['last_used_at'] =
          now.subtract(Duration(seconds: index)).toIso8601String();
      rows[food.id]!['use_count'] = 1;
    }
    if (rows.isNotEmpty) {
      await Supabase.instance.client.from('user_food_preferences').upsert(
            rows.values.toList(),
            onConflict: 'user_id,food_id',
          );
      await _preferences.setString(_legacyOwnerKey, userId);
    }
    await _preferences.setBool('$_migratedPrefix$userId', true);
  }

  Future<List<FoodItem>> _readOwnedLegacy(
    String userId, {
    required bool favorites,
  }) async {
    final owner = await _preferences.getString(_legacyOwnerKey);
    if (owner != null && owner != userId) return [];
    return _read(favorites ? _legacyFavoriteKey : _legacyRecentKey);
  }

  Future<List<FoodItem>> _read(String key) async {
    final source = await _preferences.getString(key);
    if (source == null || source.isEmpty) return [];
    try {
      final list = jsonDecode(source) as List<dynamic>;
      return list
          .map((item) => FoodItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<FoodItem> foods) =>
      _preferences.setString(
        key,
        jsonEncode(foods.map((food) => food.toJson()).toList()),
      );
}
