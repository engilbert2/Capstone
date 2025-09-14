import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class Environment {
  static String get fileName {
    if (kReleaseMode) {
      return '.env.production';
    } else if (kProfileMode) {
      return '.env.staging'; // Optional: create a .env.staging file
    } else {
      return '.env';
    }
  }

  static String get emailUser => dotenv.get('EMAIL_USER');
  static String get emailPassword => dotenv.get('EMAIL_PASSWORD');
  static String get zukiApiKey => dotenv.get('ZUKI_API_KEY');

  // Debug method to print environment status (removed in production)
  static void debugEnvironment() {
    if (!kReleaseMode) {
      print('🔧 Debug Environment Variables:');
      print('   - File: ${fileName}');
      print('   - EMAIL_USER: ${emailUser.isNotEmpty ? "Set (${emailUser.length} chars)" : "Not set"}');
      print('   - EMAIL_PASSWORD: ${emailPassword.isNotEmpty ? "Set (${emailPassword.length} chars)" : "Not set"}');
      print('   - All env vars: ${dotenv.env.keys.toList()}');
    }
  }

  // Helper method to check if all required env vars are loaded
  static bool get isConfigured {
    return emailUser.isNotEmpty && emailPassword.isNotEmpty;
  }

  // Get env variable with fallback
  static String getOrDefault(String key, String defaultValue) {
    try {
      return dotenv.get(key, fallback: defaultValue);
    } catch (e) {
      print('⚠️ Warning: Could not get env var $key, using default: $defaultValue');
      return defaultValue;
    }
  }
}