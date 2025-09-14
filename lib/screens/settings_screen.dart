import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 4; // Set to 4 for Settings screen

  // Get the current year dynamically
  final int currentYear = DateTime.now().year;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/records');
        break;
      case 2:
      // This is the plus button, handled separately
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/category');
        break;
      case 4:
      // Already on settings screen
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _shareApp() {
    Share.share('Check out Arko - a great expense tracking app!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // App Info Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APP INFO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green, size: 24),
                      SizedBox(width: 16),
                      Text(
                        'Version',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '1.0.0',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.update, color: Colors.green, size: 24),
                      SizedBox(width: 16),
                      Text(
                        'Last Updated',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '$currentYear', // Updated to use dynamic year
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Feedback Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FEEDBACK',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Send Feedback
                  ListTile(
                    leading: Icon(Icons.feedback, color: Colors.green),
                    title: Text('Send Feedback'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/feedback');
                    },
                  ),
                  Divider(height: 1),
                  // Share App
                  ListTile(
                    leading: Icon(Icons.share, color: Colors.green),
                    title: Text('Share with Friends'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _shareApp,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Account Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Logout
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed bottom navigation bar with labels
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Records',
          ),
          // This is the plus button in the middle
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 32, color: Colors.green),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
      // Floating action button positioned at the center of the bottom navigation bar
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/expense');
        },
        child: Icon(Icons.add, size: 32),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}