import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_entry.dart';
import 'sync_status_service.dart';

class MealHistoryService {
  MealHistoryService._();

  static final instance = MealHistoryService._();
  static const _legacyKey = 'fitfast_meal_entries_v1';
  static const _legacyOwnerKey = 'fitfast_meal_entries_v1_owner';
  static const _userKeyPrefix = 'fitfast_meal_entries_v2_';
  static const _migratedPrefix = 'fitfast_meal_entries_migrated_';
  static const _dirtyPrefix = 'fitfast_meal_entries_dirty_';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  String _userKey(String userId) => '$_userKeyPrefix$userId';

  Future<List<MealEntry>> _readAll() async {
    final userId = _userId;
    if (userId == null) return _loadLocal(_legacyKey);

    final key = _userKey(userId);
    final local = await _loadLocal(key);
    final dirty = await _preferences.getBool('$_dirtyPrefix$userId') ?? false;
    if (dirty) {
      try {
        await _replaceRemote(userId, local);
        await _markSynced(userId);
      } catch (_) {}
      return local;
    }

    try {
      final remote = await _loadRemote(userId);
      final migrated =
          await _preferences.getBool('$_migratedPrefix$userId') ?? false;
      if (migrated || remote.isNotEmpty) {
        await _writeLocal(key, remote);
        await _preferences.setBool('$_migratedPrefix$userId', true);
        return remote;
      }

      final source =
          local.isNotEmpty ? local : await _claimLegacyHistory(userId);
      if (source.isNotEmpty) {
        await _replaceRemote(userId, source);
        await _writeLocal(key, source);
      }
      await _preferences.setBool('$_migratedPrefix$userId', true);
      return source;
    } catch (_) {
      return local.isNotEmpty ? local : await _loadOwnedLegacyHistory(userId);
    }
  }

