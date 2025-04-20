import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  String? _token;

  Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        return {'success': true, 'data': data['data']};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message':
              'Invalid credentials. Please check your email and password.'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed due to an unknown error.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred. Please try again later.'
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
    String passwordConfirmation,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();

      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        _token = null;
        return {'success': true, 'message': 'Logged out locally'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      _token = null;

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
      _token = null;

      return {
        'success': true,
        'message':
            'Logged out locally, but server sync failed: ${e.toString()}',
      };
    }
  }
}
