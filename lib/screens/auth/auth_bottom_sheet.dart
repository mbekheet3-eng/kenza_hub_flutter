import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:kenza_hub_flutter/providers/auth_provider.dart';
import 'package:kenza_hub_flutter/core/helpers.dart';
import 'package:kenza_hub_flutter/core/localization/app_localizations.dart';

enum AuthSheetMode { login, signUp }

/// Shared, reusable authentication bottom sheet.
class AuthBottomSheet {
  const AuthBottomSheet._();

  static Future<void> show(
    BuildContext context, {
    AuthSheetMode initialMode = AuthSheetMode.login,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.68,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => _AuthSheetContent(
          initialMode: initialMode,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _AuthSheetContent extends StatefulWidget {
  const _AuthSheetContent({
    required this.initialMode,
    required this.scrollController,
  });

  final AuthSheetMode initialMode;
  final ScrollController scrollController;

  @override
  State<_AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends State<_AuthSheetContent> {
  static const _red = Color(0xFFC62828);
  static const _navy = Color(0xFF0F172A);

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late AuthSheetMode _mode;
  bool _hidePassword = true;
  bool _hideConfirmation = true;
  bool _acceptedTerms = false;

  bool get _isSignUp => _mode == AuthSheetMode.signUp;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _switchMode(AuthSheetMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _acceptedTerms = false;
      _formKey.currentState?.reset();
    });
    context.read<AuthProvider>().clearError();
  }

  Future<void> _submit(AuthProvider auth) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isSignUp) {
      if (_password.text != _confirmPassword.text) {
        _message(AppLocalizations.of(context).passwordsDoNotMatch);
        return;
      }
      if (!_acceptedTerms) {
        _message(AppLocalizations.of(context).termsRequired);
        return;
      }
    }

    final success = _isSignUp
        ? await auth.signUp(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _name.text.trim(),
          )
        : await auth.signIn(
            email: _email.text.trim(),
            password: _password.text,
          );

    if (!mounted) return;
    if (success) {
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go('/home');
    } else if (auth.error != null) {
      _message(auth.error!);
    }
  }

  Future<void> _socialSignIn(
    AuthProvider auth,
    Future<bool> Function() action,
  ) async {
    if (_isSignUp && !_acceptedTerms) {
      _message(AppLocalizations.of(context).termsRequired);
      return;
    }
    final started = await action();
    if (!mounted) return;
    if (!started && auth.error != null) _message(auth.error!);
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _red,
      ),
    );
  }

  InputDecoration _decoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _navy),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _red, width: 1.4),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: hidden,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      decoration: _decoration(
        label,
        Icons.lock_outline,
        suffix: IconButton(
          onPressed: toggle,
          icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context).passwordRequired;
            }
            if (value.length < 6) {
              return AppLocalizations.of(context).passwordMinLength;
            }
            return null;
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final auth = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isSignUp ? strings.signupTitle : strings.loginTitle,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      _isSignUp ? strings.signupSubtitle : strings.loginSubtitle,
                      style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: _decoration(strings.fullName, Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return strings.nameRequired;
                          if (value.trim().length < 3) return strings.nameMinLength;
                          return null;
                        },
                      ),
                      const SizedBox(height: 13),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      decoration: _decoration(strings.email, Icons.email_outlined),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return strings.emailRequired;
                        if (!StringHelpers.isValidEmail(value.trim())) return strings.invalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _passwordField(
                      label: strings.password,
                      controller: _password,
                      hidden: _hidePassword,
                      toggle: () => setState(() => _hidePassword = !_hidePassword),
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 13),
                      _passwordField(
                        label: strings.confirmPassword,
                        controller: _confirmPassword,
                        hidden: _hideConfirmation,
                        toggle: () => setState(() => _hideConfirmation = !_hideConfirmation),
                        validator: (value) {
                          if (value == null || value.isEmpty) return strings.confirmPasswordRequired;
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: _red,
                        title: const Text(
                          'أوافق على الشروط والأحكام وسياسة الخصوصية',
                          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        ),
                      ),
                    ] else
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/forgot-password');
                          },
                          child: Text(strings.forgotPassword),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : () => _submit(auth),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _isSignUp ? strings.signUp : strings.login,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(strings.or, style: const TextStyle(color: Color(0xFF64748B))),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 13),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : () => _socialSignIn(auth, auth.signInWithGoogle),
                      icon: const Icon(Icons.g_mobiledata, size: 27),
                      label: Text(strings.continueWithGoogle),
                    ),
                    const SizedBox(height: 9),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : () => _socialSignIn(auth, auth.signInWithApple),
                      icon: const Icon(Icons.phone_iphone),
                      label: Text(strings.continueWithApple),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isSignUp ? 'لديك حساب بالفعل؟' : strings.noAccount),
                        TextButton(
                          onPressed: () => _switchMode(_isSignUp ? AuthSheetMode.login : AuthSheetMode.signUp),
                          child: Text(
                            _isSignUp ? strings.login : strings.signUp,
                            style: const TextStyle(color: _red, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    if (!_isSignUp)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                        child: Text(strings.continueAsGuest),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Route fallback for authentication-required actions. It keeps a guest
/// marketplace screen behind the modal instead of presenting a full-page form.
class AuthBottomSheetRoute extends StatefulWidget {
  const AuthBottomSheetRoute({
    super.key,
    required this.initialMode,
    required this.background,
  });

  final AuthSheetMode initialMode;
  final Widget background;

  @override
  State<AuthBottomSheetRoute> createState() => _AuthBottomSheetRouteState();
}

class _AuthBottomSheetRouteState extends State<AuthBottomSheetRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AuthBottomSheet.show(context, initialMode: widget.initialMode);
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) => widget.background;
}
