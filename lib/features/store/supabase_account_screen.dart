import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_config.dart';
import '../../shared/widgets/game_ui.dart';

class SupabaseAccountScreen extends StatefulWidget {
  const SupabaseAccountScreen({super.key});

  @override
  State<SupabaseAccountScreen> createState() => _SupabaseAccountScreenState();
}

class _SupabaseAccountScreenState extends State<SupabaseAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _notice;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !SupabaseConfig.isInitialized) return;
    setState(() {
      _busy = true;
      _notice = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_isSignUp) {
        final result = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          emailRedirectTo: kIsWeb ? Uri.base.origin + Uri.base.path : null,
        );
        if (result.session == null) {
          if (mounted) setState(() => _notice = 'تم إنشاء الطلب. راجع بريدك الإلكتروني لتأكيد الحساب قبل تسجيل الدخول.');
        } else {
          if (mounted) Navigator.of(context).maybePop();
        }
      } else {
        await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) Navigator.of(context).maybePop();
      }
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      final userMessage = message.contains('email not confirmed')
          ? 'تحقق من بريدك الإلكتروني ثم حاول تسجيل الدخول.'
          : message.contains('password') && message.contains('weak')
              ? 'اختر كلمة مرور أقوى ثم أعد المحاولة.'
              : message.contains('rate') || error.statusCode == '429'
                  ? 'تم تجاوز عدد المحاولات المسموح. انتظر قليلاً ثم حاول مجدداً.'
                  : 'تعذر إتمام العملية. تحقق من البيانات وحاول مجدداً.';
      if (mounted) setState(() => _notice = userMessage);
    } catch (_) {
      if (mounted) setState(() => _notice = 'تعذر الاتصال بخدمة الحساب. حاول مجدداً لاحقاً.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) setState(() => _notice = 'تم تسجيل الخروج من الحساب.');
    } catch (_) {
      if (mounted) setState(() => _notice = 'تعذر تسجيل الخروج. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = SupabaseConfig.isInitialized;
    final user = configured ? Supabase.instance.client.auth.currentUser : null;

    return GameScaffold(
      title: 'حساب BOARD KINGS',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(color: aqua.withOpacity(0.14), borderRadius: BorderRadius.circular(17)),
                      child: const Icon(Icons.shield_outlined, color: aqua, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text('حسابك، خزانة واحدة', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 7),
                    const Text('مزامنة رصيد BOARD COINS والمظاهر المملوكة بين جلساتك.', style: TextStyle(color: mutedText)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!configured)
                const _SetupNotice()
              else if (user != null)
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.verified_user_rounded, color: aqua, size: 28),
                      const SizedBox(height: 13),
                      const Text('أنت مسجل الدخول', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const SizedBox(height: 6),
                      Text(user.email ?? 'حساب BOARD KINGS', style: const TextStyle(color: mutedText)),
                      const SizedBox(height: 18),
                      GameActionButton(label: 'تسجيل الخروج', icon: Icons.logout_rounded, onPressed: _busy ? null : _signOut),
                    ],
                  ),
                )
              else
                SurfaceCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('تسجيل الدخول')),
                            ButtonSegment(value: true, label: Text('حساب جديد')),
                          ],
                          selected: {_isSignUp},
                          onSelectionChanged: _busy ? null : (selection) => setState(() {
                            _isSignUp = selection.first;
                            _notice = null;
                          }),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.alternate_email_rounded)),
                          validator: (value) => value == null || !value.contains('@') ? 'أدخل بريداً إلكترونياً صالحاً.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: _isSignUp ? const [AutofillHints.newPassword] : const [AutofillHints.password],
                          decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_outline_rounded)),
                          validator: (value) => value == null || value.length < 8 ? 'استخدم ٨ أحرف على الأقل.' : null,
                        ),
                        if (_notice != null) ...[
                          const SizedBox(height: 13),
                          Text(_notice!, style: const TextStyle(color: gold), textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 18),
                        GameActionButton(
                          label: _isSignUp ? 'إنشاء الحساب' : 'تسجيل الدخول',
                          icon: _isSignUp ? Icons.person_add_alt_1_rounded : Icons.login_rounded,
                          onPressed: _busy ? null : _submit,
                        ),
                        if (_busy) ...[
                          const SizedBox(height: 13),
                          const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                        ],
                        const SizedBox(height: 12),
                        const Text('تُدار الجلسة والمصادقة بواسطة Supabase Auth. لا تضع مفتاح Service Role في التطبيق.', style: TextStyle(color: mutedText, fontSize: 11), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupNotice extends StatelessWidget {
  const _SetupNotice();

  @override
  Widget build(BuildContext context) => const SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.link_off_rounded, color: gold, size: 28),
            SizedBox(height: 12),
            Text('تعذر تهيئة اتصال Supabase', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 7),
            Text('تم ربط إعدادات المشروع بمفتاح العميل العام. تحقّق من اتصال الإنترنت وإعدادات Supabase Auth إذا استمرت المشكلة. لا تستخدم مفتاح service_role داخل التطبيق.', style: TextStyle(color: mutedText)),
          ],
        ),
      );
}
