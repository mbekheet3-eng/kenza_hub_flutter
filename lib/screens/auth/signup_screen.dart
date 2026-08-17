import 'package:flutter/material.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      return false;
    }

    if (!_agreeToTerms) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).signupTitle),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).joinUs,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).signupSubtitle,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),

            // Full Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: AppLocalizations.of(context).fullName,
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: AppLocalizations.of(context).email,
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).password,
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: AppLocalizations.of(context).confirmPassword,
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 16),

            // Terms & Conditions
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() => _agreeToTerms = value ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _agreeToTerms = !_agreeToTerms);
                    },
                    child: Text(
                      AppLocalizations.of(context).agreeToTerms,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateForm()
                    ? () {
                        // TODO: Implement signup
                        context.pushReplacement('/');
                      }
                    : null,
                child: Text(AppLocalizations.of(context).signupTitle),
              ),
            ),
            const SizedBox(height: 16),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context).haveAccount),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(AppLocalizations.of(context).login),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
