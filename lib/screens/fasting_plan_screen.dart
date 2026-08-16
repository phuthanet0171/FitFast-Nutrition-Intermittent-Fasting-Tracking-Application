import 'package:flutter/material.dart';

import '../models/fasting_plan.dart';
import '../models/nutrition_result.dart';
import '../models/user_profile.dart';
import 'main_shell.dart';

class FastingPlanScreen extends StatefulWidget {
  const FastingPlanScreen({
    super.key,
    required this.profile,
    required this.nutrition,
  });

  final UserProfile profile;
  final NutritionResult nutrition;

  @override
  State<FastingPlanScreen> createState() => _FastingPlanScreenState();
}

class _FastingPlanScreenState extends State<FastingPlanScreen> {
  FastingPlan _selected = fastingPlans.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกแผน IF')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'รูปแบบการอดอาหาร',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text('เลือกแผนที่เหมาะกับกิจวัตรของคุณ'),
          const SizedBox(height: 20),
          ...fastingPlans.map(
            (plan) => Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () => setState(() => _selected = plan),
                leading: Icon(
                  _selected == plan
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  plan.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'อด ${plan.fastingHours} ชม. • ทาน ${plan.eatingHours} ชม.\n${plan.description}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainShell()),
                (route) => false,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('เริ่มใช้งาน FitFast'),
            ),
          ),
        ],
      ),
    );
  }
}
