import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/cloud_profile_service.dart';
import '../theme/app_theme.dart';
import 'authenticated_home_screen.dart';
import 'verify_email_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _googleLoading = false;

  Future<void> _continueWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'fitfast://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message), backgroundColor: AppColors.orange),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  void _openEmail(bool registering) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EmailAuthScreen(registering: registering),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7FAF9),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 112,
                        height: 112,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: Image.asset(
                          'assets/icons/fitfast_launcher_foreground.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'FitFast',
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'FitFast',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ดูแลสุขภาพให้เป็นเรื่องง่าย',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(flex: 2),
                      FilledButton(
                        onPressed: () => _openEmail(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: const Text('สมัครสมาชิก'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _openEmail(false),
                        style: _secondaryButtonStyle(),
                        child: const Text('เข้าสู่ระบบ'),
                      ),
                      const _AuthDivider(),
                      OutlinedButton.icon(
                        onPressed: _googleLoading ? null : _continueWithGoogle,
                        style: _secondaryButtonStyle(
                          color: AppColors.navy,
                          borderColor: AppColors.border,
                        ),
                        icon: _googleLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const _GoogleMark(),
                        label: Text(_googleLoading
                            ? 'กำลังเปิด...'
                            : 'เข้าสู่ระบบด้วย Google'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  ButtonStyle _secondaryButtonStyle({
    Color color = AppColors.tealDark,
    Color borderColor = AppColors.teal,
  }) =>
      OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(color: borderColor, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );
}

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key, required this.registering});

  final bool registering;

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  late final bool _registering = widget.registering;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  String? _emailError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอกอีเมล';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return null;
  }

  String? _usernameError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอกชื่อผู้ใช้';
    if (text.length < 3 || text.length > 20) {
      return 'ชื่อผู้ใช้ต้องมี 3–20 ตัวอักษร';
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(text)) {
      return 'ใช้ได้เฉพาะภาษาอังกฤษ ตัวเลข จุด ขีดล่าง และขีดกลาง';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _loading) return;
    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;
      if (_registering) {
        if (client.auth.currentSession == null) {
          final response = await client.auth.signUp(
            email: _email.text.trim(),
            password: _password.text,
            emailRedirectTo: 'fitfast://login-callback',
            data: {'username': _username.text.trim()},
          );
          if (!mounted) return;
          if (response.session == null) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: _email.text.trim()),
            ));
            return;
          }
        }
        await CloudProfileService.instance.saveUsername(_username.text.trim());
        await client.auth.updateUser(
          UserAttributes(data: {'username': _username.text.trim()}),
        );
      } else {
        await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthenticatedHomeScreen()),
        (_) => false,
      );
    } on PostgrestException catch (error) {
      if (CloudProfileService.instance.isDuplicateUsername(error)) {
        _showError('ชื่อผู้ใช้นี้ถูกใช้แล้ว กรุณาเลือกชื่ออื่น');
      } else {
        _showError('บันทึกชื่อผู้ใช้ไม่สำเร็จ กรุณาลองใหม่');
      }
    } on AuthException catch (error) {
      _showError(_friendly(error.message));
    } catch (_) {
      _showError('เชื่อมต่อระบบสมาชิกไม่สำเร็จ กรุณาตรวจอินเทอร์เน็ต');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(String message) {
    final value = message.toLowerCase();
    if (value.contains('invalid login credentials')) {
      return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
    }
    if (value.contains('already registered')) {
      return 'อีเมลนี้สมัครสมาชิกแล้ว';
    }
    if (value.contains('email not confirmed')) {
      return 'กรุณายืนยันอีเมลก่อนเข้าสู่ระบบ';
    }
    if (value.contains('rate limit')) {
      return 'ลองหลายครั้งเกินไป กรุณารอสักครู่';
    }
    return message;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.orange),
    );
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลืมรหัสผ่าน'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'อีเมล',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('ส่งลิงก์'),
          ),
        ],
      ),
    );
    // showDialog completes before its reverse transition has fully detached
    // the TextField, so defer disposal until that transition is complete.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (result == null) return;
    if (_emailError(result) != null) {
      _showError('กรุณากรอกอีเมลให้ถูกต้อง');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        result,
        redirectTo: 'fitfast://login-callback',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ส่งลิงก์ตั้งรหัสผ่านใหม่แล้ว กรุณาตรวจอีเมล')),
      );
    } on AuthException catch (error) {
      _showError(_friendly(error.message));
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF6F9F8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.7),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF3FAF7),
        body: Stack(
          children: [
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1BA184), Color(0xFF0D7863)],
                ),
              ),
            ),
            const Positioned(
              top: -95,
              right: -80,
              child: _DecorativeCircle(size: 240, color: Color(0x16FFFFFF)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 20, 0),
                      child: Row(
                        children: [
                          Material(
                            color: Colors.white.withValues(alpha: .16),
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'ย้อนกลับ',
                              onPressed: () => Navigator.maybePop(context),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          const _CompactBrand(light: true),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                      child: Text(
                        _registering ? 'สมัครสมาชิก' : 'เข้าสู่ระบบ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.6,
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: .09),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_registering) ...[
                                  TextFormField(
                                    controller: _username,
                                    keyboardType: TextInputType.text,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username
                                    ],
                                    autocorrect: false,
                                    maxLength: 20,
                                    validator: _usernameError,
                                    decoration: _fieldDecoration(
                                      label: 'ชื่อผู้ใช้',
                                      hint: 'เช่น fitfast_user',
                                      icon: Icons.person_outline_rounded,
                                    ).copyWith(counterText: ''),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  validator: _emailError,
                                  decoration: _fieldDecoration(
                                    label: 'อีเมล',
                                    hint: 'name@example.com',
                                    icon: Icons.mail_outline_rounded,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  textInputAction: _registering
                                      ? TextInputAction.next
                                      : TextInputAction.done,
                                  autofillHints: [
                                    _registering
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  validator: (value) => (value ?? '').length < 8
                                      ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'
                                      : null,
                                  onFieldSubmitted:
                                      _registering ? null : (_) => _submit(),
                                  decoration: _fieldDecoration(
                                    label: 'รหัสผ่าน',
                                    helper: _registering
                                        ? 'ใช้อย่างน้อย 8 ตัวอักษร'
                                        : null,
                                    icon: Icons.lock_outline_rounded,
                                    suffix: IconButton(
                                      tooltip: _obscure
                                          ? 'แสดงรหัสผ่าน'
                                          : 'ซ่อนรหัสผ่าน',
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(_obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                    ),
                                  ),
                                ),
                                if (_registering) ...[
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordConfirmation,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.newPassword
                                    ],
                                    validator: (value) =>
                                        value != _password.text
                                            ? 'รหัสผ่านทั้งสองช่องไม่ตรงกัน'
                                            : null,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: _fieldDecoration(
                                      label: 'ยืนยันรหัสผ่าน',
                                      icon: Icons.verified_user_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ] else
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed:
                                          _loading ? null : _forgotPassword,
                                      child: const Text('ลืมรหัสผ่าน?'),
                                    ),
                                  ),
                                FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(58),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_registering
                                          ? 'สมัครสมาชิก'
                                          : 'เข้าสู่ระบบ'),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _registering
                                            ? 'มีบัญชีอยู่แล้ว?'
                                            : 'ยังไม่มีบัญชี?',
                                        style: const TextStyle(
                                            color: AppColors.muted),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () => Navigator.of(context)
                                                  .pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EmailAuthScreen(
                                                    registering: !_registering,
                                                  ),
                                                ),
                                              ),
                                      child: Text(_registering
                                          ? 'เข้าสู่ระบบ'
                                          : 'สมัครสมาชิก'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: light ? Colors.white : AppColors.mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/icons/fitfast_launcher_foreground.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'FitFast',
            style: TextStyle(
              color: light ? Colors.white : AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
        ],
      );
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('หรือ',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
      );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Text('G',
            style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w900,
                fontSize: 14)),
      );
}
