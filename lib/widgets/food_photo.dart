import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A food photo, or an icon for the food's group when there is no photo.
/// The group is the first letter of the Thai FCD food code.
class FoodPhoto extends StatelessWidget {
  const FoodPhoto({super.key, this.url, this.foodCode, this.size = 56});

  final String? url;
  final String? foodCode;
  final double size;

  static (IconData, Color) groupStyle(String? foodCode) {
    final code = foodCode ?? '';
    // DoH dish table codes: DOH11 dishes, DOH12 desserts, DOH14 snacks.
    final group = code.startsWith('DOH12')
        ? 'M'
        : code.startsWith('DOH')
            ? 'T'
            : code.isEmpty
                ? ''
                : code[0];
    return switch (group) {
      'A' => (Icons.rice_bowl_rounded, const Color(0xFFC9A227)),
      'B' => (Icons.grass_rounded, const Color(0xFF9C7A4E)),
      'C' => (Icons.spa_rounded, const Color(0xFF8D6E63)),
      'D' => (Icons.eco_rounded, const Color(0xFF3FA34D)),
      'E' => (Icons.local_florist_rounded, const Color(0xFFE56B8A)),
      'F' => (Icons.kebab_dining_rounded, const Color(0xFFD9534F)),
      'G' => (Icons.set_meal_rounded, AppColors.blue),
      'H' => (Icons.egg_rounded, const Color(0xFFE0A526)),
      'J' => (Icons.local_drink_rounded, const Color(0xFF6C8EBF)),
      'K' => (Icons.water_drop_rounded, const Color(0xFFD4A017)),
      'M' => (Icons.cake_rounded, const Color(0xFFD96FA8)),
      'N' => (Icons.soup_kitchen_rounded, const Color(0xFFB5652B)),
      'Q' => (Icons.local_cafe_rounded, const Color(0xFF7B5E57)),
      'S' => (Icons.lunch_dining_rounded, AppColors.orange),
      'T' => (Icons.ramen_dining_rounded, AppColors.tealDark),
      'Z' => (Icons.cookie_rounded, const Color(0xFFB07D48)),
      _ => (Icons.restaurant_rounded, AppColors.tealDark),
    };
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final (icon, color) = groupStyle(foodCode);
    final fallback = Container(
      color: color.withValues(alpha: .13),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: size * .5),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .28),
      child: SizedBox(
        width: size,
        height: size,
        child: uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => fallback,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback,
              )
            : fallback,
      ),
    );
  }
}
