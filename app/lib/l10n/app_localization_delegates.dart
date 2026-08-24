import 'package:material_ui/material_ui.dart';

import 'app_localizations.g.dart';

// gen_l10n only knows flutter_localizations, whose MaterialLocalizations is
// the legacy package:flutter/material.dart type; material_ui looks up its own
// and would find none, so AppLocalizations.localizationsDelegates leaves every
// locale but English without material strings.
const appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];
