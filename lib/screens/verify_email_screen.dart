import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'authenticated_home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = false;

  Future<void> _check() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.refreshSession();
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthenticatedHomeScreen()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ยังไม่พบการยืนยัน กรุณาเปิดลิงก์ในอีเมลก่อน')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
        emailRedirectTo: 'fitfast://login-callback',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งอีเมลยืนยันอีกครั้งแล้ว')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.mark_email_unread_outlined,
                  size: 82, color: AppColors.teal),
              const SizedBox(height: 24),
              Text('ยืนยันอีเมลของคุณ',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text('เราส่งลิงก์ยืนยันไปที่\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 30),
              FilledButton(
                onPressed: _loading ? null : _check,
                child:
                    Text(_loading ? 'กำลังตรวจสอบ...' : 'ฉันยืนยันอีเมลแล้ว'),
              ),
              TextButton(
                  onPressed: _resend, child: const Text('ส่งอีเมลอีกครั้ง')),
              TextButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (_) => false,
                ),
                child: const Text('กลับไปเข้าสู่ระบบ'),
              ),
            ]),
          ),
        ),
      );
}
