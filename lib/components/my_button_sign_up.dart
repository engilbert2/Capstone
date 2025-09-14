import 'package:flutter/material.dart';

class MyButtonSignUp extends StatelessWidget {
  final VoidCallback? onTap;
  const MyButtonSignUp({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: const Color(0xFF00B8D4), // teal-ish blue background
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "Sign Up",
            style: TextStyle(
              color: Colors.white, // white text for good contrast
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
