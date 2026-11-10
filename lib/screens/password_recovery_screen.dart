import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

import '../services/auth_service.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 8 || _password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context)!.passwordMismatchOrTooShort)),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await _auth.updatePassword(_password.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context)!.passwordUpdated)),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context)!.passwordUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.of(context)!.accountPasswordTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppStrings.of(context)!.passwordIntro),
          const SizedBox(height: 18),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: AppStrings.of(context)!.password),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: InputDecoration(labelText: AppStrings.of(context)!.confirmPassword),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const CircularProgressIndicator()
                : Text(AppStrings.of(context)!.savePassword),
          ),
        ],
      ),
    );
  }
}
