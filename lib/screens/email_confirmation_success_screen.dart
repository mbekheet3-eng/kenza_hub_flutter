import 'package:material_ui/material_ui.dart';

class EmailConfirmationSuccessScreen extends StatelessWidget {
  const EmailConfirmationSuccessScreen({
    super.key,
    required this.onContinue,
    required this.busy,
  });

  final VoidCallback onContinue;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final isArabic = language == 'ar';
    final isFrench = language == 'fr';

    final title = isArabic
        ? 'تم تأكيد بريدك الإلكتروني بنجاح'
        : isFrench
            ? 'Votre adresse e-mail a été confirmée'
            : 'Your email has been confirmed';
    final message = isArabic
        ? 'أهلاً بك في كنزا. تم تفعيل حسابك ويمكنك الآن متابعة استخدام التطبيق.'
        : isFrench
            ? 'Bienvenue sur Kenza. Votre compte est activé et vous pouvez continuer.'
            : 'Welcome to Kenza. Your account is active and you can continue.';
    final button = isArabic
        ? 'متابعة إلى كنزا'
        : isFrench
            ? 'Continuer vers Kenza'
            : 'Continue to Kenza';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 88,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : onContinue,
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
