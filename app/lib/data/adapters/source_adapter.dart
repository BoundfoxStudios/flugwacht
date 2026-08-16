import 'lookup_result.dart';

abstract interface class SourceAdapter {
  Future<LookupResult> lookupByHexAddress(String hexAddress);

  Future<LookupResult> lookupByCallsign(String callsign);

  Future<LookupResult> lookupByRegistration(String registration);
}
