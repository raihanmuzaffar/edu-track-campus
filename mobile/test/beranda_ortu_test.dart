import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/orang_tua_preview_data.dart';
import 'package:mobile/screens/orang_tua/beranda_tab.dart';

void main() {
  group('Beranda Orang Tua unavailable state', () {
    testWidgets('menampilkan pesan profil anak belum tersedia', Function(
      WidgetTester tester,
      expect(find.text('Profil anak belum tersedia'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    }) ;
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BerandaTab(
              data: OrangTuaDashboardData.empty,
              onNavigate: (_) => {},
            ),
          ),
        ),
      );
      expect(find.text('Profil anak belum tersedia'), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
    })
  });
}
