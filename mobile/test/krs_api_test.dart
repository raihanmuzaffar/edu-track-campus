import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/screens/mahasiswa/krs_tab.dart';
import 'package:mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _classData() => {
  'id': 5,
  'name': 'Kelas A',
  'year': '2026/2027',
  'semester': 'Ganjil',
  'day': 'Senin',
  'start_time': '08:00',
  'end_time': '10:00',
  'status': 'Aktif',
  'course': {'name': 'Basis Data', 'code': 'CS101', 'sks': 3, 'semester': 1},
};

Map<String, dynamic> _enrollmentData() => {
  'id': 9,
  'class_id': 5,
  'status': 'active',
  'class': _classData(),
};

http.Response _response(
  Object? data, {
  int statusCode = 200,
  String? message,
}) => http.Response(
  jsonEncode({'message': message ?? 'ok', 'data': data}),
  statusCode,
);

void main() {
  late MockClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'mock-access-token'});
  });

  tearDown(() {
    client.close();
  });

  testWidgets('creates and drops KRS then refreshes from the backend', (
    tester,
  ) async {
    var krsReads = 0;
    final mutationRequests = <http.Request>[];
    client = MockClient((request) async {
      if (request.url.path.endsWith('/enrollments/my')) {
        krsReads++;
        return _response(
          krsReads == 1 || krsReads >= 3 ? [] : [_enrollmentData()],
        );
      }
      if (request.url.path.endsWith('/classes/list')) {
        return _response({
          'data': [_classData()],
          'total_data': 1,
          'page': 1,
          'limit': 10,
        });
      }
      if (request.url.path.endsWith('/student/academic/summary')) {
        return _response({
          'ipk': 3.75,
          'graded_sks': 3,
          'semesters': [
            {'year': '2026/2027', 'semester': 'Ganjil', 'ips': 3.75},
          ],
        });
      }
      if (request.url.path.endsWith('/enrollments') &&
          request.method == 'POST') {
        mutationRequests.add(request);
        return _response(_enrollmentData(), statusCode: 201);
      }
      if (request.url.path.endsWith('/enrollments/drop') &&
          request.method == 'POST') {
        mutationRequests.add(request);
        return _response(null);
      }
      throw StateError('Unexpected request path.');
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: KrsTab()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tambah kelas ke KRS'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tambah kelas ke KRS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basis Data'));
    await tester.pumpAndSettle();

    expect(find.text('Basis Data'), findsOneWidget);
    expect(mutationRequests.first.url.path.endsWith('/enrollments'), isTrue);
    expect(jsonDecode(mutationRequests.first.body), {'class_id': 5});
    expect(krsReads, 2);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Batalkan kelas'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Batalkan kelas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan kelas').last);
    await tester.pumpAndSettle();

    expect(mutationRequests, hasLength(2));
    expect(
      mutationRequests.last.url.path.endsWith('/enrollments/drop'),
      isTrue,
    );
    expect(jsonDecode(mutationRequests.last.body), {'class_id': 5});
    expect(krsReads, 3);
    expect(find.text('Belum ada kelas di KRS'), findsOneWidget);
  });

  testWidgets('shows backend KRS validation failures without changing state', (
    tester,
  ) async {
    var krsReads = 0;
    client = MockClient((request) async {
      if (request.url.path.endsWith('/enrollments/my')) {
        krsReads++;
        return _response([]);
      }
      if (request.url.path.endsWith('/classes/list')) {
        return _response({
          'data': [_classData()],
        });
      }
      if (request.url.path.endsWith('/student/academic/summary')) {
        return _response({'ipk': 0, 'graded_sks': 0, 'semesters': []});
      }
      if (request.url.path.endsWith('/enrollments') &&
          request.method == 'POST') {
        return _response(
          null,
          statusCode: 400,
          message: 'Jadwal kelas bertabrakan.',
        );
      }
      throw StateError('Unexpected request path.');
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: KrsTab()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tambah kelas ke KRS'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tambah kelas ke KRS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Basis Data'));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal kelas bertabrakan.'), findsOneWidget);
    expect(find.text('Belum ada kelas di KRS'), findsOneWidget);
    expect(krsReads, 1);
  });
}
