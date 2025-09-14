import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String text;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    this.backgroundColor = const Color(0xFF1ED891),
    this.padding = const EdgeInsets.all(25.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 25),
  });

  // Named constructor for the "forgot password" style button
  const MyButton.forgot({
    super.key,
    required this.onTap,
    this.text = "Submit Answer",
    this.backgroundColor = const Color.fromARGB(255, 0, 0, 0),
    this.padding = const EdgeInsets.all(25.0),
    this.margin = const EdgeInsets.symmetric(horizontal: 25),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}