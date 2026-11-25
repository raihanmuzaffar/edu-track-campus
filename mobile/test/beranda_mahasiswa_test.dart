import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/mahasiswa/beranda_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockClient client;
  var shouldFail = true;

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'test-access'});
    shouldFail = true;
    client = MockClient((request) async {
      if (shouldFail) {
        throw http.ClientException('network error');
      }
      if (request.url.path.endsWith('/student/academic/summary')) {
        return http.Response(
          jsonEncode({
            'data': {
              'name': 'Test Mahasiswa',
              'nim': '220001',
              'program_studi': 'Teknik Informatika',
              'ipk': 0,
              'planned_sks': 0,
              'graded_sks': 0,
            },
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/api/v1/schedules/my')) {
        return http.Response(jsonEncode({'data': []}), 200);
      }
      if (request.url.path.endsWith('/admin/announcements/list')) {
        return http.Response(jsonEncode({'data': []}), 200);
      }
      return http.Response(jsonEncode({'message': 'not found'}), 404);
    });
    ApiService.setHttpClient(client);
  });

  tearDown(() {
    client.close();
  });

  testWidgets('menampilkan loading, error, empty, dan retry', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BerandaTab()));

    // verifikasi loading awal
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(
      find.text(
        'Tidak dapat terhubung ke server. Periksa jaringan lalu coba lagi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Belum ada jadwal yang tersedia.'),
      300,
    );
    expect(find.text('Belum ada jadwal yang tersedia.'), findsOneWidget);
  });
}
