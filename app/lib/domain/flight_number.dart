final _pattern = RegExp(
  r'^([A-Z]{2,3}|[A-Z][0-9]|[0-9][A-Z])([0-9]+)([A-Z]{0,2})$',
);
final _whitespace = RegExp(r'\s');
final _leadingZeros = RegExp('^0+(?=.)');

const _maximumNumberLength = 4;

class FlightNumber {
  const FlightNumber(this.airlineCode, this.number);

  /// Splits an airline code and a number off the input following the
  /// standing-data normalisation rules, or returns null when the input does
  /// not describe a flight number.
  static FlightNumber? tryParse(String input) {
    final match = _pattern.firstMatch(
      input.replaceAll(_whitespace, '').toUpperCase(),
    );
    if (match == null) {
      return null;
    }
    final number = match[2]!.replaceFirst(_leadingZeros, '') + match[3]!;
    if (number.length > _maximumNumberLength) {
      return null;
    }
    return FlightNumber(match[1]!, number);
  }

  final String airlineCode;
  final String number;

  String get normalized => '$airlineCode$number';

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
