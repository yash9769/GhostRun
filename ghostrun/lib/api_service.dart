import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ApiService {
  static String customBaseUrl = '';

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) {
      final url = customBaseUrl.trim();
      return url.endsWith('/api') ? url : '$url/api';
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8001/api';
      }
    } else {
      if (kDebugMode) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:8001/api';
        }
        return 'http://localhost:8001/api';
      }
    }
    return 'https://ghostrun-mq5v.onrender.com/api';
  }

  static String get wsUrl {
    if (customBaseUrl.isNotEmpty) {
      final url = customBaseUrl.trim();
      final wsBase = url.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://');
      return wsBase.endsWith('/ws/alerts') ? wsBase : '$wsBase/ws/alerts';
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'ws://localhost:8001/ws/alerts';
      }
    } else {
      if (kDebugMode) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'ws://10.0.2.2:8001/ws/alerts';
        }
        return 'ws://localhost:8001/ws/alerts';
      }
    }
    return 'wss://ghostrun-mq5v.onrender.com/ws/alerts';
  }

  // ── Device Info ───────────────────────────────────────────────────────────

  /// Returns real device info from the native platform.
  static Future<Map<String, dynamic>> getRealDeviceInfo() async {
    final info = DeviceInfoPlugin();
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final d = await info.androidInfo;
        return {
          'os_version': 'Android ${d.version.release} (SDK ${d.version.sdkInt})',
          'model': '${d.manufacturer} ${d.model}',
          'brand': d.brand,
          'device': d.device,
          'is_physical': d.isPhysicalDevice,
          'sdk_int': d.version.sdkInt,
          // Developer mode & root detection heuristics
          'developer_mode': !d.isPhysicalDevice, // emulator likely has dev mode
          'is_rooted': false, // requires native root check beyond this plugin
          'unknown_sources': false,
        };
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final d = await info.iosInfo;
        return {
          'os_version': 'iOS ${d.systemVersion}',
          'model': d.model,
          'device': d.utsname.machine,
          'is_physical': d.isPhysicalDevice,
          'developer_mode': false,
          'is_rooted': false,
          'unknown_sources': false,
        };
      }
    } catch (e) {
      print('DeviceInfo error: $e');
    }
    return {
      'os_version': 'Unknown',
      'model': 'Unknown Device',
      'developer_mode': false,
      'is_rooted': false,
      'unknown_sources': false,
    };
  }

  // ── Network Info ──────────────────────────────────────────────────────────

  /// Returns real Wi-Fi SSID, BSSID, and signal info (Android requires location permission).
  static Future<Map<String, dynamic>> getRealNetworkInfo() async {
    try {
      final connectivity = Connectivity();
      final connectivityResult = await connectivity.checkConnectivity();

      // Check if on Wi-Fi
      bool onWifi = connectivityResult.contains(ConnectivityResult.wifi);

      if (onWifi && !kIsWeb) {
        final networkInfo = NetworkInfo();
        final ssid = await networkInfo.getWifiName();
        final bssid = await networkInfo.getWifiBSSID();
        final ip = await networkInfo.getWifiIP();
        final gatewayIp = await networkInfo.getWifiGatewayIP();

        return {
          'on_wifi': true,
          'ssid': ssid?.replaceAll('"', '') ?? 'Unknown',
          'bssid': bssid ?? 'Unknown',
          'ip': ip ?? 'Unknown',
          'gateway': gatewayIp ?? 'Unknown',
          'connection_type': 'Wi-Fi',
        };
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        return {
          'on_wifi': false,
          'ssid': 'Cellular',
          'connection_type': 'Mobile Data',
        };
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        return {
          'on_wifi': false,
          'ssid': 'Ethernet',
          'connection_type': 'Ethernet',
        };
      }
    } catch (e) {
      print('NetworkInfo error: $e');
    }
    return {
      'on_wifi': false,
      'ssid': 'Unknown',
      'connection_type': 'Unknown',
    };
  }

  // ── News ──────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchNews() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/news'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching news: $e');
    }
    return [];
  }

  static Future<List<String>> fetchArticleContent(String url) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/news/content?url=${Uri.encodeComponent(url)}'))
          .timeout(const Duration(seconds: 15));
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/scan/start'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {"user_id": userId, "scan_type": "full", "file_id": fileId}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error starting scan: $e');
    }
    return {"status": "error"};
  }

  static Future<Map<String, dynamic>> getScanStatus(String scanId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/scan/$scanId'))
          .timeout(const Duration(seconds: 15));
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
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
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
      final response = await http
          .get(Uri.parse('$baseUrl/threats'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching threats: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> reportThreat(
      Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/threats/report'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error reporting threat: $e');
    }
    return {"error": "Failed to report threat"};
  }

  static Future<void> voteThreat(String threatId, bool upvote) async {
    try {
      await http
          .post(Uri.parse('$baseUrl/threats/$threatId/vote?upvote=$upvote'))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Error voting threat: $e');
    }
  }

  // ── Fleet Dashboard ───────────────────────────────────────────────────────

  static Future<List<dynamic>> fetchFleetDevices() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/fleet/devices'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error fetching fleet devices: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchFleetStats() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/fleet/stats'))
          .timeout(const Duration(seconds: 15));
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/device/score'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(profile),
          )
          .timeout(const Duration(seconds: 15));
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
      final response = await http
          .post(
            Uri.parse('$baseUrl/network/audit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));
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
          .post(Uri.parse('$baseUrl/ai/analyze?scan_id=$scanId'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      print('Error getting AI analysis: $e');
    }
    return {
      "plain_summary": "Analysis unavailable.",
      "mitre_grid": {},
      "detected_techniques": []
    };
  }
}
