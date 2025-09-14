import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Config
import 'config/flutter_dotenv.dart';

// Models
import 'package:Arko/models/expense_item.dart';
import 'package:Arko/models/category_item.dart';

// Providers
import 'package:Arko/providers/expense_provider.dart';

// Services
import 'package:Arko/services/auth_service.dart';

// Screens
import 'package:Arko/screens/home_screen.dart';
import 'package:Arko/screens/expense_screen.dart';
import 'package:Arko/screens/records_screen.dart';
import 'package:Arko/screens/category_screen.dart';
import 'package:Arko/screens/settings_screen.dart';
import 'package:Arko/screens/feedback_screen.dart';
import 'package:Arko/screens/two_fa_settings.dart';
import 'package:Arko/screens/verification_screen.dart';
import 'package:Arko/screens/captcha_screen.dart';
import 'package:Arko/screens/chatbot_screen.dart'; // Added import for ChatbotScreen

// Admin Screens
import 'package:Arko/admin/admin_dashboard.dart';
import 'package:Arko/admin/admin_users.dart';
import 'package:Arko/admin/admin_feedback.dart';

// Pages
import 'package:Arko/pages/login_page.dart';
import 'package:Arko/pages/sign_up_page.dart';
import 'package:Arko/pages/forgot_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: Environment.fileName);

    // Initialize Hive
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseItemAdapter());
    Hive.registerAdapter(CategoryItemAdapter());

    await Hive.openBox<ExpenseItem>('expenses');
    await Hive.openBox<CategoryItem>('categories');
    await Hive.openBox('settings');

    runApp(const MyApp());
  } catch (e) {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ExpenseProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Arko',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/initialization',
        routes: {
          '/initialization': (context) => const InitializationScreen(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/forgot': (context) => const ForgotPage(),
          '/home': (context) => HomeScreen(),
          '/expense': (context) => ExpenseScreen(),
          '/records': (context) => RecordsScreen(),
          '/category': (context) => CategoryScreen(),
          '/settings': (context) => SettingsScreen(),
          '/feedback': (context) => FeedbackScreen(),
          '/2fa-settings': (context) => TwoFASettingsScreen(),
          '/chatbot': (context) => ChatbotScreen(), // Added chatbot route

          // Routes that require arguments
          '/verification': (context) {
            final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return VerificationScreen(userData: args ?? {});
          },
          '/captcha': (context) {
            final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return CaptchaScreen(userData: args ?? {});
          },

          // Admin routes
          '/admin_dashboard': (context) => AdminDashboard(),
          '/admin_users': (context) => AdminUsersScreen(),
          '/admin_feedback': (context) => AdminFeedbackScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const LoginPage());
        },
      ),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String _statusMessage = 'Starting initialization...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() => _statusMessage = 'Initializing provider...');
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.initialize();

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final isLoggedIn = await AuthService().isUserLoggedIn();
      final isAdmin = await AuthService().isUserAdmin();

      if (isLoggedIn) {
        Navigator.pushReplacementNamed(
            context, isAdmin ? '/admin_dashboard' : '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() => _statusMessage = 'Error initializing app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 20),
            Text(_statusMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}