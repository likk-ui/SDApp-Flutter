import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://1.14.132.232/api.php';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'login',
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': '网络错误'};
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAnimations() async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'animations'}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'animations': []};
    } catch (e) {
      return {'success': false, 'animations': []};
    }
  }

  static Future<void> syncTraining(String username, String date, int duration) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/training/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'date': date,
          'duration': duration,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<int> fetchTraining(String username, String date) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/training/get'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'date': date,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['total'] ?? 0;
        }
      }
    } catch (_) {}
    return 0;
  }
}