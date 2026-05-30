// Smoke test. (The real coverage is in the engine tests: ao_ini_test,
// char_roundtrip_test, sprite_scanner_test, color_ops_test, animation_test.)
//
// This file also intentionally replaces the default counter-app test that
// `flutter create .` would otherwise generate (which references a non-existent
// `MyApp` and breaks `flutter analyze`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pinsel/src/app.dart';
import 'package:pinsel/src/ui/app_state.dart';

void main() {
  testWidgets('app boots to the home shell without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => AppState(),
        child: const PinselApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
