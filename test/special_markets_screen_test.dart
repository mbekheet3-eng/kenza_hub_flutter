import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenza_hub_marketplace/l10n/app_strings.dart';
import 'package:kenza_hub_marketplace/l10n/kenza_localizations.dart';
import 'package:kenza_hub_marketplace/screens/special_markets_screen.dart';

void main() {
  testWidgets('shows only the two approved special markets in Arabic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: KenzaLocalizations.delegates,
        home: SpecialMarketsScreen(),
      ),
    );

    expect(find.text('ركن الوكالة'), findsOneWidget);
    expect(find.text('المتاجر الإلكترونية'), findsOneWidget);
    expect(find.text('الأنتيكات والتحف'), findsNothing);
    expect(find.text('الهاند ميد'), findsNothing);
  });

  testWidgets('localizes special market names in English and French', (tester) async {
    for (final locale in const [Locale('en'), Locale('fr')]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: KenzaLocalizations.delegates,
          home: const SpecialMarketsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      if (locale.languageCode == 'en') {
        expect(find.text('Wekala Corner'), findsOneWidget);
        expect(find.text('Online Stores'), findsOneWidget);
      } else {
        expect(find.text('Coin Wekala'), findsOneWidget);
        expect(find.text('Boutiques en ligne'), findsOneWidget);
      }
    }
  });
}