  Future<List<MealEntry>> loadDate(String dateKey) async {
    final entries = await _readAll();
    return entries.where((entry) => entry.dateKey == dateKey).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<MealEntry?> loadLatestDetailedForFood(int foodId) async {
    final entries = await _readAll();
    final matches = entries
        .where((entry) => entry.foodId == foodId && entry.isDetailed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> add(MealEntry entry) async {
    final userId = _userId;
    final key = userId == null ? _legacyKey : _userKey(userId);
    final entries = await _readAll();
    final index = entries.indexWhere((item) => item.id == entry.id);
    index >= 0 ? entries[index] = entry : entries.add(entry);
    _sort(entries);
    await _writeLocal(key, entries);
    if (userId != null) await _syncRemoteSnapshot(userId, entries);
  }

  Future<void> update(MealEntry entry) async {
    final userId = _userId;
    final key = userId == null ? _legacyKey : _userKey(userId);
    final entries = await _readAll();
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    entries[index] = entry;
    _sort(entries);
    await _writeLocal(key, entries);
    if (userId != null) await _syncRemoteSnapshot(userId, entries);
  }

  Future<void> delete(MealEntry entry) async {
    final userId = _userId;
    final key = userId == null ? _legacyKey : _userKey(userId);
    final entries = await _readAll();
    var index = entries.indexWhere((item) =>
        item.id == entry.id &&
        item.createdAt.isAtSameMomentAs(entry.createdAt));
    index =
        index < 0 ? entries.indexWhere((item) => item.id == entry.id) : index;
    if (index < 0) return;
    entries.removeAt(index);
    await _writeLocal(key, entries);
    if (userId == null) return;
    await _syncRemoteSnapshot(userId, entries);
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) {
      await _preferences.remove(_legacyKey);
      return;
    }
    await _preferences.remove(_userKey(userId));
    await _preferences.remove('$_dirtyPrefix$userId');
  }

  Future<void> _syncRemoteSnapshot(
      String userId, List<MealEntry> entries) async {
    await _preferences.setBool('$_dirtyPrefix$userId', true);
    try {
      await _replaceRemote(userId, entries);
      await SyncStatusService.instance.markConnected();
      await _markSynced(userId);
    } catch (_) {
      SyncStatusService.instance.markFailed();
    }
  }

  Future<List<MealEntry>> _loadRemote(String userId) async {
    final rows = await Supabase.instance.client
        .from('meal_entries')
        .select()
        .eq('user_id', userId)
        .order('meal_date')
        .order('created_at');
    final entries = (rows as List)
        .map((row) => _fromRemote(Map<String, dynamic>.from(row as Map)))
        .toList();
    _sort(entries);
    return entries;
  }

  Future<void> _replaceRemote(
    String userId,
    List<MealEntry> entries,
  ) async {
    final table = Supabase.instance.client.from('meal_entries');
    if (entries.isEmpty) {
      await table.delete().eq('user_id', userId);
      return;
    }

    // Upsert first. If this fails, existing cloud history remains intact.
    await table
        .upsert(entries.map((entry) => _toRemote(userId, entry)).toList());

    // Remove stale rows only after every desired row is safely in the cloud.
    final desiredIds = entries.map((entry) => entry.id).toSet();
    final remoteRows = await table.select('id').eq('user_id', userId);
    for (final row in remoteRows as List) {
      final id = (row as Map)['id']?.toString();
      if (id != null && !desiredIds.contains(id)) {
        await table.delete().eq('user_id', userId).eq('id', id);
      }
    }
  }

  Map<String, dynamic> _toRemote(String userId, MealEntry entry) => {
        'id': entry.id,
        'user_id': userId,
        'meal_date': entry.dateKey,
        'meal_type': entry.mealType.key,
        'food_id': entry.foodId,
        'food_code': entry.foodCode,
        'food_name': entry.foodName,
        'grams': entry.grams,
        'calories': entry.calories,
        'protein_g': entry.protein,
        'carbs_g': entry.carbs,
        'fat_g': entry.fat,
        'sugar_g': entry.sugar,
        'sodium_mg': entry.sodium,
        'has_sugar_data': entry.hasSugarData,
        'has_sodium_data': entry.hasSodiumData,
        'created_at': entry.createdAt.toUtc().toIso8601String(),
        'components': entry.components.map((item) => item.toJson()).toList(),
      };

  MealEntry _fromRemote(Map<String, dynamic> row) {
    double number(String key) => (row[key] as num?)?.toDouble() ?? 0;
    return MealEntry(
      id: row['id'] as String? ?? '',
      dateKey: row['meal_date'] as String? ?? '',
      mealType: MealTypeLabel.fromKey(row['meal_type'] as String? ?? ''),
      foodId: (row['food_id'] as num?)?.toInt() ?? 0,
      foodCode: row['food_code'] as String? ?? '',
      foodName: row['food_name'] as String? ?? '',
      grams: number('grams'),
      calories: number('calories'),
      protein: number('protein_g'),
      carbs: number('carbs_g'),
      fat: number('fat_g'),
      sugar: number('sugar_g'),
      sodium: number('sodium_mg'),
      hasSugarData: row['has_sugar_data'] as bool? ?? false,
      hasSodiumData: row['has_sodium_data'] as bool? ?? false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      components: (row['components'] as List<dynamic>? ?? const [])
          .map((item) =>
              MealComponent.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Future<List<MealEntry>> _claimLegacyHistory(String userId) async {
    final owner = await _preferences.getString(_legacyOwnerKey);
    if (owner != null && owner != userId) return [];
    final entries = await _loadLocal(_legacyKey);
    if (entries.isNotEmpty) {
      await _preferences.setString(_legacyOwnerKey, userId);
    }
    return entries;
  }

  Future<List<MealEntry>> _loadOwnedLegacyHistory(String userId) async {
    final owner = await _preferences.getString(_legacyOwnerKey);
    if (owner != null && owner != userId) return [];
    return _loadLocal(_legacyKey);
  }

  Future<List<MealEntry>> _loadLocal(String key) async {
    final source = await _preferences.getString(key);
    if (source == null || source.isEmpty) return [];
    try {
      final decoded = jsonDecode(source) as List<dynamic>;
      final entries = decoded
          .map((item) => MealEntry.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .where((entry) => entry.id.isNotEmpty && entry.dateKey.isNotEmpty)
          .toList();
      _sort(entries);
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeLocal(String key, List<MealEntry> entries) =>
      _preferences.setString(
        key,
        jsonEncode(entries.map((entry) => entry.toJson()).toList()),
      );

  Future<void> _markSynced(String userId) async {
    await _preferences.setBool('$_dirtyPrefix$userId', false);
    await _preferences.setBool('$_migratedPrefix$userId', true);
  }

  void _sort(List<MealEntry> entries) {
    entries.sort((a, b) {
      final byDate = a.dateKey.compareTo(b.dateKey);
      return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
    });
  }
}
