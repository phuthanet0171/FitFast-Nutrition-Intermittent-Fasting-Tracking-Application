import 'package:fitfast/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FitFast dashboard smoke test', (tester) async {
    await tester.pumpWidget(const FitFastApp());

    expect(find.text('FitFast'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('สมัครสมาชิก'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
  });
}
