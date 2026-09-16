import 'package:flutter_test/flutter_test.dart';
import 'package:munkalap_program/main.dart';

void main() {
  testWidgets('MunkalapApp betöltési teszt', (WidgetTester tester) async {
    await tester.pumpWidget(const MunkalapApp());
    expect(find.text('Új Digitális Munkalap'), findsOneWidget);
  });
}