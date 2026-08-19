import 'package:flutter_test/flutter_test.dart';
import 'package:pawnder/main.dart';

void main() {
  testWidgets('Pawnder app smoke test', (WidgetTester tester) async {
    // Încarcă aplicația Pawnder
    await tester.pumpWidget(const PawnderApp());

    // Verifică dacă titlul "Pawnder" apare pe ecran
    expect(find.text('Pawnder'), findsOneWidget);
  });
}