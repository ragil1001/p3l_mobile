import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/auth';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'EMAIL': email,
          'PASSWORD': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('user_type', data['user_type']);
        await prefs.setString('role', data['user']['role'][0] ?? '');

        return {
          'success': true,
          'data': {
            'token': data['token'],
            'user_type': data['user_type'],
            'role': data['user']['role'][0],
          },
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed due to an unknown error.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again later.',
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String nama,
    String email,
    String telepon,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/pembeli'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'NAMA': nama,
          'EMAIL': email,
          'TELEPON': telepon,
          'PASSWORD': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['errors']?['EMAIL']?.first ??
              data['message'] ??
              'Registration failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again later.',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      final prefs = await SharedPreferences.getInstance();

      if (token == null) {
        await prefs.remove('token');
        await prefs.remove('user_type');
        await prefs.remove('role');
        return {'success': true, 'message': 'Logged out locally'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      await prefs.remove('token');
      await prefs.remove('user_type');
      await prefs.remove('role');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Successfully logged out'};
      } else {
        return {
          'success': true,
          'message': 'Logged out locally, but server sync failed',
        };
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_type');
      await prefs.remove('role');
      return {
        'success': true,
        'message': 'Logged out locally due to network error',
      };
    }
  }
}
