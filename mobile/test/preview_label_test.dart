import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/orang_tua/orang_tua_dashboard.dart';

void main() {
  group('Label demo', () {
    testWidgets('menampilkan label DEMO saat demoMode=true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: OrangTuaDashboard(demoMode: true)),
      );
      expect(find.text('DEMO'), findsOneWidget);
    });
  });
}
