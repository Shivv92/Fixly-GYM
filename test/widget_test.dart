import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fixly_gym/main.dart';

void main() {
  testWidgets('login screen displays its fields and action', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('FIXLY GYM'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Access Dashboard'), findsOneWidget);
  });
}
