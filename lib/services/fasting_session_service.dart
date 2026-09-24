import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fasting_settings.dart';

class FastingSessionService {
  FastingSessionService._();

  static final instance = FastingSessionService._();

  Future<void> syncCurrentSchedule(
    FastingSettings settings, {
    DateTime? currentTime,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final now = currentTime ?? DateTime.now();
    final client = Supabase.instance.client;
    final nowUtc = now.toUtc().toIso8601String();

    final dueSessions = await client
        .from('fasting_sessions')
        .select('id, target_end_at, target_minutes')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .lte('target_end_at', nowUtc);
    for (final session in dueSessions) {
      await client
          .from('fasting_sessions')
          .update({
            'status': 'completed',
            'ended_at': session['target_end_at'],
            'completed_minutes': session['target_minutes'],
          })
          .eq('user_id', user.id)
          .eq('id', session['id']);
    }

    final period = _currentPeriod(settings, now);
    if (!period.isFasting) return;

    final active = await client
        .from('fasting_sessions')
        .select('id, plan, started_at, target_end_at')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (active != null) {
      final activeStart =
          DateTime.tryParse(active['started_at'] as String? ?? '');
      final activeEnd =
          DateTime.tryParse(active['target_end_at'] as String? ?? '');
      final sameSchedule = active['plan'] == settings.plan &&
          activeStart?.isAtSameMomentAs(period.start.toUtc()) == true &&
          activeEnd?.isAtSameMomentAs(period.end.toUtc()) == true;
      if (sameSchedule) return;
      await cancelActive(currentTime: now);
    }

    try {
      await client.from('fasting_sessions').insert({
        'user_id': user.id,
        'plan': settings.plan,
        'started_at': period.start.toUtc().toIso8601String(),
        'target_end_at': period.end.toUtc().toIso8601String(),
        'target_minutes': settings.fastingHours * 60,
        'status': 'active',
      });
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
    }
  }

  Future<void> cancelActive({DateTime? currentTime}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final now = currentTime ?? DateTime.now();
    final active = await Supabase.instance.client
        .from('fasting_sessions')
        .select('id, started_at')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();
    if (active == null) return;

    final startedAt = DateTime.tryParse(active['started_at'] as String? ?? '');
    final completedMinutes = startedAt == null
        ? 0
        : now.toUtc().difference(startedAt.toUtc()).inMinutes.clamp(0, 1440);
    await Supabase.instance.client
        .from('fasting_sessions')
        .update({
          'status': 'cancelled',
          'ended_at': now.toUtc().toIso8601String(),
          'completed_minutes': completedMinutes,
        })
        .eq('user_id', user.id)
        .eq('id', active['id']);
  }

  _ScheduledPeriod _currentPeriod(FastingSettings settings, DateTime now) {
    var start = DateTime(
      now.year,
      now.month,
      now.day,
      settings.fastingStartHour,
      settings.fastingStartMinute,
    );
    if (now.isBefore(start)) start = start.subtract(const Duration(days: 1));
    final end = start.add(Duration(hours: settings.fastingHours));
    return _ScheduledPeriod(
      start: start,
      end: end,
      isFasting: now.isBefore(end),
    );
  }
}

class _ScheduledPeriod {
  const _ScheduledPeriod({
    required this.start,
    required this.end,
    required this.isFasting,
  });

  final DateTime start;
  final DateTime end;
  final bool isFasting;
}
