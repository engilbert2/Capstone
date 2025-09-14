import 'package:flutter/material.dart';
import 'package:Arko/services/auth_service.dart';
import 'package:Arko/services/api_service.dart';

class TwoFASettingsScreen extends StatefulWidget {
  @override
  _TwoFASettingsScreenState createState() => _TwoFASettingsScreenState();
}

class _TwoFASettingsScreenState extends State<TwoFASettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _is2FAEnabled = false;
  Map<String, dynamic>? _currentUser;
  String? _userEmail; // Store email separately

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUser = currentUser;
          // Extract email - try different possible keys
          _userEmail = _extractEmail(currentUser);
        });
        await _check2FAStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please login to manage 2FA settings')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper method to extract email from user data
  String? _extractEmail(Map<String, dynamic> userData) {
    // Try different possible keys for email
    return userData['email'] ??
        userData['Email'] ??
        userData['userEmail'] ??
        userData['emailAddress'] ??
        userData['user_email'];
  }

  Future<void> _check2FAStatus() async {
    if (_currentUser == null || _currentUser!['id'] == null) return;

    try {
      bool enabled = await ApiService.is2FAEnabled(_currentUser!['id'].toString());
      setState(() => _is2FAEnabled = enabled);
    } catch (e) {
      print('Error checking 2FA status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking 2FA status')),
      );
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (_currentUser == null || _currentUser!['id'] == null) return;

    setState(() => _isLoading = true);

    try {
      bool success = await ApiService.toggle2FA(_currentUser!['id'].toString(), value);
      if (success) {
        setState(() => _is2FAEnabled = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('2FA ${value ? 'enabled' : 'disabled'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update 2FA settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two-Factor Authentication'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Two-Factor Authentication',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add an extra layer of security to your account',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _is2FAEnabled,
                          onChanged: _currentUser != null ? _toggle2FA : null,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'When enabled, you will receive a verification code via email at ${_userEmail ?? 'your email address'} whenever you sign in.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_is2FAEnabled)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('✓ Two-factor authentication is active'),
                      Text('✓ Verification codes will be sent to ${_userEmail ?? 'your email'}'),
                    ],
                  ),
                ),
              ),
            if (_currentUser == null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Please login to manage 2FA settings',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}