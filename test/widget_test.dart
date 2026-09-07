import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/main.dart';

void main() {
  testWidgets('App launches and shows the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });
}
