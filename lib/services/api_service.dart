import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.14/arco_api";

  // Token expiration time (15 minutes in milliseconds)
  static const int tokenExpirationTime = 15 * 60 * 1000;
  static Map<String, DateTime> _tokenGenerationTimes = {};

  // ------------------------------
  // Chatbot Response Method - ADDED
  // ------------------------------
  static Future<String> getChatbotResponse(String message, String context) async {
    try {
      final response = await http.post(
        Uri.parse("https://api.zuki.ai/v1/chat/completions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer zu-a739850e912a7e3a13f7bf3c53813792",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "You are a helpful budgeting assistant. $context"
            },
            {
              "role": "user",
              "content": message
            }
          ],
          "max_tokens": 150,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to get chatbot response: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ getChatbotResponse error: $e");
      throw Exception('Network error: Please check your connection');
    }
  }

  // ------------------------------
  // Resend Verification Code - ADDED
  // ------------------------------
  static Future<bool> resendVerificationCode(String userId, String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // Use mobile endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "resend_code",
          "user_id": userId,
          "email": email,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("resendVerificationCode error: $e");
      return false;
    }
  }

  // ------------------------------
  // Connection Test
  // ------------------------------
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feedback.php'));
      print('Connection test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // ------------------------------
  // User Authentication - UPDATED TO mobile_auth.php
  // ------------------------------
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      print('🔐 Login attempt - Username: "$username", Password: "$password"');

      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ✅ Correct endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "login",
          "username": username,
          "password": password,
        }),
      );

      print('📡 Login response status: ${response.statusCode}');
      print('📡 Login response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("❌ Login error: $e");
      return {
        'success': false,
        'message': 'Network error: Please check your connection'
      };
    }
  }

  // ------------------------------
  // Check Username Availability - UPDATED TO mobile_auth.php
  // ------------------------------
  static Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ← CHANGED TO mobile_auth.php
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "check_username",
          "username": username,
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'available': data['available'] ?? false,
          'message': data['message'] ?? '',
        };
      }
      return {'available': false, 'message': 'Failed to check username'};
    } catch (e) {
      print("checkUsername error: $e");
      return {'available': false, 'message': 'Error checking username'};
    }
  }

  // ------------------------------
  // Sign Up User - UPDATED TO mobile_auth.php
  // ------------------------------
  static Future<Map<String, dynamic>> signUpUser({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    String? email,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ← CHANGED TO mobile_auth.php
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "sign_up",
          "username": username,
          "first_name": firstName,
          "last_name": lastName,
          "password": password,
          "email": email ?? '',
          "security_question": securityQuestion ?? '',
          "security_answer": securityAnswer ?? '',
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? '',
          'user': data['user'] ?? {},
        };
      }
      return {'success': false, 'message': 'Failed to sign up'};
    } catch (e) {
      print("signUpUser error: $e");
      return {'success': false, 'message': 'Error signing up'};
    }
  }

  // ------------------------------
  // Reset Password - UPDATED TO mobile_auth.php
  // ------------------------------
  static Future<bool> resetPassword(
      String username,
      String securityQuestion,
      String answer,
      String newPassword,
      ) async {
    try {
      print('🔐 Reset password attempt:');
      print('📧 Username: $username');
      print('❓ Security Question: $securityQuestion');
      print('✅ Answer: $answer');
      print('🔑 New Password: $newPassword');

      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ← CHANGED TO mobile_auth.php
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "reset_password",
          "username": username,
          "security_question": securityQuestion,
          "security_answer": answer,
          "new_password": newPassword,
        }),
      );

      print('📡 Reset password response status: ${response.statusCode}');
      print('📡 Reset password response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Reset password result: ${data['success']}');
        print('✅ Reset password message: ${data['message']}');
        return data['success'] == true;
      } else {
        print('❌ Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ resetPassword error: $e');
      return false;
    }
  }

  // ------------------------------
  // 2FA / Verification Methods - UPDATED TO mobile_auth.php
  // ------------------------------
  static Future<String?> generateVerificationToken(String userId, String email) async {
    try {
      print('📧 Generating token for user: $userId, email: $email');

      // Store generation time for this user
      _tokenGenerationTimes[userId] = DateTime.now();
      print('⏰ Token generation time stored: ${_tokenGenerationTimes[userId]}');

      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ← CHANGED TO mobile_auth.php
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "generate_token",
          "user_id": userId,
          "email": email,
        }),
      );

      print('📡 Generate token response status: ${response.statusCode}');
      print('📡 Generate token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final token = data['token']?.toString() ?? data['debug_token']?.toString();
          print('✅ Token generated successfully: $token');
          return token;
        } else {
          print('❌ Server returned success:false - ${data['message']}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print("❌ generateVerificationToken error: $e");
      return null;
    }
  }

  static Future<bool> verifyToken(String userId, String token) async {
    try {
      print('🔐 Verifying token for user: $userId, token: $token');

      // Check if token might be expired
      if (_isTokenExpired(userId)) {
        print('⚠️ Token may be expired - generated too long ago');
        return false;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ← CHANGED TO mobile_auth.php
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "verify_token",
          "user_id": userId,
          "token": token,
        }),
      );

      print('📡 Verify token response status: ${response.statusCode}');
      print('📡 Verify token response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Verification result: ${data['success']}');
        print('✅ Verification message: ${data['message']}');

        if (data['success'] == true) {
          // Clear the token generation time on successful verification
          _tokenGenerationTimes.remove(userId);
          return true;
        } else {
          // Handle specific error messages
          if (data['message']?.toString().toLowerCase().contains('expired') == true) {
            print('❌ Token expired - requesting new one');
          } else if (data['message']?.toString().toLowerCase().contains('invalid') == true) {
            print('❌ Invalid token - please check the code');
          }
          return false;
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print("❌ verifyToken error: $e");
      return false;
    }
  }

  // Check if token might be expired based on generation time
  static bool _isTokenExpired(String userId) {
    final generationTime = _tokenGenerationTimes[userId];
    if (generationTime == null) {
      print('⚠️ No generation time found for user $userId');
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(generationTime).inMilliseconds;
    final isExpired = difference > tokenExpirationTime;

    print('⏰ Token age: ${difference ~/ 1000} seconds');
    print('⏰ Expiration threshold: ${tokenExpirationTime ~/ 1000} seconds');
    print('⏰ Is expired: $isExpired');

    return isExpired;
  }

  // Clear expired tokens
  static void clearExpiredTokens() {
    final now = DateTime.now();
    _tokenGenerationTimes.removeWhere((userId, generationTime) {
      final isExpired = now.difference(generationTime).inMilliseconds > tokenExpirationTime;
      if (isExpired) {
        print('🧹 Cleared expired token for user: $userId');
      }
      return isExpired;
    });
  }

  // ------------------------------
  // Enhanced token verification with retry logic
  // ------------------------------
  static Future<Map<String, dynamic>> verifyTokenWithRetry(
      String userId, String token, String email) async {
    try {
      // First attempt
      final isValid = await verifyToken(userId, token);

      if (isValid) {
        return {'success': true, 'message': 'Verification successful'};
      }

      // If token is expired or invalid, try to generate a new one
      print('🔄 Token verification failed, attempting to generate new token...');
      final newToken = await generateVerificationToken(userId, email);

      if (newToken != null) {
        return {
          'success': false,
          'message': 'Token expired. A new code has been sent to your email.',
          'newTokenSent': true
        };
      } else {
        return {
          'success': false,
          'message': 'Verification failed. Please try again or request a new code.',
          'newTokenSent': false
        };
      }
    } catch (e) {
      print('❌ verifyTokenWithRetry error: $e');
      return {
        'success': false,
        'message': 'Verification error: ${e.toString()}',
        'newTokenSent': false
      };
    }
  }

  // ------------------------------
  // Check if user needs a new token (for UI feedback)
  // ------------------------------
  static bool needsNewToken(String userId) {
    return _isTokenExpired(userId);
  }

  // ------------------------------
  // Get time remaining for token expiration (for UI)
  // ------------------------------
  static int getTimeRemaining(String userId) {
    final generationTime = _tokenGenerationTimes[userId];
    if (generationTime == null) return 0;

    final now = DateTime.now();
    final difference = now.difference(generationTime).inMilliseconds;
    final remaining = tokenExpirationTime - difference;

    return remaining > 0 ? remaining ~/ 1000 : 0;
  }

  // 2FA is always enabled and mandatory for all users
  static Future<bool> is2FAEnabled(String userId) async {
    return true; // Always return true since 2FA is mandatory
  }

  // Toggle 2FA - can only enable (disabling is not allowed) - UPDATED TO mobile_auth.php
  static Future<bool> toggle2FA(String userId, bool enable) async {
    if (!enable) {
      // Cannot disable 2FA - it's mandatory
      print("Cannot disable 2FA - it is required for all users");
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ← CHANGED TO mobile_auth.php
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "toggle_2fa",
          "user_id": userId,
          "enable": true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("toggle2FA error: $e");
      return false;
    }
  }

  // ------------------------------
  // Feedback Methods - UPDATED WITH DEBUG LOGS
  // ------------------------------
  static Future<bool> submitFeedback(
      String userId,
      String name,
      String message,
      {int? rating}
      ) async {
    try {
      print('📝 Preparing to submit feedback...');
      print('👤 User ID: $userId');
      print('👤 User Name: $name');
      print('⭐ Rating: $rating');
      print('📋 Message: $message');

      final response = await http.post(
        Uri.parse("$baseUrl/feedback.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "submit",
          "user_id": userId,
          "name": name,
          "message": message,
          "rating": rating, // Add rating to the request
        }),
      );

      print('📡 Submit feedback response status: ${response.statusCode}');
      print('📡 Submit feedback response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ submitFeedback error: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getFeedback() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/feedback.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "get_feedback"}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['feedback'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print("❌ getFeedback error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getRecentFeedback({int limit = 5}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/feedback.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_recent_feedback",
          "limit": limit
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['feedback'] ?? [];
        }
      }
      return [];
    } catch (e) {
      print("❌ getRecentFeedback error: $e");
      return [];
    }
  }

  static Future<bool> deleteFeedback(String feedbackId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/feedback.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "delete_feedback",
          "feedback_id": feedbackId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("❌ deleteFeedback error: $e");
      return false;
    }
  }

  // ------------------------------
  // User Management Methods
  // ------------------------------
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_users",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['users']);
        }
      }
      return [];
    } catch (e) {
      print("getUsers error: $e");
      return [];
    }
  }

  static Future<bool> archiveUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "archive_user",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("archiveUser error: $e");
      return false;
    }
  }

  static Future<bool> unarchiveUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "unarchive_user",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("unarchiveUser error: $e");
      return false;
    }
  }

  // ------------------------------
  // Budget Methods
  // ------------------------------
  static Future<List<Map<String, dynamic>>> getBudgets(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/budgets.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_budgets",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['budgets']);
        }
      }
      return [];
    } catch (e) {
      print("getBudgets error: $e");
      return [];
    }
  }

  static Future<bool> createBudget(
      String userId,
      String category,
      double amount,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/budgets.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "create_budget",
          "user_id": userId,
          "category": category,
          "amount": amount,
          "start_date": startDate.toIso8601String(),
          "end_date": endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("createBudget error: $e");
      return false;
    }
  }

  static Future<bool> updateBudget(
      int budgetId,
      String category,
      double amount,
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/budgets.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update_budget",
          "budget_id": budgetId,
          "category": category,
          "amount": amount,
          "start_date": startDate.toIso8601String(),
          "end_date": endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("updateBudget error: $e");
      return false;
    }
  }

  static Future<bool> deleteBudget(int budgetId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/budgets.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "delete_budget",
          "budget_id": budgetId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("deleteBudget error: $e");
      return false;
    }
  }

  // ------------------------------
  // Expense Methods
  // ------------------------------
  static Future<List<Map<String, dynamic>>> getExpenses(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/expenses.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_expenses",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['expenses']);
        }
      }
      return [];
    } catch (e) {
      print("getExpenses error: $e");
      return [];
    }
  }

  static Future<bool> addExpense(
      String userId,
      String category,
      double amount,
      String description,
      DateTime date,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/expenses.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "add_expense",
          "user_id": userId,
          "category": category,
          "amount": amount,
          "description": description,
          "date": date.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("addExpense error: $e");
      return false;
    }
  }

  static Future<bool> updateExpense(
      int expenseId,
      String category,
      double amount,
      String description,
      DateTime date,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/expenses.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update_expense",
          "expense_id": expenseId,
          "category": category,
          "amount": amount,
          "description": description,
          "date": date.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("updateExpense error: $e");
      return false;
    }
  }

  static Future<bool> deleteExpense(int expenseId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/expenses.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "delete_expense",
          "expense_id": expenseId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("deleteExpense error: $e");
      return false;
    }
  }

  // ------------------------------
  // Analytics Methods
  // ------------------------------
  static Future<Map<String, dynamic>> getAnalytics(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/analytics.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_analytics",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['analytics'] ?? {};
        }
      }
      return {};
    } catch (e) {
      print("getAnalytics error: $e");
      return {};
    }
  }

  // ------------------------------
  // Notification Methods
  // ------------------------------
  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notifications.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_notifications",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['notifications']);
        }
      }
      return [];
    } catch (e) {
      print("getNotifications error: $e");
      return [];
    }
  }

  static Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/notifications.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "mark_as_read",
          "notification_id": notificationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("markNotificationAsRead error: $e");
      return false;
    }
  }

  // ------------------------------
  // Profile Methods
  // ------------------------------
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_profile",
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['profile'] ?? {};
        }
      }
      return {};
    } catch (e) {
      print("getProfile error: $e");
      return {};
    }
  }

  static Future<bool> updateProfile(
      String userId,
      String firstName,
      String lastName,
      String email,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "update_profile",
          "user_id": userId,
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("updateProfile error: $e");
      return false;
    }
  }

  // ------------------------------
  // Security Question Methods
  // ------------------------------
  static Future<List<String>> getSecurityQuestions() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/security_questions.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_questions",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['questions']);
        }
      }
      return [];
    } catch (e) {
      print("getSecurityQuestions error: $e");
      return [];
    }
  }

  static Future<String?> getUserSecurityQuestion(String username) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/security_questions.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "get_user_question",
          "username": username,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['question'];
        }
      }
      return null;
    } catch (e) {
      print("getUserSecurityQuestion error: $e");
      return null;
    }
  }
}