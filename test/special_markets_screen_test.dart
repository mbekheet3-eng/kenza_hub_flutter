import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kenza_hub_marketplace/l10n/app_strings.dart';
import 'package:kenza_hub_marketplace/l10n/kenza_localizations.dart';
import 'package:kenza_hub_marketplace/screens/special_markets_screen.dart';

Widget _genderLabels(BuildContext context) {
  final strings = AppStrings.of(context)!;
  return Text(
    '${strings.male} / ${strings.female} / ${strings.genderMan} / ${strings.genderWoman}',
  );
}

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

    expect(find.text('محلات الوكالة'), findsOneWidget);
    expect(find.text('صفحات السوشيال'), findsOneWidget);
    expect(find.text('الأنتيكات والتحف'), findsNothing);
    expect(find.text('الهاند ميد'), findsNothing);
    expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
  });

  testWidgets('uses the approved Arabic gender labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: KenzaLocalizations.delegates,
        home: Builder(
          builder: _genderLabels,
        ),
      ),
    );

    expect(find.text('ذكر / أنثى / ذكر / أنثى'), findsOneWidget);
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
        expect(find.text('Wekala Shops'), findsOneWidget);
        expect(find.text('Social Pages'), findsOneWidget);
      } else {
        expect(find.text('Magasins Wekala'), findsOneWidget);
        expect(find.text('Pages sociales'), findsOneWidget);
      }
    }
  });
}
