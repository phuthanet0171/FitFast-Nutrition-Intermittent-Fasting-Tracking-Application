import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FoodPhoto extends StatelessWidget {
  const FoodPhoto({super.key, this.url, this.size = 56});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final fallback = Container(
        color: AppColors.mint,
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant, color: AppColors.tealDark));
    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
            width: size,
            height: size,
            child: uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
                ? Image.network(url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => fallback,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : fallback)
                : fallback));
  }
}
