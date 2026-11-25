import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'token': 'expired-access',
      'refresh_token': 'current-refresh',
    });
  });

  tearDown(() {
    client.close();
  });

  test('refreshes an expired session once and retries the request', () async {
    var refreshCount = 0;
    client = MockClient((request) async {
      if (request.url.path.endsWith('/refresh-token')) {
        refreshCount++;
        expect(jsonDecode(request.body), {'refresh_token': 'current-refresh'});
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'token': 'new-access', 'refresh_token': 'new-refresh'},
          }),
          200,
        );
      }

      expect(request.url.path.endsWith('/users/me'), isTrue);
      if (request.headers['authorization'] == 'Bearer new-access') {
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'id': 42},
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'message': 'Sesi berakhir', 'data': null}),
        401,
      );
    });
    ApiService.setHttpClient(client);

    final response = await ApiService.get('/users/me');
    final prefs = await SharedPreferences.getInstance();

    expect(response['data']['id'], 42);
    expect(refreshCount, 1);
    expect(prefs.getString('token'), 'new-access');
    expect(prefs.getString('refresh_token'), 'new-refresh');
  });

  test(
    'refreshes a missing access token before sending an authorized request',
    () async {
      SharedPreferences.setMockInitialValues({
        'refresh_token': 'current-refresh',
      });
      var refreshCount = 0;
      var protectedRequestCount = 0;
      client = MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) {
          refreshCount++;
          return http.Response(
            jsonEncode({
              'message': 'ok',
              'data': {'token': 'new-access', 'refresh_token': 'new-refresh'},
            }),
            200,
          );
        }

        protectedRequestCount++;
        expect(request.headers['authorization'], 'Bearer new-access');
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'id': 42},
          }),
          200,
        );
      });
      ApiService.setHttpClient(client);

      await ApiService.get('/users/me');

      expect(refreshCount, 1);
      expect(protectedRequestCount, 1);
    },
  );

  test(
    'does not send an unauthenticated request when no session exists',
    () async {
      SharedPreferences.setMockInitialValues({});
      var requestCount = 0;
      client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 401);
      });
      ApiService.setHttpClient(client);

      await expectLater(
        ApiService.get('/users/me'),
        throwsA(isA<SessionExpiredException>()),
      );

      expect(requestCount, 0);
    },
  );

  test('does not persist an admin login in the mobile session', () async {
    SharedPreferences.setMockInitialValues({});
    client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'message': 'ok',
          'data': {
            'token': 'admin-access',
            'refresh_token': 'admin-refresh',
            'role': 'admin',
          },
        }),
        200,
      );
    });
    ApiService.setHttpClient(client);

    await expectLater(
      ApiService.login('admin@example.test', 'password'),
      throwsA(isA<UnsupportedMobileRoleException>()),
    );
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getString('token'), isNull);
    expect(prefs.getString('refresh_token'), isNull);
    expect(prefs.getString('role'), isNull);
  });

  test(
    'surfaces forbidden responses as access-denied errors without refresh',
    () async {
      var refreshCount = 0;
      client = MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) refreshCount++;
        return http.Response(
          jsonEncode({'message': 'forbidden', 'data': null}),
          403,
        );
      });
      ApiService.setHttpClient(client);

      await expectLater(
        ApiService.get('/classes/list'),
        throwsA(
          isA<ApiRequestException>().having(
            (error) => error.statusCode,
            'statusCode',
            403,
          ),
        ),
      );

      expect(refreshCount, 0);
      expect(
        ApiService.errorMessage(
          const ApiRequestException(403, 'forbidden'),
          fallback: 'fallback',
        ),
        'Akses ditolak untuk akun ini.',
      );
    },
  );

  test(
    'does not retry or refresh repeatedly after a retry is unauthorized',
    () async {
      var refreshCount = 0;
      var protectedRequestCount = 0;
      client = MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) {
          refreshCount++;
          return http.Response(
            jsonEncode({
              'message': 'ok',
              'data': {'token': 'new-access', 'refresh_token': 'new-refresh'},
            }),
            200,
          );
        }
        protectedRequestCount++;
        return http.Response(
          jsonEncode({'message': 'unauthorized', 'data': null}),
          401,
        );
      });
      ApiService.setHttpClient(client);

      await expectLater(
        ApiService.get('/users/me'),
        throwsA(isA<SessionExpiredException>()),
      );

      expect(refreshCount, 1);
      expect(protectedRequestCount, 2);
    },
  );

  test('shares one refresh request between concurrent 401 responses', () async {
    var refreshCount = 0;
    client = MockClient((request) async {
      if (request.url.path.endsWith('/refresh-token')) {
        refreshCount++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return http.Response(
          jsonEncode({
            'message': 'ok',
            'data': {'token': 'new-access', 'refresh_token': 'new-refresh'},
          }),
          200,
        );
      }

      if (request.headers['authorization'] == 'Bearer new-access') {
        return http.Response(jsonEncode({'message': 'ok', 'data': []}), 200);
      }
      return http.Response(
        jsonEncode({'message': 'Sesi berakhir', 'data': null}),
        401,
      );
    });
    ApiService.setHttpClient(client);

    final responses = await Future.wait([
      ApiService.get('/first'),
      ApiService.get('/second'),
    ]);

    expect(responses, hasLength(2));
    expect(refreshCount, 1);
  });

  test('collects every page from a paginated list envelope', () async {
    final requestedPages = <String>[];
    client = MockClient((request) async {
      requestedPages.add(request.url.queryParameters['page'] ?? '');
      final page = int.parse(request.url.queryParameters['page']!);
      final data = page == 1 ? [1, 2] : [3];
      return http.Response(
        jsonEncode({
          'message': 'ok',
          'data': {'data': data, 'total_data': 3, 'page': page, 'limit': 2},
        }),
        200,
      );
    });
    ApiService.setHttpClient(client);

    final records = await ApiService.getAll('/classes/list', limit: 2);

    expect(records, [1, 2, 3]);
    expect(requestedPages, ['1', '2']);
  });

  test('collects every page using the total-count response header', () async {
    final requestedPages = <String>[];
    client = MockClient((request) async {
      requestedPages.add(request.url.queryParameters['page'] ?? '');
      final page = int.parse(request.url.queryParameters['page']!);
      return http.Response(
        jsonEncode({
          'message': 'ok',
          'data': page == 1 ? [1, 2] : [3],
        }),
        200,
        headers: {'x-total-count': '3'},
      );
    });
    ApiService.setHttpClient(client);

    final records = await ApiService.getAll(
      '/classes/students?class_id=7',
      limit: 2,
    );

    expect(records, [1, 2, 3]);
    expect(requestedPages, ['1', '2']);
  });

  test(
    'logout revokes the rotated refresh token after an access-token 401',
    () async {
      final logoutRefreshTokens = <String>[];
      client = MockClient((request) async {
        if (request.url.path.endsWith('/refresh-token')) {
          return http.Response(
            jsonEncode({
              'message': 'ok',
              'data': {'token': 'new-access', 'refresh_token': 'new-refresh'},
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/logout')) {
          logoutRefreshTokens.add(
            jsonDecode(request.body)['refresh_token'] as String,
          );
          if (request.headers['authorization'] == 'Bearer new-access') {
            return http.Response(
              jsonEncode({'message': 'ok', 'data': null}),
              200,
            );
          }
          return http.Response(
            jsonEncode({'message': 'Sesi berakhir', 'data': null}),
            401,
          );
        }
        throw StateError('Unexpected request.');
      });
      ApiService.setHttpClient(client);

      await ApiService.logout();
      final prefs = await SharedPreferences.getInstance();

      expect(logoutRefreshTokens, ['current-refresh', 'new-refresh']);
      expect(prefs.getString('token'), isNull);
      expect(prefs.getString('refresh_token'), isNull);
    },
  );
}
