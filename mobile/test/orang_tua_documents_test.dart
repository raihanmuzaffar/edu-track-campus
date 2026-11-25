import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/orang_tua_api_mapper.dart';
import 'package:mobile/screens/orang_tua/informasi_tab.dart';
import 'package:mobile/screens/orang_tua/orang_tua_dashboard.dart';
import 'package:mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object? data, {int statusCode = 200}) =>
    http.Response(jsonEncode({'message': 'ok', 'data': data}), statusCode);

void main() {
  late MockClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'mock-access-token'});
  });

  tearDown(() {
    client.close();
  });

  testWidgets('requests documents only for a server-linked child', (
    tester,
  ) async {
    final documentRequests = <http.Request>[];
    client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/users/me')) {
        return _response({
          'name': 'Orang Tua Uji',
          'email': 'parent@example.test',
        });
      }
      if (path.endsWith('/parent/children')) {
        return _response([
          {'id': 12, 'name': 'Anak Uji', 'nim': 'TEST-12'},
        ]);
      }
      if (path.endsWith('/parent/announcements')) return _response([]);
      if (path.endsWith('/parent/child/documents')) {
        documentRequests.add(request);
        return _response([
          {
            'id': 8,
            'student_id': 12,
            'type': 'Transkrip',
            'semester': '2025/2026',
            'status': 'Lengkap',
            'date': '2026-02-10T00:00:00Z',
          },
        ]);
      }
      if (path.endsWith('/parent/child/profile')) {
        return _response({
          'name': 'Anak Uji',
          'nim': 'TEST-12',
          'program_studi': 'Sistem Informasi',
        });
      }
      if (path.endsWith('/parent/child/summary')) {
        return _response({'graded_sks': 0, 'semesters': []});
      }
      if (path.endsWith('/parent/child/attendances') ||
          path.endsWith('/parent/child/schedules') ||
          path.endsWith('/parent/child/ukt')) {
        return _response([]);
      }
      throw StateError('Unexpected request path.');
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: OrangTuaDashboard()));
    await tester.pumpAndSettle();

    expect(documentRequests, hasLength(1));
    expect(documentRequests.single.url.queryParameters, {'child_id': '12'});
  });

  testWidgets('does not request child documents when no child is linked', (
    tester,
  ) async {
    var requestedChildData = false;
    client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/users/me')) {
        return _response({
          'name': 'Orang Tua Uji',
          'email': 'parent@example.test',
        });
      }
      if (path.endsWith('/parent/children')) return _response([]);
      if (path.endsWith('/parent/announcements')) return _response([]);
      if (path.contains('/parent/child/')) requestedChildData = true;
      throw StateError('Unexpected request path.');
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: OrangTuaDashboard()));
    await tester.pumpAndSettle();

    expect(requestedChildData, isFalse);
    expect(find.text('Profil anak belum tersedia'), findsOneWidget);
  });

  testWidgets('shows an explicit error if the documents endpoint fails', (
    tester,
  ) async {
    client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/users/me')) {
        return _response({
          'name': 'Orang Tua Uji',
          'email': 'parent@example.test',
        });
      }
      if (path.endsWith('/parent/children')) {
        return _response([
          {'id': 12, 'name': 'Anak Uji', 'nim': 'TEST-12'},
        ]);
      }
      if (path.endsWith('/parent/announcements')) return _response([]);
      if (path.endsWith('/parent/child/documents')) {
        return _response(null, statusCode: 500);
      }
      if (path.endsWith('/parent/child/profile')) {
        return _response({
          'name': 'Anak Uji',
          'nim': 'TEST-12',
          'program_studi': 'Sistem Informasi',
        });
      }
      if (path.endsWith('/parent/child/summary')) {
        return _response({'graded_sks': 0, 'semesters': []});
      }
      if (path.endsWith('/parent/child/attendances') ||
          path.endsWith('/parent/child/schedules') ||
          path.endsWith('/parent/child/ukt')) {
        return _response([]);
      }
      throw StateError('Unexpected request path.');
    });
    ApiService.setHttpClient(client);

    await tester.pumpWidget(const MaterialApp(home: OrangTuaDashboard()));
    await tester.pumpAndSettle();

    expect(
      find.text('Server sedang bermasalah. Coba lagi nanti.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty metadata state without file actions', (
    tester,
  ) async {
    final data = OrangTuaApiMapper.fromResponses(
      parent: {'name': 'Orang Tua Uji', 'email': 'parent@example.test'},
      children: [
        {'id': 12, 'name': 'Anak Uji', 'nim': 'TEST-12'},
      ],
      announcements: [],
      documents: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InformasiTab(data: data, onNavigate: (_) {}),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Metadata dokumen anak'),
      240,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Belum ada metadata dokumen yang tersedia.'),
      findsOneWidget,
    );
    expect(find.text('Unduh'), findsNothing);
    expect(find.text('Hapus'), findsNothing);
  });
}
