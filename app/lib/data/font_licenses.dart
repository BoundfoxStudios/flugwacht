import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hands the bundled fonts to the license page: they ship as plain assets, so
/// nothing else would ever register their open font licenses.
void registerFontLicenses() => LicenseRegistry.addLicense(_fontLicenses);

const _fontLicenseAssets = {
  'Bebas Neue': 'assets/fonts/OFL-BebasNeue.txt',
  'Barlow': 'assets/fonts/OFL-Barlow.txt',
};

Stream<LicenseEntry> _fontLicenses() async* {
  for (final MapEntry(key: font, value: asset) in _fontLicenseAssets.entries) {
    yield LicenseEntryWithLineBreaks([
      font,
    ], await rootBundle.loadString(asset));
  }
}
