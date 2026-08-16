import 'package:flutter/material.dart';

import '../models/health_result.dart';
import '../theme/app_theme.dart';
import 'if_manual_plan_screen.dart';
import 'if_recommendation_screen.dart';

class IfSetupMethodScreen extends StatelessWidget {
  const IfSetupMethodScreen({
    super.key,
    required this.age,
    required this.bmi,
    required this.healthResult,
  });

  final int age;
  final double bmi;
  final HealthResult healthResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกวิธีตั้งค่า')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('อยากเริ่มแบบไหน?',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 9),
              const Text(
                  'FitFast ช่วยแนะนำให้ได้ หรือคุณจะเลือกแผนด้วยตัวเองก็ได้',
                  style: TextStyle(color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 30),
              _MethodCard(
                icon: Icons.auto_awesome_rounded,
                color: AppColors.teal,
                title: 'รับคำแนะนำการทำ IF',
                description:
                    'ตอบคำถามสั้น ๆ เพื่อเลือกแผนที่เหมาะกับประสบการณ์และกิจวัตรของคุณ',
                badge: 'แนะนำ',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IfRecommendationScreen(
                      age: age,
                      bmi: bmi,
                      healthResult: healthResult,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _MethodCard(
                icon: Icons.tune_rounded,
                color: AppColors.orange,
                title: 'เลือกรูปแบบ IF เอง',
                description: 'เลือกได้โดยตรงระหว่าง 16/8, 18/6 และ 20/4',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IfManualPlanScreen(
                      age: age,
                      healthResult: healthResult,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'IF ไม่เหมาะกับทุกคน หากมีโรคประจำตัวหรือใช้ยา ควรปรึกษาผู้เชี่ยวชาญก่อนเริ่ม',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description,
      required this.onTap,
      this.badge});
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(99)),
                        child: Text(badge!,
                            style: const TextStyle(
                                color: AppColors.tealDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(description,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.45)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 17, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
