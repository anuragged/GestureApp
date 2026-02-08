
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Production Server
  static const String baseUrl = 'https://tutorialdisk.com/api';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: 'auth_token', value: token);
        return {'success': true, 'data': data};
      } else {
         final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json'
          },
        );
      } catch (_) {}
    }
    await _storage.delete(key: 'auth_token');
  }

  Future<void> logUsage(String gestureName, String actionType) async {
    final token = await getToken();
    // Proceed even if not logged in? Requirement says "Sync to API if logged in".
    // Usually analytics might be anonymous, but "log-usage" implies user tracking.
    if (token == null) return; 

    try {
      await http.post(
        Uri.parse('$baseUrl/log-usage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({
          'gesture_name': gestureName,
          'action_type': actionType,
        }),
      );
    } catch (e) {
      print("Log Usage Error: $e");
    }
  }

  // --- Gesture Syncing ---
  
  Future<List<dynamic>?> fetchGestures() async {
      final token = await getToken();
      if (token == null) return null;

      try {
          final response = await http.get(
              Uri.parse('$baseUrl/gestures'),
               headers: {
                'Authorization': 'Bearer $token',
                'Accept': 'application/json'
              },
          );
          
          if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              // Backend returns wrapped data? Assuming standard Laravel Resource: { data: [...] }
              // But controller logic in index method usually returns collection directly or resource collection
              // Creating a safe parser
              if (data is Map && data.containsKey('data')) {
                   return data['data'];
              } else if (data is List) {
                  return data;
              }
              return [];
          }
      } catch (e) {
          print("Fetch Error: $e");
      }
      return null;
  }
  
  Future<bool> syncGestures(List<Map<String, dynamic>> gestures) async {
      final token = await getToken();
      if (token == null) return false;
      
      try {
           final response = await http.post(
              Uri.parse('$baseUrl/sync-gestures'),
               headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json'
              },
              body: jsonEncode({'gestures': gestures}),
          );
          return response.statusCode == 200;
      } catch (e) {
          print("Sync Error: $e");
          return false;
      }
  }
}
