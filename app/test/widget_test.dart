import 'package:flugwacht/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  testWidgets('renders every icon of the design icon set', (tester) async {
    await tester.pumpWidget(const FlugwachtApp());

    expect(find.byType(FaIcon), findsNWidgets(8));
  });
}
