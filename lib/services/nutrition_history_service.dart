import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_nutrition_record.dart';
import '../models/health_result.dart';

class NutritionHistoryService {
  NutritionHistoryService._();

  static final instance = NutritionHistoryService._();
  static const _storageKey = 'fitfast_nutrition_history_v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<Map<String, DailyNutritionRecord>> _readAll() async {
    final source = await _preferences.getString(_storageKey);
    if (source == null || source.isEmpty) return {};
    try {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          DailyNutritionRecord.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, DailyNutritionRecord> records) async {
    final encoded = jsonEncode(
      records.map((key, value) => MapEntry(key, value.toJson())),
    );
    await _preferences.setString(_storageKey, encoded);
  }

  Future<DailyNutritionRecord> loadOrCreateToday(
    HealthResult? healthResult,
  ) async {
    final now = DateTime.now();
    final key = dateKey(now);
    final records = await _readAll();
    final existing = records[key];
    if (existing != null) return existing;

    final record = DailyNutritionRecord(
      dateKey: key,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      sugar: 0,
      sodium: 0,
      calorieTarget: healthResult?.calories ?? 2000,
      proteinTarget: healthResult?.protein ?? 120,
      carbTarget: healthResult?.carbs ?? 220,
      fatTarget: healthResult?.fat ?? 65,
      sugarLimit: (healthResult?.sugar ?? 24).clamp(0, 24).toDouble(),
      sodiumLimit: healthResult?.sodium ?? 2000,
    );
    records[key] = record;
    await _writeAll(records);
    return record;
  }

  Future<DailyNutritionRecord?> load(DateTime date) async {
    final records = await _readAll();
    return records[dateKey(date)];
  }

  Future<void> save(DailyNutritionRecord record) async {
    final records = await _readAll();
    records[record.dateKey] = record;
    await _writeAll(records);
  }
}
