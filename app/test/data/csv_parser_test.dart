import 'package:flugwacht/data/csv_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits plain rows into fields', () {
    expect(parseCsvRows('a,b,c\nd,e,f\n'), [
      ['a', 'b', 'c'],
      ['d', 'e', 'f'],
    ]);
  });

  test('keeps commas inside quoted fields', () {
    expect(parseCsvRows('ACR,"Aerocenter, Escuela de Formación",ACR\n'), [
      ['ACR', 'Aerocenter, Escuela de Formación', 'ACR'],
    ]);
  });

  test('unescapes doubled quotes inside quoted fields', () {
    expect(parseCsvRows('a,"say ""hello""",c\n'), [
      ['a', 'say "hello"', 'c'],
    ]);
  });

  test('keeps empty fields', () {
    expect(parseCsvRows('1B,Abacus International,,1B,,\n'), [
      ['1B', 'Abacus International', '', '1B', '', ''],
    ]);
  });

  test('drops the byte order mark from the first field', () {
    expect(parseCsvRows('\u{FEFF}Code,Name\n'), [
      ['Code', 'Name'],
    ]);
  });

  test('reads rows separated by carriage return line feed', () {
    expect(parseCsvRows('a,b\r\nc,d\r\n'), [
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });

  test('reads a last row without a trailing line break', () {
    expect(parseCsvRows('a,b\nc,d'), [
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });

  test('ignores blank lines', () {
    expect(parseCsvRows('a,b\n\n\nc,d\n'), [
      ['a', 'b'],
      ['c', 'd'],
    ]);
  });

  test('keeps line breaks inside quoted fields', () {
    expect(parseCsvRows('a,"two\nlines"\n'), [
      ['a', 'two\nlines'],
    ]);
  });
}
