import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('ExpenseTrackerApp builds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pump();
    expect(find.byType(ExpenseTrackerApp), findsOneWidget);
  });
}
