import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Sesi berakhir. Silakan masuk kembali.';
}

class ApiRequestException implements Exception {
  const ApiRequestException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiNetworkException implements Exception {
  const ApiNetworkException();

  @override
  String toString() =>
      'Tidak dapat terhubung ke server. Periksa jaringan lalu coba lagi.';
}

class ApiConfigurationException implements Exception {
  const ApiConfigurationException();

  @override
  String toString() =>
      'URL API belum dikonfigurasi dengan benar. Build release memerlukan '
      'EDUTRACK_API_BASE_URL HTTPS yang berakhiran /api/v1.';
}

class TokenStorageException implements Exception {
  const TokenStorageException();

  @override
  String toString() =>
      'Sesi tidak dapat disimpan di perangkat. Silakan masuk kembali.';
}

class UnsupportedMobileRoleException implements Exception {
  const UnsupportedMobileRoleException();

  @override
  String toString() =>
      'Akun ini tidak didukung di aplikasi mobile. Gunakan Web Admin.';
}

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'EDUTRACK_API_BASE_URL',
    defaultValue: kDebugMode ? 'http://10.0.2.2:8080/api/v1' : '',
  );
  static const Duration _requestTimeout = Duration(seconds: 20);
  static http.Client _client = http.Client();
  static Future<bool>? _refreshInProgress;

  static String get _apiRoot {
    final uri = Uri.tryParse(baseUrl);
    final scheme = uri?.scheme.toLowerCase();
    final path = uri?.path.replaceFirst(RegExp(r'/+$'), '');
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (scheme != 'https' && !(kDebugMode && scheme == 'http')) ||
        path == null ||
        !path.endsWith('/api/v1')) {
      throw const ApiConfigurationException();
    }
    return baseUrl.replaceFirst(RegExp(r'/+$'), '');
  }

  @visibleForTesting
  static void setHttpClient(http.Client client) {
    _client = client;
  }

  static Uri _uri(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse('$_apiRoot/$path');
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Respons API tidak valid.');
  }

  static String _message(Map<String, dynamic> response, String fallback) {
    final message = response['message'];
    return message is String && message.isNotEmpty ? message : fallback;
  }

  static Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  static Future<http.Response> _send(
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send().timeout(_requestTimeout);
    } on http.ClientException {
      throw const ApiNetworkException();
    } on TimeoutException {
      throw const ApiNetworkException();
    }
  }

  static Future<void> _storeTokens(
    SharedPreferences prefs, {
    required String token,
    required String refreshToken,
    String? role,
    String? email,
  }) async {
    final refreshStored = await prefs.setString('refresh_token', refreshToken);
    final tokenStored = await prefs.setString('token', token);
    final roleStored = role == null || await prefs.setString('role', role);
    final emailStored = email == null || await prefs.setString('email', email);
    if (!refreshStored || !tokenStored || !roleStored || !emailStored) {
      throw const TokenStorageException();
    }
  }

  static String errorMessage(Object error, {required String fallback}) {
    if (error is SessionExpiredException ||
        error is ApiNetworkException ||
        error is ApiConfigurationException ||
        error is TokenStorageException ||
        error is UnsupportedMobileRoleException) {
      return error.toString();
    }
    if (error is! ApiRequestException) return fallback;
    return switch (error.statusCode) {
      400 || 409 => error.message,
      401 => error.message,
      403 => 'Akses ditolak untuk akun ini.',
      404 => 'Data yang diminta tidak ditemukan.',
      >= 500 => 'Server sedang bermasalah. Coba lagi nanti.',
      _ => fallback,
    };
  }

  static Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var accessToken = await getToken();
    if (accessToken == null || accessToken.isEmpty) {
      if (!await _refreshSession()) {
        await _clearSession();
        throw const SessionExpiredException();
      }
      accessToken = await getToken();
    }
    final initialAccessToken = accessToken;
    if (initialAccessToken == null || initialAccessToken.isEmpty) {
      await _clearSession();
      throw const SessionExpiredException();
    }

    final response = await _send(() => request(_headers(initialAccessToken)));
    if (response.statusCode != 401) return response;

    if (!await _refreshAfterUnauthorized(initialAccessToken)) {
      await _clearSession();
      throw const SessionExpiredException();
    }

    final refreshedAccessToken = await getToken();
    if (refreshedAccessToken == null || refreshedAccessToken.isEmpty) {
      await _clearSession();
      throw const SessionExpiredException();
    }
    final retryResponse = await _send(
      () => request(_headers(refreshedAccessToken)),
    );
    if (retryResponse.statusCode == 401) {
      await _clearSession();
      throw const SessionExpiredException();
    }
    return retryResponse;
  }

  static Future<bool> _refreshAfterUnauthorized(String expiredToken) async {
    final currentToken = await getToken();
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != expiredToken) {
      return true;
    }

    return _refreshSession();
  }

  static Future<bool> _refreshSession() async {
    final pendingRefresh = _refreshInProgress;
    if (pendingRefresh != null) return pendingRefresh;

    final refresh = _refreshTokens();
    _refreshInProgress = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshInProgress, refresh)) {
        _refreshInProgress = null;
      }
    }
  }

  static Future<bool> _refreshTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final response = await _send(
      () => _client.post(
        _uri('/refresh-token'),
        headers: _headers(null),
        body: jsonEncode({'refresh_token': refreshToken}),
      ),
    );
    if (response.statusCode == 401) return false;

    final payload = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw ApiRequestException(
        response.statusCode,
        _message(payload, 'Sesi tidak dapat diperbarui.'),
      );
    }
    final data = payload['data'];
    if (data is! Map ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty ||
        data['refresh_token'] is! String ||
        (data['refresh_token'] as String).isEmpty) {
      throw const FormatException('Respons pembaruan sesi tidak valid.');
    }

    await _storeTokens(
      prefs,
      token: data['token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return true;
  }

  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('role');
    await prefs.remove('email');
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _send(
      () => _client.post(
        _uri('/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    final payload = _decodeResponse(response);
    if (response.statusCode != 200) {
      throw ApiRequestException(
        response.statusCode,
        _message(payload, 'Login gagal.'),
      );
    }

    final data = payload['data'];
    if (data is! Map ||
        data['token'] is! String ||
        data['refresh_token'] is! String ||
        data['role'] is! String) {
      throw const FormatException('Respons login tidak valid.');
    }
    if (!const {'mahasiswa', 'dosen', 'orangtua'}.contains(data['role'])) {
      await _clearSession();
      throw const UnsupportedMobileRoleException();
    }

    final prefs = await SharedPreferences.getInstance();
    await _storeTokens(
      prefs,
      token: data['token'] as String,
      refreshToken: data['refresh_token'] as String,
      role: data['role'] as String,
      email: email,
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/register'),
        headers: _headers(null),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      ),
    );
    final payload = _decodeResponse(response);
    if (response.statusCode == 201) return payload;
    throw ApiRequestException(
      response.statusCode,
      _message(payload, 'Registrasi gagal.'),
    );
  }

  static Future<String> forgotPassword(String email) async {
    final response = await _send(
      () => _client.post(
        _uri('/forgot-password'),
        headers: _headers(null),
        body: jsonEncode({'email': email}),
      ),
    );
    final payload = _decodeResponse(response);
    if (response.statusCode == 200) {
      return _message(payload, 'Permintaan berhasil dikirim.');
    }
    throw ApiRequestException(
      response.statusCode,
      _message(payload, 'Gagal mengirim permintaan.'),
    );
  }

  static Future<String> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    final response = await _send(
      () => _client.post(
        _uri('/reset-password'),
        headers: _headers(null),
        body: jsonEncode({
          'email': email,
          'token': token,
          'new_password': newPassword,
        }),
      ),
    );
    final payload = _decodeResponse(response);
    if (response.statusCode == 200) {
      return _message(payload, 'Password berhasil direset.');
    }
    throw ApiRequestException(
      response.statusCode,
      _message(payload, 'Gagal mereset password.'),
    );
  }

  static Future<http.Response> _getResponse(String endpoint) {
    return _authorizedRequest(
      (headers) => _client.get(_uri(endpoint), headers: headers),
    );
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await _getResponse(endpoint);
    final payload = _decodeResponse(response);
    if (response.statusCode == 200) return payload;
    throw ApiRequestException(
      response.statusCode,
      _message(payload, 'Gagal mengambil data.'),
    );
  }

  static Future<List<dynamic>> getAll(
    String endpoint, {
    int limit = 100,
  }) async {
    final records = <dynamic>[];
    var page = 1;
    while (true) {
      final separator = endpoint.contains('?') ? '&' : '?';
      final response = await _getResponse(
        '$endpoint${separator}page=$page&limit=$limit',
      );
      final payload = _decodeResponse(response);
      if (response.statusCode != 200) {
        throw ApiRequestException(
          response.statusCode,
          _message(payload, 'Gagal mengambil data.'),
        );
      }

      final data = payload['data'];
      final List<dynamic> pageRecords;
      final int? total;
      if (data is Map) {
        final items = data['data'];
        if (items is! List) {
          throw const FormatException('Respons daftar tidak valid.');
        }
        pageRecords = items;
        total = (data['total_data'] as num?)?.toInt();
      } else if (data is List) {
        pageRecords = data;
        total = int.tryParse(response.headers['x-total-count'] ?? '');
      } else {
        throw const FormatException('Respons daftar tidak valid.');
      }

      records.addAll(pageRecords);
      if (pageRecords.length < limit) break;
      if (total != null && records.length >= total) break;
      page++;
      if (page > 1000) break;
    }
    return records;
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _authorizedRequest(
      (headers) => _client.post(
        _uri(endpoint),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
    final payload = _decodeResponse(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return payload;
    }
    throw ApiRequestException(
      response.statusCode,
      _message(payload, 'Gagal mengirim data.'),
    );
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final response = await _authorizedRequest(
      (headers) =>
          _client.put(_uri(endpoint), headers: headers, body: jsonEncode(body)),
    );
    final payload = _decodeResponse(response);
    if (response.statusCode == 200) return payload;
    throw ApiRequestException(
      response.statusCode,
      _message(payload, 'Gagal memperbarui data.'),
    );
  }

  static Future<void> logout() async {
    final token = await getToken();
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    try {
      if (token != null || refreshToken != null) {
        final response = await _authorizedRequest((headers) async {
          final currentPrefs = await SharedPreferences.getInstance();
          return _client.post(
            _uri('/logout'),
            headers: headers,
            body: jsonEncode({
              'refresh_token': currentPrefs.getString('refresh_token') ?? '',
            }),
          );
        });
        final payload = _decodeResponse(response);
        if (response.statusCode != 200) {
          throw ApiRequestException(
            response.statusCode,
            _message(payload, 'Gagal mengakhiri sesi.'),
          );
        }
      }
    } finally {
      await _clearSession();
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}
