import 'dart:convert';
import 'package:http/http.dart' as http;

class MySQLService {
  static const String baseUrl = 'http://192.168.1.14/arco_api'; // Change to your PC's IP

  // Helper method for API calls
  Future<dynamic> _apiCall(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('API call failed: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Authentication
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final result = await _apiCall('auth', {
      'action': 'login',
      'username': username,
      'password': password,
    });

    if (result['success'] == true) {
      return result['user'];
    }
    return null;
  }

  // Admin statistics
  Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin.php?action=stats'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      print('Error fetching admin stats: $e');
      return {};
    }
  }

  // Get users with filtering
  Future<List<Map<String, dynamic>>> getUsers({String? searchQuery, String? roleFilter}) async {
    try {
      String url = '$baseUrl/admin.php?action=users';
      if (searchQuery != null && searchQuery.isNotEmpty) {
        url += '&search=$searchQuery';
      }
      if (roleFilter != null && roleFilter != 'all') {
        url += '&role=$roleFilter';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

// Add other methods for expenses, budgets, feedback, etc.
}