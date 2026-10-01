import 'package:flutter/material.dart';

import '../models/meal_entry.dart';
import '../theme/app_theme.dart';

extension MealTypeStyle on MealType {
  IconData get icon => switch (this) {
        MealType.breakfast => Icons.free_breakfast_rounded,
        MealType.lunch => Icons.rice_bowl_rounded,
        MealType.dinner => Icons.dinner_dining_rounded,
        MealType.snack => Icons.cookie_outlined,
      };

  Color get color => switch (this) {
        MealType.breakfast => const Color(0xFFFFB84D),
        MealType.lunch => AppColors.orange,
        MealType.dinner => AppColors.teal,
        MealType.snack => AppColors.blue,
      };
}
