import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Deep teal brand background with faint rings and an orange arc that echo
/// the clock in the FitFast logo. Used by the splash and sign-in screens.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child, this.arc = true});

  static const top = Color(0xFF0B5E4E);
  static const middle = Color(0xFF13806A);
  static const bottom = Color(0xFF1BA58A);

  final Widget child;

  /// The orange arc; off where it would sit behind text.
  final bool arc;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, middle, bottom],
          ),
        ),
        child: CustomPaint(painter: _RingsPainter(arc: arc), child: child),
      );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.arc});

  final bool arc;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: .08);
    final corner = Offset(size.width * 1.02, size.height * .02);
    for (final radius in [90.0, 150.0, 210.0]) {
      canvas.drawCircle(corner, radius, ring);
    }
    canvas.drawCircle(Offset(-size.width * .08, size.height * .58), 130, ring);

    if (arc) {
      canvas.drawArc(
        Rect.fromCircle(center: corner, radius: 150),
        math.pi * .55,
        math.pi * .32,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..color = AppColors.orange,
      );
    }

    final glow = Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: .10),
        Colors.white.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(
          center: Offset(size.width * .5, size.height * .3),
          radius: size.width * .7));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => oldDelegate.arc != arc;
}
