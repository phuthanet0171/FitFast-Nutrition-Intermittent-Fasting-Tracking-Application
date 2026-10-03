import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/brand_backdrop.dart';
import '../widgets/fitfast_logo.dart';
import 'auth_screen.dart';
import 'authenticated_home_screen.dart';

/// A short branded start. The saved session is read synchronously, so the
/// screen only stays for its entrance animation (well under a second).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 700);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: SplashScreen.duration);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: const Interval(0, .6));
  late final Animation<double> _scale = Tween<double>(begin: .92, end: 1)
      .animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_open);
  }

  void _open() {
    if (!mounted) return;
    final destination = Supabase.instance.client.auth.currentSession == null
        ? const AuthScreen()
        : const AuthenticatedHomeScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, animation, secondaryAnimation) => destination,
      transitionsBuilder: (_, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: BrandBackdrop.middle,
          body: BrandBackdrop(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FitFastLogo(size: 112, shadow: true),
                      SizedBox(height: 22),
                      Text(
                        'FitFast',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'กินดี อดเป็น สุขภาพดี',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
