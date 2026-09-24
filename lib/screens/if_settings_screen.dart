import 'package:flutter/material.dart';

import '../services/fasting_settings_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class IfSettingsScreen extends StatelessWidget {
  const IfSettingsScreen({
    super.key,
    required this.onChangePlanRequested,
    required this.onPlanCancelled,
  });

  final VoidCallback onChangePlanRequested;
  final VoidCallback onPlanCancelled;

  void _changePlan(BuildContext context) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChangePlanRequested();
    });
  }

  Future<void> _cancelPlan(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.timer_off_outlined,
          color: AppColors.orange,
          size: 38,
        ),
        title: const Text('ยกเลิกแผน IF?'),
        content: const Text(
          'ตัวจับเวลาและการแจ้งเตือน IF จะถูกปิด คุณสามารถกลับมาเลือกแผนใหม่ได้ภายหลัง',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('กลับ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('ยกเลิกแผน'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await NotificationService.instance.cancelFastingReminders();
    await FastingSettingsService.instance.clear();
    onPlanCancelled();
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า IF')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              _SettingsAction(
                icon: Icons.swap_horiz_rounded,
                title: 'จัดการหรือเปลี่ยนแผน',
                description: 'เลือกรูปแบบใหม่ หรือรับคำแนะนำแผน IF',
                color: AppColors.teal,
                onTap: () => _changePlan(context),
              ),
              const SizedBox(height: 14),
              _SettingsAction(
                icon: Icons.delete_outline_rounded,
                title: 'ยกเลิกแผนการทำ IF',
                description: 'ปิดตัวจับเวลาและการแจ้งเตือนของแผนนี้',
                color: AppColors.orange,
                onTap: () => _cancelPlan(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: .28)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
