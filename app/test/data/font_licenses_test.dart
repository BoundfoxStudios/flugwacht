import 'package:flugwacht/data/font_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<LicenseEntry>> registeredLicenses() {
  LicenseRegistry.reset();
  addTearDown(LicenseRegistry.reset);
  registerFontLicenses();
  return LicenseRegistry.licenses.toList();
}

void main() {
  // Reading the license assets is real I/O, so these run outside the fake
  // async zone a widget test would install.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers the license of every bundled font', () async {
    final entries = await registeredLicenses();

    expect(
      entries.expand((entry) => entry.packages),
      containsAll(['Bebas Neue', 'Barlow']),
    );
  });

  test('carries the open font license text of every font', () async {
    final entries = await registeredLicenses();

    expect(entries, hasLength(2));
    for (final entry in entries) {
      expect(
        entry.paragraphs.map((paragraph) => paragraph.text).join('\n'),
        contains('SIL Open Font License'),
        reason: 'missing in ${entry.packages}',
      );
    }
  });
}
