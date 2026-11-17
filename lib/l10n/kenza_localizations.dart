import 'package:material_ui/material_ui.dart';

import 'app_strings.dart';

/// Keeps Kenza's generated strings and Material UI delegates in sync.
abstract final class KenzaLocalizations {
  static final List<LocalizationsDelegate<dynamic>> delegates = [
    AppStrings.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ];
}
