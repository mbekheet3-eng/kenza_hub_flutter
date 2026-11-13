import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
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
        SnackBar(
          content: Text(AppStrings.of(context)!.signupIncomplete),
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
            title: Text(AppStrings.of(dialogContext)!.accountCreated),
            content: Text(AppStrings.of(dialogContext)!.emailConfirmationNext),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                },
                child: Text(AppStrings.of(dialogContext)!.signupSuccessOk),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.of(context)!.signupFailed}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.signupTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(AppStrings.of(context)!.signupJoinTitle, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(AppStrings.of(context)!.signupIntro),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: AppStrings.of(context)!.signupNameLabel,
                helperText: AppStrings.of(context)!.signupNameHint,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: AppStrings.of(context)!.email,
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            Text(AppStrings.of(context)!.signupGenderRequired, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            RadioGroup<String>(
              groupValue: _gender,
              onChanged: (value) {
                if (_busy || value == null) return;
                setState(() => _gender = value);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'male',
                    title: Text(AppStrings.of(context)!.male),
                    contentPadding: EdgeInsets.zero,
                    enabled: !_busy,
                  ),
                  RadioListTile<String>(
                    value: 'female',
                    title: Text(AppStrings.of(context)!.female),
                    contentPadding: EdgeInsets.zero,
                    enabled: !_busy,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: AppStrings.of(context)!.passwordMinEight,
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
              decoration: InputDecoration(
                labelText: AppStrings.of(context)!.confirmPassword,
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acceptedTerms,
              onChanged: _busy ? null : (value) => setState(() => _acceptedTerms = value ?? false),
              title: Text(AppStrings.of(context)!.signupAcceptTerms),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const CircularProgressIndicator() : Text(AppStrings.of(context)!.createAccount),
            ),
          ],
        ),
      ),
    );
  }
}
