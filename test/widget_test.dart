import 'package:flutter_test/flutter_test.dart';
import 'package:we_play/app/app.dart';

void main() {
  testWidgets('WePlayApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const WePlayApp());
    // App should render without errors
    expect(find.text('WE PLAY'), findsWidgets);
  });
}
