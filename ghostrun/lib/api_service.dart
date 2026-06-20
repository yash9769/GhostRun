import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8001/api';
      }
    }
    return 'https://ghostrun-mq5v.onrender.com/api';
  }

  static String get wsUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'ws://localhost:8001/ws/alerts';
      }
    }
    return 'wss://ghostrun-mq5v.onrender.com/ws/alerts';
  }

  // ── News ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/news'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching news: $e');
    }
    return [];
  }

  static Future<List<String>> fetchArticleContent(String url) async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/news/content?url=${Uri.encodeComponent(url)}'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return List<String>.from(data['paragraphs'] ?? []);
      }
    } catch (e) {
      print('Error fetching article content: $e');
    }
    return [];
  }

  // ── Scan ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> startScan(String userId,
      {String? fileId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scan/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {"user_id": userId, "scan_type": "full", "file_id": fileId}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error starting scan: $e');
    }
    return {"status": "error"};
  }

  static Future<Map<String, dynamic>> getScanStatus(String scanId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/scan/$scanId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error getting scan status: $e');
    }
    return {"status": "error"};
  }

  // ── File Inspection ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> inspectFile(
      Uint8List fileBytes, String filename) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/files/inspect'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
      ));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error inspecting file: $e');
    }
    return {"error": "Failed to inspect file"};
  }

  // ── Community Threats ─────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchThreats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/threats'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching threats: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> reportThreat(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/threats/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error reporting threat: $e');
    }
    return {"error": "Failed to report threat"};
  }

  static Future<void> voteThreat(String threatId, bool upvote) async {
    try {
      await http.post(Uri.parse(
          '$baseUrl/threats/$threatId/vote?upvote=$upvote'));
    } catch (e) {
      print('Error voting threat: $e');
    }
  }

  // ── Fleet Dashboard ───────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchFleetDevices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fleet/devices'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching fleet devices: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchFleetStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fleet/stats'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching fleet stats: $e');
    }
    return {};
  }

  // ── Device Score ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> computeDeviceScore(
      Map<String, dynamic> profile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/device/score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error computing device score: $e');
    }
    return {"score": 85.0, "verdict": "good", "factors": []};
  }

  // ── Network Audit ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> auditNetwork(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/network/audit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error auditing network: $e');
    }
    return {"verdict": "unknown", "risk_score": 50, "risk_factors": []};
  }

  // ── AI Analysis ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> aiAnalyze(String scanId) async {
    try {
      final response = await http
          .post(Uri.parse('$baseUrl/ai/analyze?scan_id=$scanId'));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error getting AI analysis: $e');
    }
    return {"plain_summary": "Analysis unavailable.", "mitre_grid": {}, "detected_techniques": []};
  }
}
