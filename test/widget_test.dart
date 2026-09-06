// Basic smoke test - checks that the app builds without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:niceplace_app/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const NicePlaceApp());

    // App load hote hi frame settle hone dete hain (splash/network calls ke liye)
    await tester.pump();

    // Sirf itna confirm karna hai ki MaterialApp successfully build ho gaya
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}