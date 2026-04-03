import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 10.0.2.2 is for Android emulator; 127.0.0.1 is for web/desktop/Windows run
  static const String baseUrl = 'http://127.0.0.1:8001/api';

  static Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/news'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> startScan(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": userId, "scan_type": "full"}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to start scan');
      }
    } catch (e) {
      print('Error starting scan: $e');
      return {"status": "error"};
    }
  }

  static Future<Map<String, dynamic>> getScanStatus(String scanId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/scan/$scanId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get scan status');
      }
    } catch (e) {
      print('Error getting scan status: $e');
      return {"status": "error"};
    }
  }
}
