import 'package:flugwacht/domain/source_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cycles to the next selectable source', () {
    expect(nextSelectableSourceId(SourceId.adsblol), SourceId.adsbfi);
  });

  test('wraps around at the end of the cycle', () {
    expect(nextSelectableSourceId(SourceId.adsbfi), SourceId.adsblol);
  });

  test('leaves a source that is not selectable for the first one', () {
    expect(nextSelectableSourceId(SourceId.airplanes), SourceId.adsblol);
  });
}
