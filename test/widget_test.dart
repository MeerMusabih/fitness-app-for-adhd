// Basic smoke test: app boots without crashing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_reforge/app.dart';

void main() {
  testWidgets('App boots and shows the dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProjectReforgeApp()));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Champion'), findsOneWidget);
  });
}
