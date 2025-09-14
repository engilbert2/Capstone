import 'package:flutter/material.dart';
import 'package:Arko/database/mysql_database.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Define the missing variables
  Map<String, dynamic>? _adminStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // Update the _loadAdminData method
  Future<void> _loadAdminData() async {
    try {
      final stats = await MySQLService().getAdminStatistics();
      setState(() {
        _adminStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_adminStats == null) {
      return const Center(child: Text('No data available'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Users: ${_adminStats!['totalUsers'] ?? 0}'),
            Text('Active Users: ${_adminStats!['activeUsers'] ?? 0}'),
            Text('Total Orders: ${_adminStats!['totalOrders'] ?? 0}'),
            // Add more statistics as needed
          ],
        ),
      ),
    );
  }
}