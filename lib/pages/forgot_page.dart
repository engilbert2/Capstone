import 'package:flutter/material.dart';
import 'package:Arko/components/my_text_field.dart';
import 'package:Arko/components/my_button_forgot.dart';
import 'package:Arko/services/api_service.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({Key? key}) : super(key: key);

  @override
  _ForgotPageState createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final usernameController = TextEditingController();
  final answerController = TextEditingController();
  final newPasswordController = TextEditingController();
  String? selectedSecurityQuestion;
  bool _isLoading = false;
  String _errorMessage = '';

  final List<String> securityQuestions = [
    "What is your mother's maiden name?",
    "What was the name of your first pet?",
    "What was the model of your first car?",
    "In what town was your first job?",
    "What is the name of the school you attended for sixth grade?",
  ];

  // ===============================
  // Verify and reset password
  // ===============================
  void verifyAndUpdatePassword() async {
    // Clear previous error
    setState(() => _errorMessage = '');

    if (usernameController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your username');
      return;
    }
    if (selectedSecurityQuestion == null) {
      setState(() => _errorMessage = 'Please select a security question');
      return;
    }
    if (answerController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter the answer');
      return;
    }
    if (newPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a new password');
      return;
    }
    if (newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔄 Starting password reset process...');
      print('👤 Username: ${usernameController.text.trim()}');
      print('❓ Question: $selectedSecurityQuestion');
      print('✅ Answer: ${answerController.text.trim()}');
      print('🔑 New Password: ${newPasswordController.text}');

      final success = await ApiService.resetPassword(
        usernameController.text.trim(),
        selectedSecurityQuestion!,
        answerController.text.trim(),
        newPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        print('✅ Password reset successful!');
        _showSnack('Password updated successfully!', isError: false);
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      } else {
        print('❌ Password reset failed');
        setState(() => _errorMessage = 'Security question/answer mismatch or user not found');
        _showSnack('Security question/answer mismatch or user not found');
      }
    } catch (e) {
      print('❌ Password reset error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again later.';
      });
      _showSnack('An error occurred. Please try again later.');
    }
  }

  // ===============================
  // Show snack message
  // ===============================
  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset('assets/images/tinylogo.png', width: 100, height: 100),
              const SizedBox(height: 20),

              // Error message display
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 10),

              MyTextField(
                controller: usernameController,
                hintText: 'Username',
                obscureText: false,
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedSecurityQuestion,
                      decoration: const InputDecoration(border: InputBorder.none),
                      hint: const Text("Select a Security Question"),
                      onChanged: (String? newValue) {
                        setState(() => selectedSecurityQuestion = newValue);
                      },
                      items: securityQuestions.map((question) {
                        return DropdownMenuItem(
                          value: question,
                          child: Text(question),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              MyTextField(
                controller: answerController,
                hintText: 'Answer to Security Question',
                obscureText: false,
              ),
              const SizedBox(height: 20),

              MyTextField(
                controller: newPasswordController,
                hintText: 'New Password',
                obscureText: true,
              ),
              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator()
                  : MyButtonForgot(
                onTap: verifyAndUpdatePassword,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}