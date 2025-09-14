// test_2fa.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class Test2FA {
  static const String baseUrl = "http://192.168.1.6/arco_api";

  // Test connection to server
  static Future<void> testConnection() async {
    try {
      print('🔗 Testing connection to: $baseUrl');
      final response = await http.get(Uri.parse('$baseUrl/'));
      print('✅ Connection status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
    } catch (e) {
      print('❌ Connection failed: $e');
    }
  }

  // Test 2FA token generation
  static Future<void> testGenerateToken() async {
    try {
      print('\n🎫 Testing token generation...');
      final response = await http.post(
        Uri.parse('$baseUrl/2fa.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "generate_token",
          "user_id": 1,
          "email": "admin@arko.com",
        }),
      );

      print('✅ Token generation status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('🎉 Token generated successfully: ${data['token']}');
        } else {
          print('❌ Token generation failed: ${data['message']}');
        }
      }
    } catch (e) {
      print('❌ Token generation error: $e');
    }
  }

  // Test 2FA status check
  static Future<void> test2FAStatus() async {
    try {
      print('\n📊 Testing 2FA status...');
      final response = await http.post(
        Uri.parse('$baseUrl/2fa.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "status",
          "user_id": 1,
        }),
      );

      print('✅ Status check status: ${response.statusCode}');
      print('📄 Response: ${response.body}');
    } catch (e) {
      print('❌ Status check error: $e');
    }
  }

  // Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting 2FA Tests...\n');
    await testConnection();
    await testGenerateToken();
    await test2FAStatus();
    print('\n🎯 All tests completed!');
  }
}