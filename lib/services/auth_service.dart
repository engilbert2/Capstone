import 'package:shared_preferences/shared_preferences.dart';
import 'package:Arko/services/api_service.dart';

class AuthService {
  // ==============================
  // CHECK USERNAME AVAILABILITY
  // ==============================
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      print('🔍 Checking username: $username');
      final result = await ApiService.checkUsername(username);
      print('📋 Username check result: $result');
      return result;
    } catch (e) {
      print('❌ Username check error: $e');
      return {
        'available': false,
        'message': 'Error checking username availability',
      };
    }
  }

  // ==============================
  // SIGN UP USER
  // ==============================
  Future<Map<String, dynamic>> signUpUser({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    String? email,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      final result = await ApiService.signUpUser(
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
        email: email,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );
      return result;
    } catch (e) {
      print('Sign up error: $e');
      return {
        'success': false,
        'message': 'Error creating account: ${e.toString()}',
      };
    }
  }

  // ==============================
  // SIGN IN USER - UPDATED VERSION
  // ==============================
  Future<Map<String, dynamic>> signInUser({
    required String username,
    required String password,
  }) async {
    try {
      final response = await ApiService.login(username, password);

      if (response != null && response['success'] == true) {
        // Save partial session for 2FA
        await savePartialUserSession(response);

        // ⭐⭐⭐ RETURN THE CORRECT RESPONSE STRUCTURE ⭐⭐⭐
        return {
          'success': true,
          'user_id': response['user_id'], // From API response
          'user': response['user'] ?? {}, // User data if available
          'message': response['message'] ?? 'Please verify with 2FA code',
        };
      } else {
        return {
          'success': false,
          'message': response?['message'] ?? 'Invalid username or password.',
        };
      }
    } catch (e) {
      print('Sign in error: $e');
      return {
        'success': false,
        'message': 'Error signing in: ${e.toString()}',
      };
    }
  }

  // ==============================
  // SAVE PARTIAL USER SESSION (BEFORE 2FA) - UPDATED
  // ==============================
  Future<void> savePartialUserSession(Map<String, dynamic> response) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Extract user data from response
      final user = response['user'] ?? {};
      final userId = response['user_id']?.toString() ?? user['id']?.toString();

      if (userId == null) {
        throw Exception('User ID not found in response');
      }

      await prefs.setString('userId', userId);
      await prefs.setString('username', user['username'] ?? '');
      await prefs.setString('firstName', user['firstName'] ?? user['first_name'] ?? '');
      await prefs.setString('lastName', user['lastName'] ?? user['last_name'] ?? '');
      await prefs.setString('email', user['email'] ?? '');
      await prefs.setBool('isPartiallyLoggedIn', true);
      await prefs.setBool('isAdmin', user['role'] == 'admin');
      await prefs.setString('role', user['role'] ?? 'user');
      await prefs.setBool('2fa_completed', false);

      print('✅ Partial user session saved: ${user['username']}');
      print('✅ First name: ${prefs.getString('firstName')}');
      print('✅ Last name: ${prefs.getString('lastName')}');
    } catch (e) {
      print('Error saving partial user session: $e');
      rethrow;
    }
  }

  // ==============================
  // SAVE FULL USER SESSION (AFTER 2FA) - UPDATED
  // ==============================
  Future<void> saveUserSession(Map<String, dynamic> user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', user['id'].toString());
      await prefs.setString('username', user['username'] ?? '');
      await prefs.setString('firstName', user['firstName'] ?? user['first_name'] ?? '');
      await prefs.setString('lastName', user['lastName'] ?? user['last_name'] ?? '');
      await prefs.setString('email', user['email'] ?? '');
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isAdmin', user['role'] == 'admin');
      await prefs.setString('role', user['role'] ?? 'user');
      await prefs.setBool('2fa_completed', true);

      print('✅ Full user session saved: ${user['username']}');
      print('✅ First name: ${prefs.getString('firstName')}');
      print('✅ Last name: ${prefs.getString('lastName')}');
    } catch (e) {
      print('Error saving user session: $e');
      rethrow;
    }
  }

  // ==============================
  // GET CURRENT USER SESSION - UPDATED
  // ==============================
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        final userData = {
          'id': prefs.getString('userId') ?? '',
          'username': prefs.getString('username') ?? '',
          'firstName': prefs.getString('firstName') ?? '',
          'lastName': prefs.getString('lastName') ?? '',
          'email': prefs.getString('email') ?? '',
          'isAdmin': prefs.getBool('isAdmin') ?? false,
          'role': prefs.getString('role') ?? 'user',
        };

        print('📋 Retrieved user data from storage: $userData');
        return userData;
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // ==============================
  // SIGN OUT USER
  // ==============================
  Future<void> signOut() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // ==============================
  // CHECK IF USER IS LOGGED IN (FULL AUTHENTICATION)
  // ==============================
  Future<bool> isUserLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      bool is2FACompleted = prefs.getBool('2fa_completed') ?? false;

      return isLoggedIn && is2FACompleted;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // ==============================
  // CHECK IF USER IS PARTIALLY LOGGED IN (BEFORE 2FA)
  // ==============================
  Future<bool> isUserPartiallyLoggedIn() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isPartiallyLoggedIn') ?? false;
    } catch (e) {
      print('Error checking partial login status: $e');
      return false;
    }
  }

  // ==============================
  // CHECK IF USER IS ADMIN
  // ==============================
  Future<bool> isUserAdmin() async {
    try {
      final user = await getCurrentUser();
      return user != null && user['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // ==============================
  // VERIFY 2FA TOKEN
  // ==============================
  Future<Map<String, dynamic>> verify2FAToken(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');

      if (userId == null) {
        return {
          'success': false,
          'message': 'User session not found. Please login again.',
        };
      }

      final verified = await ApiService.verifyToken(userId, token);

      if (verified) {
        // Get user data from partial session
        final user = {
          'id': prefs.getString('userId'),
          'username': prefs.getString('username'),
          'firstName': prefs.getString('firstName'),
          'lastName': prefs.getString('lastName'),
          'email': prefs.getString('email'),
          'role': prefs.getString('role'),
        };

        // Save full session
        await saveUserSession(user);

        return {
          'success': true,
          'message': '2FA verification successful!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid verification code. Please try again.',
        };
      }
    } catch (e) {
      print('2FA verification error: $e');
      return {
        'success': false,
        'message': 'Verification failed. Please try again.',
      };
    }
  }
}