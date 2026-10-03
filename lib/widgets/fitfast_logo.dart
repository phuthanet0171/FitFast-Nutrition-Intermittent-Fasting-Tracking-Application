import 'package:flutter/material.dart';

/// The FitFast app icon (fork and clock on a teal tile), shown whole.
class FitFastLogo extends StatelessWidget {
  const FitFastLogo({super.key, this.size = 88, this.shadow = false});

  final double size;

  /// A soft drop shadow, for the logo on the dark brand background.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/icons/fitfast_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'FitFast',
    );
    if (!shadow) return image;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF052E26).withValues(alpha: .35),
            blurRadius: size * .4,
            spreadRadius: -size * .06,
            offset: Offset(0, size * .1),
          ),
        ],
      ),
      child: image,
    );
  }
}
