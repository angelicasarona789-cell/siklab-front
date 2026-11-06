// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siklab/main.dart';
import 'package:siklab/screens/modules_screen.dart';
import 'package:siklab/theme/app_theme.dart';

void main() {
  testWidgets('App starts and shows splash screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiklabApp());

    // Verify that the splash screen shows the app name.
    expect(find.text('Siklab'), findsOneWidget);
  });

  testWidgets('Java lesson intro includes the detailed language overview',
      (WidgetTester tester) async {
    final notifier = ThemeNotifier();

    await tester.pumpWidget(
      SiklabThemeScope(
        notifier: notifier,
        child: const MaterialApp(
          home: ModulesScreen(languageFilter: 'Java'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What is Java?'), findsOneWidget);
    expect(find.text('Why Use Java?'), findsOneWidget);
  });
}
