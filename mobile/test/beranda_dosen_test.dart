import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/screens/dosen/beranda_dosen_tab.dart';
import 'package:mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'mock-access-token'});
  });

  tearDown(() {
    client.close();
  });

  testWidgets('shows a profile response error instead of empty classes', (
    tester,
  ) async {
    var requestedClasses = false;
    client = MockClient((request) async {
      if (request.url.path.endsWith('/users/me')) {
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'name': 'Dosen'},
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/classes/list')) {
        requestedClasses = true;
      }
      return http.Response('{}', 404);
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: BerandaDosenTab()));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Data beranda belum dapat dimuat. Periksa koneksi lalu coba lagi.',
      ),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Tidak ada jadwal kelas untuk hari ini.'), findsNothing);
    expect(requestedClasses, isFalse);
  });

  testWidgets('shows the empty state when the backend returns no classes', (
    tester,
  ) async {
    client = MockClient((request) async {
      if (request.url.path.endsWith('/users/me')) {
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'id': 42, 'name': 'Dosen Uji'},
          }),
          200,
        );
      }
      if (request.url.path.endsWith('/classes/list')) {
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'data': [], 'total_data': 0, 'page': 1, 'limit': 100},
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: BerandaDosenTab()));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada jadwal kelas untuk hari ini.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });
}
