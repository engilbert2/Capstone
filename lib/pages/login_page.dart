import 'package:flutter/material.dart';
import 'package:Arko/components/my_button.dart';
import 'package:Arko/components/my_button_sign_up.dart';
import 'package:Arko/services/auth_service.dart';
import 'package:Arko/services/api_service.dart';
import 'package:Arko/screens/verification_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkPartialLogin();
  }

  Future<void> _checkPartialLogin() async {
    try {
      final authService = AuthService();
      final isPartiallyLoggedIn = await authService.isUserPartiallyLoggedIn();
      if (isPartiallyLoggedIn) {
        await authService.signOut();
      }
    } catch (e) {
      print('Error checking partial login: $e');
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signUserIn(BuildContext context) async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    print('Login attempt - Username: "$username", Password: "$password"');

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Regular login - THIS ALREADY GENERATES AND SENDS THE TOKEN
      final loginResult = await AuthService().signInUser(
        username: username,
        password: password,
      );

      print('Login result: $loginResult');

      // ⭐⭐⭐ FIXED: Check for success correctly ⭐⭐⭐
      if (loginResult['success'] == true) {
        print('Login successful, proceeding to 2FA');

        // ⭐⭐⭐ NO NEED TO GENERATE TOKEN AGAIN - IT'S ALREADY DONE DURING LOGIN ⭐⭐⭐
        // The token was already generated, stored, and emailed during the login process

        final userId = loginResult['user_id']?.toString();
        final userEmail = loginResult['user']?['email'] ?? username;

        if (userId != null) {
          // Navigate directly to verification screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                userData: {
                  'id': userId,
                  'email': userEmail,
                  'username': username,
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User ID not received')),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loginResult['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Image.asset('assets/images/logo.png', width: 200, height: 200),
                const SizedBox(height: 30),

                // Username field
                TextField(
                  controller: usernameController,
                  obscureText: false,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    fillColor: Colors.grey.shade200,
                    filled: true,
                    hintText: 'Username',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    fillColor: Colors.grey.shade200,
                    filled: true,
                    hintText: 'Password',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                // Forgot Password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/forgot'),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Login button
                _isLoading
                    ? const CircularProgressIndicator()
                    : MyButton(
                  onTap: () => signUserIn(context),
                  text: 'Sign In',
                ),

                const SizedBox(height: 20),
                const Text("Don't have an account?"),
                const SizedBox(height: 10),

                // Sign up button
                MyButtonSignUp(
                  onTap: () => Navigator.pushNamed(context, '/signup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}