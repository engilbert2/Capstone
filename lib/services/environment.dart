import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class Environment {
  static String get fileName {
    if (kReleaseMode) {
      return '.env.production';
    } else if (kProfileMode) {
      return '.env.staging';
    } else {
      return '.env';
    }
  }

  static String get emailUser => dotenv.get('EMAIL_USER', fallback: '');
  static String get emailPassword => dotenv.get('EMAIL_PASSWORD', fallback: '');

  // Add debug method to check if environment variables are loaded
  static void debugEnvironment() {
    print('Environment file: ${fileName}');
    print('EMAIL_USER loaded: ${emailUser.isNotEmpty}');
    print('EMAIL_PASSWORD loaded: ${emailPassword.isNotEmpty}');
    if (emailUser.isEmpty || emailPassword.isEmpty) {
      print('WARNING: Email credentials not configured. 2FA emails will fail.');
      print('Please create a ${fileName} file with EMAIL_USER and EMAIL_PASSWORD');
    }
  }
}