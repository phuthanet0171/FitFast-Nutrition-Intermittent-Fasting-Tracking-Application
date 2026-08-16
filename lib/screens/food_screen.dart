import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
        children: [
          Text('มื้ออาหารวันนี้',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'บันทึกอาหารแต่ละมื้อเพื่ออัปเดตสารอาหารบนหน้าหลัก',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          const _MealCard(
            icon: Icons.free_breakfast_rounded,
            title: 'อาหารเช้า',
            time: '07:00 – 10:00',
            color: Color(0xFFFFB84D),
          ),
          const SizedBox(height: 12),
          const _MealCard(
            icon: Icons.rice_bowl_rounded,
            title: 'อาหารกลางวัน',
            time: '11:00 – 14:00',
            color: AppColors.orange,
          ),
          const SizedBox(height: 12),
          const _MealCard(
            icon: Icons.dinner_dining_rounded,
            title: 'อาหารเย็น',
            time: '17:00 – 20:00',
            color: AppColors.teal,
          ),
          const SizedBox(height: 12),
          const _MealCard(
            icon: Icons.cookie_outlined,
            title: 'ของว่าง',
            time: 'เพิ่มได้ทุกเวลา',
            color: AppColors.blue,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded),
            label: const Text('เพิ่มมื้ออาหาร'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.tealDark,
              side: const BorderSide(color: AppColors.teal),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 3),
                  const Text('ยังไม่ได้บันทึก',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            IconButton.filledTonal(
                onPressed: () {}, icon: const Icon(Icons.add_rounded)),
          ],
        ),
      ),
    );
  }
}
