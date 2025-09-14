import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Arko/services/api_service.dart';
import 'package:Arko/services/auth_service.dart';
import 'package:Arko/screens/captcha_screen.dart';
import 'package:Arko/screens/home_screen.dart';
import 'package:Arko/components/my_button.dart';

class VerificationScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const VerificationScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  late String _userId;
  late String _userEmail;
  late String _username;
  final String baseUrl = "http://192.168.1.14/arco_api"; // Replace with your actual API URL

  @override
  void initState() {
    super.initState();

    // Extract user data safely
    _userId = widget.userData['id']?.toString() ?? widget.userData['user_id']?.toString() ?? '';

    // DEBUG: Print all keys to identify the correct email field
    print('🔍 ALL USER DATA KEYS: ${widget.userData.keys}');

    // Extract email - try to find the correct key
    _userEmail = _extractEmail(widget.userData);

    _username = widget.userData['username']?.toString() ?? '';

    print('🔍 Verification Screen - User Data:');
    print('   - ID: $_userId');
    print('   - Email: $_userEmail');
    print('   - Username: $_username');

    _setupFocusListeners();
  }

  // Helper method to extract email with debugging
  String _extractEmail(Map<String, dynamic> userData) {
    // Common email field names to try
    final possibleEmailKeys = [
      'email', 'Email', 'userEmail', 'emailAddress',
      'user_email', 'userEmailAddress', 'e_mail'
    ];

    for (var key in possibleEmailKeys) {
      if (userData.containsKey(key) && userData[key] != null) {
        final email = userData[key].toString();
        if (email.contains('@')) { // Basic email validation
          print('✅ Found email in key: "$key" = $email');
          return email;
        }
      }
    }

    // If no email found, check all values for something that looks like an email
    for (var entry in userData.entries) {
      final value = entry.value?.toString() ?? '';
      if (value.contains('@') && value.contains('.')) {
        print('✅ Found potential email in key: "${entry.key}" = $value');
        return value;
      }
    }

    print('❌ No email found in user data');
    return '';
  }

  void _setupFocusListeners() {
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && _controllers[i].text.isEmpty && i > 0) {
          FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
        }
      });
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() => _isResending = true);

    try {
      if (_userId.isEmpty) {
        throw Exception('User ID not found');
      }

      if (_userEmail.isEmpty) {
        throw Exception('Email not found. Please check your user data structure.');
      }

      print('🔄 Resending verification code to: $_userEmail');

      // Use the correct action name for resending
      final response = await http.post(
        Uri.parse("$baseUrl/mobile_auth.php"), // ✅ CORRECT - for mobile users
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "resend_code", // ✅ CORRECT ACTION NAME FOR RESENDING
          "user_id": _userId,
          "email": _userEmail,
        }),
      );

      print('📡 Resend response status: ${response.statusCode}');
      print('📡 Resend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('New verification code sent to $_userEmail'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to resend code: ${data['message']}');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }

    } catch (e) {
      print('Error resending verification code: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    if (_controllers.every((c) => c.text.isNotEmpty)) _verifyCode();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a 6-digit code';
      });
      return;
    }

    try {
      if (_userId.isEmpty) {
        throw Exception('User ID not found');
      }

      print('🔐 Verifying code: $code for user: $_userId');

      // Use regular verification (since verifyTokenWithRetry doesn't exist)
      final isValid = await ApiService.verifyToken(_userId, code);

      if (isValid) {
        // Successful verification
        print('✅ Token verified successfully');

        final authService = AuthService();

        // Get complete user data from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final userData = {
          'id': _userId,
          'username': prefs.getString('username') ?? _username,
          'email': prefs.getString('email') ?? _userEmail,
          'firstName': prefs.getString('firstName') ?? '',
          'lastName': prefs.getString('lastName') ?? '',
          'role': prefs.getString('role') ?? 'user',
        };

        await authService.saveUserSession(userData);

        final captchaCompleted = prefs.getBool('captcha_completed_${userData['username']}') ?? false;

        if (!captchaCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CaptchaScreen(userData: userData)),
          );
        } else {
          if (userData['role'] == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid or expired verification code';
        });

        for (var c in _controllers) c.clear();
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      }
    } catch (e) {
      print('❌ Verification error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            children: [
              const Icon(Icons.security, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('2FA Required', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                _userEmail.isNotEmpty
                    ? 'Code sent to: $_userEmail'
                    : 'Verification code sent to your email address',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              if (_userEmail.isEmpty) ...[
                SizedBox(height: 10),
                Text(
                  '(Could not find email address in user data)',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      onChanged: (value) => _onChanged(value, index),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : MyButton(
                onTap: _verifyCode,
                text: 'Verify Code',
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isResending ? null : _resendVerificationCode,
                child: _isResending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  'Resend Code',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Didn\'t receive the code?',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}