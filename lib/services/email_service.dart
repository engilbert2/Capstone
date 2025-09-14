import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:Arko/config/flutter_dotenv.dart'; // Add this import

class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Get email credentials from environment variables using Environment class
  String get smtpHost => 'smtp.gmail.com';
  int get smtpPort => 587;
  String get username => Environment.emailUser;
  String get password => Environment.emailPassword;

  Future<bool> sendVerificationEmail(String toEmail, String token) async {
    // Check if email credentials are configured
    if (username.isEmpty || password.isEmpty) {
      print('❌ Email credentials not configured. Please set EMAIL_USER and EMAIL_PASSWORD in your .env file');
      return false;
    }

    try {
      final server = SmtpServer(smtpHost,
          username: username,
          password: password,
          port: smtpPort
      );

      final message = Message()
        ..from = Address(username, 'Budget App')
        ..recipients.add(toEmail)
        ..subject = 'Your Verification Code'
        ..text = 'Your verification code is: $token\nThis code will expire in 15 minutes.';

      await send(message, server);
      print('✅ Verification email sent to $toEmail');
      return true;
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }
}