import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _acceptedTerms = false;
  bool _hidePassword = true;
  String? _gender;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 8 ||
        _password.text != _confirm.text ||
        _gender == null ||
        !_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أكمل البيانات واختر النوع ووافق على الشروط'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _auth.signUp(
        displayName: _name.text,
        email: _email.text,
        password: _password.text,
        gender: _gender!,
      );
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('تم إنشاء الحساب'),
            content: const Text('إذا كان تأكيد البريد مفعّلاً، افتح رسالة التأكيد التي أرسلناها إليك ثم سجّل الدخول.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء الحساب: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('انضم إلى كنزة هب', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('حساب واحد للتصفح والبيع وإدارة منتجاتك.'),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'الاسم (الاسم الأول يكفي)',
                helperText: 'يمكنك كتابة اسمك الأول فقط أو الاسم بالكامل.',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Text('النوع (إلزامي)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            RadioGroup<String>(
              groupValue: _gender,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _gender = value),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'male',
                    title: const Text('رجل'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'female',
                    title: const Text('امرأة'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور (8 أحرف على الأقل)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: _hidePassword,
              decoration: const InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acceptedTerms,
              onChanged: _busy ? null : (value) => setState(() => _acceptedTerms = value ?? false),
              title: const Text('أوافق على شروط الاستخدام وسياسة الخصوصية'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const CircularProgressIndicator() : const Text('إنشاء الحساب'),
            ),
          ],
        ),
      ),
    );
  }
}
