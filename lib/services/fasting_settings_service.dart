import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fasting_settings.dart';
import 'fasting_session_service.dart';
import 'sync_status_service.dart';

class FastingSettingsService {
  FastingSettingsService._();

  static final instance = FastingSettingsService._();
  static const _legacyKey = 'fitfast_fasting_settings_v1';
  static const _legacyOwnerKey = 'fitfast_fasting_settings_v1_owner';
  static const _userKeyPrefix = 'fitfast_fasting_settings_v2_';
  static const _migratedPrefix = 'fitfast_fasting_settings_migrated_';
  static const _pendingPrefix = 'fitfast_fasting_settings_pending_';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;
  String _userKey(String userId) => '$_userKeyPrefix$userId';

  Future<FastingSettings?> load() async {
    final userId = _userId;
    if (userId == null) return _loadLocal(_legacyKey);

    final key = _userKey(userId);
    final local = await _loadLocal(key);
    final pending = await _preferences.getString('$_pendingPrefix$userId');
    if (pending == 'delete') {
      try {
        await _deleteRemote(userId);
        await _markSynced(userId);
      } catch (_) {
        return null;
      }
      return null;
    }

    // The per-user cache is the latest value selected on this device. Keep it
    // visible even while the network or RLS policy is temporarily unavailable.
    if (local != null) {
      try {
        await _upsertRemote(userId, local);
        await FastingSessionService.instance.syncCurrentSchedule(local);
        await _markSynced(userId);
      } catch (_) {
        await _preferences.setString('$_pendingPrefix$userId', 'save');
      }
      return local;
    }

    try {
      final remote = await _loadRemote(userId);
      final migrated =
          await _preferences.getBool('$_migratedPrefix$userId') ?? false;
      if (remote != null) {
        await _writeLocal(key, remote);
        await _preferences.setBool('$_migratedPrefix$userId', true);
        return remote;
      }

      if (migrated) return null;

      final source = await _claimLegacySettings(userId);
      if (source != null) {
        await _upsertRemote(userId, source);
        await _writeLocal(key, source);
      }
      await _preferences.setBool('$_migratedPrefix$userId', true);
      return source;
    } catch (_) {
      return local ?? await _loadOwnedLegacySettings(userId);
    }
  }

  Future<void> save(FastingSettings settings) async {
    final userId = _userId;
    if (userId == null) {
      await _writeLocal(_legacyKey, settings);
      return;
    }

    await _writeLocal(_userKey(userId), settings);
    await _preferences.setString('$_pendingPrefix$userId', 'save');
    try {
      await _upsertRemote(userId, settings);
      await FastingSessionService.instance.syncCurrentSchedule(settings);
      await SyncStatusService.instance.markConnected();
      await _markSynced(userId);
    } catch (_) {
      SyncStatusService.instance.markFailed();
      // Keep the setting locally and retry when it is loaded again.
    }
  }

  Future<void> clear() async {
    final userId = _userId;
    if (userId == null) {
      await _preferences.remove(_legacyKey);
      return;
    }

    await _preferences.remove(_userKey(userId));
    await _preferences.setString('$_pendingPrefix$userId', 'delete');
    try {
      await _deleteRemote(userId);
      await SyncStatusService.instance.markConnected();
      await _markSynced(userId);
    } catch (_) {
      SyncStatusService.instance.markFailed();
      // Keep the pending deletion and retry the next time it is loaded.
    }
  }

  Future<FastingSettings?> _loadRemote(String userId) async {
    final row = await Supabase.instance.client
        .from('fasting_settings')
        .select('plan, fasting_start_time, notifications_enabled')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;

    final parts = (row['fasting_start_time'] as String? ?? '').split(':');
    if (parts.length < 2) return null;
    return FastingSettings.fromJson({
      'plan': row['plan'],
      'fastingStartHour': int.tryParse(parts[0]),
      'fastingStartMinute': int.tryParse(parts[1]),
      'notificationsEnabled': row['notifications_enabled'],
    });
  }

  Future<void> _upsertRemote(
    String userId,
    FastingSettings settings,
  ) async {
    final hour = settings.fastingStartHour.toString().padLeft(2, '0');
    final minute = settings.fastingStartMinute.toString().padLeft(2, '0');
    await Supabase.instance.client.from('fasting_settings').upsert({
      'user_id': userId,
      'plan': settings.plan,
      'fasting_start_time': '$hour:$minute:00',
      'notifications_enabled': settings.notificationsEnabled,
      'timezone': 'Asia/Bangkok',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<void> _deleteRemote(String userId) async {
    await FastingSessionService.instance.cancelActive();
    await Supabase.instance.client
        .from('fasting_settings')
        .delete()
        .eq('user_id', userId);
  }

  Future<FastingSettings?> _claimLegacySettings(String userId) async {
    final owner = await _preferences.getString(_legacyOwnerKey);
    if (owner != null && owner != userId) return null;
    final settings = await _loadLocal(_legacyKey);
    if (settings != null) {
      await _preferences.setString(_legacyOwnerKey, userId);
    }
    return settings;
  }

  Future<FastingSettings?> _loadOwnedLegacySettings(String userId) async {
    final owner = await _preferences.getString(_legacyOwnerKey);
    if (owner != null && owner != userId) return null;
    return _loadLocal(_legacyKey);
  }

  Future<FastingSettings?> _loadLocal(String key) async {
    final source = await _preferences.getString(key);
    if (source == null || source.isEmpty) return null;
    try {
      return FastingSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(source) as Map),
      );
    } catch (_) {
      await _preferences.remove(key);
      return null;
    }
  }

  Future<void> _writeLocal(String key, FastingSettings settings) =>
      _preferences.setString(key, jsonEncode(settings.toJson()));

  Future<void> _markSynced(String userId) async {
    await _preferences.remove('$_pendingPrefix$userId');
    await _preferences.setBool('$_migratedPrefix$userId', true);
  }
}
