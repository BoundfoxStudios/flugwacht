final _registrationPattern = RegExp(r'^[A-Z0-9-]{2,10}$');
final _hexAddressPattern = RegExp('^[0-9a-f]{6}\$');

/// The registration as it is stored, or null when the input is no
/// registration.
String? normalizedRegistration(String input) {
  final registration = input.trim().toUpperCase();
  return _registrationPattern.hasMatch(registration) ? registration : null;
}

/// The icao 24 bit address as it is stored — lower case, matching the `hex`
/// field of the readsb sources — or null when the input is no hex address.
String? normalizedHexAddress(String input) {
  final hexAddress = input.trim().toLowerCase();
  return _hexAddressPattern.hasMatch(hexAddress) ? hexAddress : null;
}
