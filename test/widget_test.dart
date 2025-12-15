// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sijil/core/storage/app_preferences.dart';
import 'package:sijil/main.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final AppPreferences appPreferences = await AppPreferences.load();
    Get.put<AppPreferences>(appPreferences, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Splash screen displays while session initializes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AttendanceApp());

    // Splash screen shows a progress indicator while the AuthController restores a session.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
