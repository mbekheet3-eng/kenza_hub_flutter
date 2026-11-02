import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:kenza_hub_flutter/config/app_colors.dart';
import 'package:kenza_hub_flutter/config/app_radius.dart';
import 'package:kenza_hub_flutter/config/app_spacing.dart';
import 'package:kenza_hub_flutter/providers/auth_provider.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';
import 'package:kenza_hub_flutter/core/helpers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isRedirecting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context, AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      _redirectToHome();
    } else if (!mounted) return;

    if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _redirectToHome() {
    if (_isRedirecting || !mounted) return;
    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/home');
    });
  }

  Future<void> _handleSocialSignIn(
    AuthProvider authProvider,
    Future<bool> Function() signIn,
  ) async {
    final launched = await signIn();
    if (!launched && mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).loginTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final strings = AppLocalizations.of(context);
          if (authProvider.isSignedIn) _redirectToHome();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Logo or Image
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.lg),
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        size: 50,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    strings.welcomeBack,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle
                  Text(
                    strings.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: strings.email,
                      hintText: 'example@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return strings.emailRequired;
                      }
                      if (!StringHelpers.isValidEmail(value)) {
                        return strings.invalidEmail;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: strings.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return strings.passwordRequired;
                      }
                      if (value.length < 6) {
                        return strings.passwordMinLength;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Forgot Password
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(AppLocalizations.of(context).forgotPassword),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Login Button
                  ElevatedButton(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleLogin(context, authProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            strings.login,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: Text(
                          strings.or,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Social sign-in
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleSocialSignIn(
                              authProvider,
                              authProvider.signInWithGoogle,
                            ),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(strings.continueWithGoogle),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => _handleSocialSignIn(
                              authProvider,
                              authProvider.signInWithApple,
                            ),
                    icon: const Icon(Icons.phone_iphone),
                    label: Text(strings.continueWithApple),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(strings.noAccount),
                      TextButton(
                        onPressed: () {
                          context.push('/sign-up');
                        },
                        child: Text(
                          strings.signUp,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Guest Login
                  OutlinedButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      strings.continueAsGuest,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
