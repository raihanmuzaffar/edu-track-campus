import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ GANTI URL INI:
  // Jika pakai Emulator Android, gunakan 'http://10.0.2.2:8080/api/v1'
  // Jika pakai HP Fisik, gunakan IP Laptop Anda (misal 'http://192.168.1.10:8080/api/v1')
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; 

  // 1. Fungsi Login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan Token, Role, dan Email ke HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['data']['token']);
        await prefs.setString('role', data['data']['role']);
        await prefs.setString('email', email); // <--- TAMBAHAN UNTUK PROFIL
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      // Membersihkan pesan error agar rapi saat ditampilkan di UI
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 2. Fungsi Register (Pendaftaran Akun Baru)
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data; // Registrasi berhasil
      } else {
        throw Exception(data['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 3. Fungsi Minta Token Lupa Password
  static Future<String> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data['message'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mengirim permintaan');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 4. Fungsi Reset Password dengan Token
  static Future<String> resetPassword(String email, String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return data['message'];
      } else {
        throw Exception(data['message'] ?? 'Gagal mereset password');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 5. Fungsi GET Generic (Untuk mengambil data KRS, Nilai, Absensi, dll)
  static Future<dynamic> get(String endpoint) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Otomatis menyisipkan Token JWT
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengambil data');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 6. Fungsi POST Generic (Untuk Enroll KRS, dll)
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengirim data');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 7. Fungsi Logout (Diperbaiki: Tidak menghapus status isFirstTime)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus data sesi user saja, biarkan isFirstTime tetap ada
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('email');
  }

  // 8. Fungsi Ambil Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 9. Fungsi Ambil Role (Untuk navigasi di Main App)
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}