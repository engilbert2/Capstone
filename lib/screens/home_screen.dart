import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/expense_provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? currentUser;
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  String _username = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Set status bar color to match dashboard green
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.green[700],
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    // Reset status bar when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      print('🔄 Loading user data...');
      final currentUser = await _authService.getCurrentUser();

      // Debug: Print the retrieved user data
      print('📋 Retrieved user data: $currentUser');

      if (currentUser != null) {
        setState(() {
          this.currentUser = currentUser;
          _username = currentUser['username'] ?? 'User';
          _isLoading = false;
        });

        // Debug: Print the stored values
        print('👤 Username: ${currentUser['username']}');
        print('👤 First Name: ${currentUser['firstName']}');
        print('👤 Last Name: ${currentUser['lastName']}');
        print('👤 Email: ${currentUser['email']}');
        print('👤 Role: ${currentUser['role']}');
        print('👤 Is Admin: ${currentUser['isAdmin']}');
      } else {
        print('❌ No user data found, redirecting to login');
        // If no user data found, navigate back to login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal
    ];
    int index = category.length % colors.length;
    return colors[index];
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

  void _showSalaryDialog(BuildContext context, ExpenseProvider expenseProvider) {
    final salaryController = TextEditingController(
        text: expenseProvider.monthlySalary > 0
            ? expenseProvider.monthlySalary.toString()
            : ''
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Monthly Salary'),
          content: TextField(
            controller: salaryController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monthly Salary',
              prefixText: '₱ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final salary = double.tryParse(salaryController.text) ?? 0;
                expenseProvider.monthlySalary = salary;
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading user data...'),
            ],
          ),
        ),
      );
    }

    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final formatCurrency = NumberFormat.currency(symbol: '₱');

    // Get user data with fallbacks for all possible field names
    final firstName = currentUser?['firstName'] ?? currentUser?['first_name'] ?? '';
    final lastName = currentUser?['lastName'] ?? currentUser?['last_name'] ?? '';
    final userName = '$firstName $lastName'.trim();
    final userInitial = firstName.isNotEmpty ? firstName[0] : (userName.isNotEmpty ? userName[0] : 'U');

    // Debug: Print what will be displayed
    print('🎯 Displaying name: $userName');
    print('🎯 First name: $firstName');
    print('🎯 Last name: $lastName');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        toolbarHeight: 70,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh user data',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Green header that spans full width
                Container(
                  width: double.infinity,
                  color: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          userInitial,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Text(
                              // Display first and last name or username as fallback
                              userName.isNotEmpty ? userName : (currentUser?['username'] ?? 'User'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Rest of the content remains the same
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),

                        // Monthly salary card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Monthly Salary',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 18),
                                      onPressed: () => _showSalaryDialog(context, expenseProvider),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  formatCurrency.format(expenseProvider.monthlySalary),
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Expenses and remaining budget
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    color: Colors.red[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.trending_down, color: Colors.red, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Total Expenses',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            formatCurrency.format(expenseProvider.totalExpenses),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Card(
                                    color: Colors.green[50],
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.account_balance, color: Colors.green, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Remaining',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            formatCurrency.format(expenseProvider.remainingBudget),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 24),

                        // Recent expenses header
                        Text(
                          'Recent Expenses',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),

                        // Recent expenses list
                        Consumer<ExpenseProvider>(
                          builder: (context, expenseProvider, child) {
                            final recentExpenses = expenseProvider.expenses.length > 5
                                ? expenseProvider.expenses.sublist(0, 5)
                                : expenseProvider.expenses;

                            if (recentExpenses.isEmpty) {
                              return Center(
                                child: Text(
                                  'No expenses yet',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: recentExpenses.length,
                              itemBuilder: (context, index) {
                                final expense = recentExpenses[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4),
                                  leading: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _getCategoryColor(expense.category),
                                    child: Text(
                                      expense.category[0],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    expense.name,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    DateFormat('MMM dd, yyyy').format(expense.date),
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  trailing: Text(
                                    formatCurrency.format(expense.amount),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Circular AI Chatbot Button positioned at the bottom right
            Positioned(
              right: 16,
              bottom: 80, // Position above the bottom navigation bar
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chatbot');
                },
                backgroundColor: Colors.green, // Changed from blue to green
                foregroundColor: Colors.white,
                child: Icon(Icons.smart_toy), // Changed to AI chatbot icon
                heroTag: 'chatbotButton',
                tooltip: 'AI Budget Assistant', // Updated tooltip
              ),
            ),
          ],
        ),
      ),
      // Fixed bottom navigation bar with labels
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Navigate to different screens based on index
          switch (index) {
            case 0:
            // Already on home screen
              break;
            case 1:
              Navigator.pushNamed(context, '/records');
              break;
            case 2:
            // This is the plus button, handled separately
              break;
            case 3:
              Navigator.pushNamed(context, '/category');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
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
          // This is the plus button in the middle - changed to green
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
        elevation: 2,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}