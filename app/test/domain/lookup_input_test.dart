import 'package:flugwacht/domain/lookup_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes a registration to trimmed upper case', () {
    expect(normalizedRegistration('d-aima'), 'D-AIMA');
    expect(normalizedRegistration('  n123ab '), 'N123AB');
  });

  test('rejects a registration outside two to ten characters', () {
    expect(normalizedRegistration('d'), isNull);
    expect(normalizedRegistration(''), isNull);
    expect(normalizedRegistration('D-AIMA12345'), isNull);
  });

  test('rejects a registration with characters outside letters, digits and '
      'dashes', () {
    expect(normalizedRegistration('D_AIMA'), isNull);
    expect(normalizedRegistration('D AIMA'), isNull);
    expect(normalizedRegistration('D-AIMÄ'), isNull);
  });

  test('normalizes a hex address to lower case', () {
    expect(normalizedHexAddress('3C6444'), '3c6444');
    expect(normalizedHexAddress(' 3c6444 '), '3c6444');
  });

  test('rejects anything but exactly six hex digits', () {
    expect(normalizedHexAddress('3C64'), isNull);
    expect(normalizedHexAddress('3C64444'), isNull);
    expect(normalizedHexAddress('XYZXYZ'), isNull);
    expect(normalizedHexAddress(''), isNull);
  });
}
