// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caroflags/login.dart';

void main() {
  testWidgets('Login page renders correctly', (WidgetTester tester) async {
    // Build the login page wrapped in MaterialApp
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify the login page renders key elements
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
