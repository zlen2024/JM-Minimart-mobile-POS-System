import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jm_mini_mart_propos/main.dart'; // Ensure correct import

void main() {
  testWidgets('App basic shell test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: JMMiniMartApp()));

    // Verify that our POS dashboard text exists.
    expect(find.text('JM Mini Mart'), findsOneWidget);
    expect(find.byIcon(Icons.point_of_sale), findsOneWidget);
  });
}
