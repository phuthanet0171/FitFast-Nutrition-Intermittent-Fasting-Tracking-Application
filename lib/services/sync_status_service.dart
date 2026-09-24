import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CloudSyncState { idle, checking, connected, failed }

class SyncStatus {
  const SyncStatus({
    required this.state,
    this.lastConnectedAt,
  });

  final CloudSyncState state;
  final DateTime? lastConnectedAt;

  SyncStatus copyWith({
    CloudSyncState? state,
    DateTime? lastConnectedAt,
  }) =>
      SyncStatus(
        state: state ?? this.state,
        lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      );
}

class SyncStatusService {
  SyncStatusService._();

  static final instance = SyncStatusService._();
  static const _lastConnectedPrefix = 'fitfast_last_connected_v1_';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final ValueNotifier<SyncStatus> status = ValueNotifier(
    const SyncStatus(state: CloudSyncState.idle),
  );

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> restore() async {
    final userId = _userId;
    if (userId == null) return;
    if (status.value.state == CloudSyncState.connected ||
        status.value.state == CloudSyncState.checking) {
      return;
    }
    final source = await _preferences.getString('$_lastConnectedPrefix$userId');
    status.value = SyncStatus(
      state: CloudSyncState.idle,
      lastConnectedAt: DateTime.tryParse(source ?? '')?.toLocal(),
    );
  }

  Future<bool> checkConnection() async {
    final userId = _userId;
    if (userId == null) {
      status.value = const SyncStatus(state: CloudSyncState.failed);
      return false;
    }
    status.value = status.value.copyWith(state: CloudSyncState.checking);
    try {
      await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .limit(1);
      await markConnected();
      return true;
    } catch (_) {
      markFailed();
      return false;
    }
  }

  Future<void> markConnected() async {
    final now = DateTime.now();
    status.value = SyncStatus(
      state: CloudSyncState.connected,
      lastConnectedAt: now,
    );
    final userId = _userId;
    if (userId != null) {
      await _preferences.setString(
        '$_lastConnectedPrefix$userId',
        now.toUtc().toIso8601String(),
      );
    }
  }

  void markFailed() {
    status.value = status.value.copyWith(state: CloudSyncState.failed);
  }
}
