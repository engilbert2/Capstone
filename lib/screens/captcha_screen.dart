import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class CaptchaScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CaptchaScreen({super.key, required this.userData});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  late String correctCode;
  String? selectedCode;
  bool isVerified = false;
  bool isRobotCheckboxChecked = false;
  late List<String> codeOptions;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final random = Random();

    correctCode = (1000 + random.nextInt(9000)).toString();

    codeOptions = [correctCode];
    while (codeOptions.length < 3) {
      String randomCode = (1000 + random.nextInt(9000)).toString();
      if (!codeOptions.contains(randomCode)) {
        codeOptions.add(randomCode);
      }
    }

    codeOptions.shuffle();
  }

  Future<void> _saveCaptchaCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('captcha_completed_${widget.userData['username']}', true);
  }

  void _verifyCaptcha() {
    if (selectedCode == correctCode && isRobotCheckboxChecked) {
      setState(() {
        isVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CAPTCHA verified successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _saveCaptchaCompletion();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // Check if user is admin and navigate accordingly
          final isAdmin = widget.userData['role'] == 'admin';
          if (isAdmin) {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the security check.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CAPTCHA Verification'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight - 100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Security Verification',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please complete the security check to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Select the correct code:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          correctCode,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: codeOptions.map((code) {
                          bool isSelected = selectedCode == code;
                          bool isCorrect = code == correctCode;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCode = code;
                              });
                            },
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isCorrect ? Colors.green[100] : Colors.red[100])
                                    : Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? (isCorrect ? Colors.green : Colors.red)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: isCorrect ? Colors.green : Colors.red,
                                      size: 18,
                                    ),
                                  if (isSelected) const SizedBox(width: 5),
                                  Text(
                                    code,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? (isCorrect ? Colors.green : Colors.red)
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      isRobotCheckboxChecked = !isRobotCheckboxChecked;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRobotCheckboxChecked
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isRobotCheckboxChecked ? Colors.green : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "I'm not a robot",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (selectedCode == correctCode && isRobotCheckboxChecked)
                        ? _verifyCaptcha
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: (selectedCode == correctCode && isRobotCheckboxChecked) ? 2 : 0,
                    ),
                    child: const Text(
                      'Verify CAPTCHA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}