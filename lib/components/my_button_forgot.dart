import 'package:flutter/material.dart';

class MyButtonForgot extends StatelessWidget {
  final Function()? onTap;
  final Color color; // Add color parameter

  const MyButtonForgot({
    super.key,
    required this.onTap,
    this.color = const Color.fromARGB(255, 0, 0, 0), // Default to black if no color provided
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(25.0),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: color, // Use the provided color
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text("Submit Answer",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }
}