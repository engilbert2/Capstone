import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class RecordsScreen extends StatefulWidget {
  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  DateTime _selectedMonth = DateTime.now();
  int _currentIndex = 1; // Set to 1 for Records screen

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
      // Already on records screen
        break;
      case 2:
      // This is the plus button, handled separately
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/category');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final formatCurrency = NumberFormat.currency(symbol: '₱');

    // Get expenses for the selected month
    final monthlyExpenses = expenseProvider.getExpensesForMonth(_selectedMonth);

    // Calculate total for the month
    final monthlyTotal = monthlyExpenses.fold(
        0.0, // Use double instead of int
            (sum, expense) => sum + expense.amount
    );

    // Calculate category breakdown
    final categoryBreakdown = Map<String, double>();
    for (var expense in monthlyExpenses) {
      categoryBreakdown.update(
        expense.category,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Expense Records',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green, // Changed from blue to green
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                          1
                      );
                    });
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios_rounded, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                          1
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Monthly total card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Total Spent in ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  formatCurrency.format(monthlyTotal),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.green, // Changed from blue to green
                  ),
                ),
                SizedBox(height: 16),
                if (monthlyExpenses.isNotEmpty) ...[
                  Divider(height: 1, color: Colors.grey[200]),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${monthlyExpenses.length} ${monthlyExpenses.length == 1 ? 'Expense' : 'Expenses'}',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${categoryBreakdown.length} ${categoryBreakdown.length == 1 ? 'Category' : 'Categories'}',
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Category breakdown (if expenses exist)
          if (monthlyExpenses.isNotEmpty) ...[
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Category Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 120,
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: categoryBreakdown.entries.map((entry) {
                  final percentage = (entry.value / monthlyTotal * 100).round();
                  return Container(
                    width: 140,
                    margin: EdgeInsets.only(right: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2D3748),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formatCurrency.format(entry.value),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.green, // Changed from blue to green
                          ),
                        ),
                        Text(
                          '$percentage% of total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Expense list header
          SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expense History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          // Expense list
          Expanded(
            child: monthlyExpenses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No expenses for this month',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFA0AEC0),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add expenses to see them here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFA0AEC0),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: monthlyExpenses.length,
              itemBuilder: (context, index) {
                final expense = monthlyExpenses[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(expense.category),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          expense.category[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      expense.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Text(
                      '${expense.category} • ${DateFormat('MMM dd').format(expense.date)}',
                      style: TextStyle(
                        color: Color(0xFF718096),
                      ),
                    ),
                    trailing: Text(
                      formatCurrency.format(expense.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Fixed bottom navigation bar with labels (copied from HomeScreen)
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
            icon: Icon(Icons.add, size: 32, color: Colors.green), // Changed from blue to green
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
        backgroundColor: Colors.green, // Changed from blue to green
        elevation: 0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Helper function to generate consistent colors for categories
  Color _getCategoryColor(String category) {
    final colors = [
      Colors.green, // Changed from blue to green
      Color(0xFF38A169), // Green
      Color(0xFFD69E2E), // Yellow
      Color(0xFFE53E3E), // Red
      Color(0xFF805AD5), // Purple
      Color(0xFF319795), // Teal
      Color(0xFFDD6B20), // Orange
    ];

    // Generate a consistent index based on category name
    final index = category.hashCode % colors.length;
    return colors[index];
  }
}