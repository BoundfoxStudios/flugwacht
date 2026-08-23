final _pattern = RegExp(
  r'^([A-Z]{2,3}|[A-Z][0-9]|[0-9][A-Z])([0-9]+)([A-Z]{0,2})$',
);
final _whitespace = RegExp(r'\s');
final _leadingZeros = RegExp('^0+(?=.)');
final _numberParts = RegExp(r'^([0-9]+)([A-Z]{0,2})$');

const _maximumNumberLength = 4;

/// Airlines file a short number padded to three digits on the wire; a wider
/// padding is not a form aircraft transmit.
const _wireNumberWidth = 3;

class FlightNumber {
  const FlightNumber(this.airlineCode, this.number);

  /// Splits an airline code and a number off the input following the
  /// standing-data normalisation rules, or returns null when the input does
  /// not describe a flight number.
  static FlightNumber? tryParse(String input) {
    final match = _pattern.firstMatch(clean(input));
    if (match == null) {
      return null;
    }
    final number = match[2]!.replaceFirst(_leadingZeros, '') + match[3]!;
    if (number.length > _maximumNumberLength) {
      return null;
    }
    return FlightNumber(match[1]!, number);
  }

  /// The input with case and spacing settled, which is the form the app
  /// stores: it keeps the leading zeros [tryParse] strips.
  static String clean(String input) =>
      input.replaceAll(_whitespace, '').toUpperCase();

  final String airlineCode;
  final String number;

  String get normalized => '$airlineCode$number';

  /// The number in the form an aircraft transmits it: the standing data lists
  /// a short one stripped, the wire carries it padded.
  String get wireNumber => digits.padLeft(_wireNumberWidth, '0') + suffix;

  String get wireForm => '$airlineCode$wireNumber';

  /// The digits alone, without the letters a few numbers carry behind them.
  String get digits => _digitsAndSuffix?.group(1) ?? number;

  String get suffix => _digitsAndSuffix?.group(2) ?? '';

  RegExpMatch? get _digitsAndSuffix => _numberParts.firstMatch(number);

  @override
  bool operator ==(Object other) =>
      other is FlightNumber &&
      other.airlineCode == airlineCode &&
      other.number == number;

  @override
  int get hashCode => Object.hash(airlineCode, number);

  @override
  String toString() => normalized;
}
