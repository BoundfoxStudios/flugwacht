import '../../domain/fix.dart';

sealed class LookupResult {
  const LookupResult();
}

class LookupSuccess extends LookupResult {
  const LookupSuccess(this.fixes);

  final List<Fix> fixes;
}

class LookupNetworkFailure extends LookupResult {
  const LookupNetworkFailure();
}

class LookupStatusFailure extends LookupResult {
  const LookupStatusFailure(this.statusCode);

  final int statusCode;
}

class LookupMalformedPayload extends LookupResult {
  const LookupMalformedPayload();
}
