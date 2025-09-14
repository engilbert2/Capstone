import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense_item.dart';
import '../models/category_item.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // Add a welcome message from the bot and automatically analyze expenses
    _messages.add({
      'text': 'Hello! I\'m your Arco Budget Assistant. Analyzing your expenses to provide personalized suggestions...',
      'isUser': false,
      'time': DateTime.now(),
    });

    // Automatically analyze expenses when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _analyzeExpensesAndProvideSuggestions();
    });
  }

  void _analyzeExpensesAndProvideSuggestions() async {
    setState(() {
      _isAnalyzing = true;
    });

    // Add a loading indicator message
    setState(() {
      _messages.add({
        'text': '🔍 Analyzing your spending patterns...',
        'isUser': false,
        'time': DateTime.now(),
      });
    });
    _scrollToBottom();

    // Wait a moment for dramatic effect
    await Future.delayed(Duration(seconds: 1));

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final expenses = expenseProvider.expenses;
    final categories = expenseProvider.categories;

    if (expenses.isEmpty) {
      setState(() {
        _messages.add({
          'text': 'I don\'t see any expenses yet. Start adding expenses to get personalized money-saving suggestions!',
          'isUser': false,
          'time': DateTime.now(),
        });
      });
      _scrollToBottom();
      setState(() {
        _isAnalyzing = false;
      });
      return;
    }

    // Analyze expenses and generate suggestions
    final suggestions = _generateExpenseSuggestions(expenses, categories, expenseProvider);

    setState(() {
      // Combine all suggestions into one clean, formatted message
      String formattedSuggestions = '✅ Analysis complete! Here are my personalized suggestions:\n\n';

      for (int i = 0; i < suggestions.length; i++) {
        formattedSuggestions += '• ${suggestions[i]}\n';
      }

      formattedSuggestions += '\nHow else can I help you with your finances today?';

      _messages.add({
        'text': formattedSuggestions,
        'isUser': false,
        'time': DateTime.now(),
      });
    });

    _scrollToBottom();
    setState(() {
      _isAnalyzing = false;
    });
  }

  List<String> _generateExpenseSuggestions(
      List<ExpenseItem> expenses,
      List<CategoryItem> categories,
      ExpenseProvider expenseProvider) {
    final suggestions = <String>[];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    // Get current month expenses
    final currentMonthExpenses = expenseProvider.getExpensesForMonth(currentMonth);
    final lastMonthExpenses = expenseProvider.getExpensesForMonth(lastMonth);

    // Calculate total spending
    final totalSpent = expenseProvider.totalExpenses;
    final monthlySalary = expenseProvider.monthlySalary;
    final remainingBudget = expenseProvider.remainingBudget;

    // 1. General budget status
    if (monthlySalary > 0) {
      final spendingPercentage = (totalSpent / monthlySalary * 100).round();

      if (spendingPercentage > 80) {
        suggestions.add('You\'ve spent $spendingPercentage% of your monthly salary. Consider cutting back on non-essential expenses.');
      } else if (spendingPercentage > 50) {
        suggestions.add('You\'ve spent $spendingPercentage% of your monthly salary. You\'re on track but could save more by reviewing your spending.');
      } else {
        suggestions.add('Great job! You\'ve only spent $spendingPercentage% of your monthly salary, leaving ₱${remainingBudget.toStringAsFixed(2)} available.');
      }
    }

    // 2. Category analysis
    final categoryTotals = <String, double>{};
    for (var expense in expenses) {
      categoryTotals.update(
        expense.category,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    // Find highest spending category
    if (categoryTotals.isNotEmpty) {
      final highestCategory = categoryTotals.entries.reduce(
              (a, b) => a.value > b.value ? a : b);

      if (highestCategory.value > monthlySalary * 0.3) {
        suggestions.add('Your highest spending category is "${highestCategory.key}" at ₱${highestCategory.value.toStringAsFixed(2)}. This is over 30% of your income - consider finding alternatives.');
        // Add specific saving tips based on category
        suggestions.add(_getCategorySpecificSavingsTip(highestCategory.key, highestCategory.value));
      } else {
        suggestions.add('Your highest spending category is "${highestCategory.key}" at ₱${highestCategory.value.toStringAsFixed(2)}.');
      }
    }

    // 3. Compare with previous month
    if (lastMonthExpenses.isNotEmpty && currentMonthExpenses.isNotEmpty) {
      final lastMonthTotal = lastMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      final currentMonthTotal = currentMonthExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

      final difference = currentMonthTotal - lastMonthTotal;
      final percentageChange = (difference / lastMonthTotal * 100).round();

      if (difference > 0) {
        suggestions.add('Your spending increased by ${percentageChange.abs()}% compared to last month. Try to identify what\'s causing this increase.');
      } else if (difference < 0) {
        suggestions.add('Great! Your spending decreased by ${percentageChange.abs()}% compared to last month. Keep up the good habits!');
      }
    }

    // 4. Recurring expenses analysis
    final recurringExpenses = expenses.where((e) => e.isRecurring).toList();
    if (recurringExpenses.isNotEmpty) {
      final recurringTotal = recurringExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      suggestions.add('You have ${recurringExpenses.length} recurring expenses totaling ₱${recurringTotal.toStringAsFixed(2)} monthly. Review these subscriptions regularly.');

      // Add specific tips for recurring expenses
      suggestions.add('Consider canceling at least one subscription to save ₱${(recurringTotal/recurringExpenses.length).toStringAsFixed(2)} monthly.');
    }

    // 5. Daily spending rate - only calculate if there are expenses
    if (expenses.isNotEmpty) {
      final firstExpenseDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
      final daysTracked = now.difference(firstExpenseDate).inDays + 1;
      final dailySpendingRate = totalSpent / daysTracked;

      suggestions.add('Your average daily spending is ₱${dailySpendingRate.toStringAsFixed(2)}. At this rate, you\'ll spend ₱${(dailySpendingRate * 30).toStringAsFixed(2)} this month.');

      // Add daily saving tip
      suggestions.add('Try reducing your daily spending by 10% to save ₱${(dailySpendingRate * 0.1 * 30).toStringAsFixed(2)} this month.');
    }

    // 6. Budget limit check
    if (expenseProvider.isBudgetLimitActive) {
      final spentInPeriod = expenseProvider.totalSpentInLimitPeriod;
      final limit = expenseProvider.budgetLimit;
      final percentageUsed = (spentInPeriod / limit * 100).round();

      if (percentageUsed > 90) {
        suggestions.add('You\'ve used $percentageUsed% of your budget limit (₱$limit). Consider pausing non-essential spending until the next period.');
      } else if (percentageUsed > 70) {
        suggestions.add('You\'ve used $percentageUsed% of your budget limit. Be mindful of your spending to stay within budget.');
      }
    }

    // 7. Add specific money-saving strategies based on spending patterns
    suggestions.addAll(_getPersonalizedSavingsStrategies(expenses, monthlySalary));

    // 8. Generic money-saving tips (if we don't have enough specific suggestions)
    if (suggestions.length < 5) {
      suggestions.addAll([
        'Consider cooking at home more often instead of eating out to save money.',
        'Review your subscriptions and cancel any you don\'t use regularly.',
        'Set specific financial goals to stay motivated with your budgeting.',
        'Try the 24-hour rule: wait a day before making non-essential purchases to avoid impulse buying.',
        'Use cash instead of cards for discretionary spending to be more aware of your expenses.',
        'Plan your meals for the week to reduce food waste and unnecessary grocery purchases.',
        'Look for generic brands instead of name brands to save on everyday items.',
        'Consider using public transportation or carpooling to save on fuel costs.',
      ]);
    }

    return suggestions;
  }

  String _getCategorySpecificSavingsTip(String category, double amount) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return 'For food expenses: Consider meal prepping to save ₱${(amount * 0.2).toStringAsFixed(2)} monthly. Limit eating out to twice a week.';
      case 'transportation':
        return 'For transportation: Use public transport or carpool 2 days a week to save ₱${(amount * 0.15).toStringAsFixed(2)} monthly.';
      case 'entertainment':
        return 'For entertainment: Look for free community events instead of paid activities to save ₱${(amount * 0.25).toStringAsFixed(2)} monthly.';
      case 'shopping':
        return 'For shopping: Implement a 48-hour cooling-off period before purchases to reduce impulse buying and save ₱${(amount * 0.3).toStringAsFixed(2)} monthly.';
      case 'utilities':
        return 'For utilities: Turn off lights when not in use and unplug devices to save ₱${(amount * 0.1).toStringAsFixed(2)} monthly on electricity.';
      case 'subscriptions':
        return 'Review your subscriptions and cancel any you haven\'t used in the past month to save ₱${(amount * 0.4).toStringAsFixed(2)} monthly.';
      default:
        return 'For ${category.toLowerCase()}: Review your spending in this category and identify areas where you can cut back by 15% to save ₱${(amount * 0.15).toStringAsFixed(2)} monthly.';
    }
  }

  List<String> _getPersonalizedSavingsStrategies(List<ExpenseItem> expenses, double monthlySalary) {
    final strategies = <String>[];
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Calculate weekly spending
    final weeklyExpenses = expenses.where((e) =>
        e.date.isAfter(weekStart)).fold(0.0, (sum, expense) => sum + expense.amount);

    if (weeklyExpenses > monthlySalary / 4 * 1.2) {
      strategies.add('Your weekly spending is higher than recommended. Try implementing a "no-spend day" once a week to save ₱${(weeklyExpenses/7).toStringAsFixed(2)} weekly.');
    }

    // Check for frequent small purchases
    final smallPurchases = expenses.where((e) => e.amount < 100 &&
        e.date.isAfter(now.subtract(Duration(days: 7)))).length;

    if (smallPurchases > 10) {
      strategies.add('You have $smallPurchases small purchases this week. These add up quickly! Consider bundling these expenses or eliminating some to save ₱${(smallPurchases * 20).toStringAsFixed(2)} weekly.');
    }

    // Check for expensive recent purchases
    final recentLargePurchases = expenses.where((e) => e.amount > 500 &&
        e.date.isAfter(now.subtract(Duration(days: 14)))).toList();

    if (recentLargePurchases.isNotEmpty) {
      strategies.add('You\'ve made ${recentLargePurchases.length} large purchases recently. For future large purchases, try saving up specifically for them instead of impacting your regular budget.');
    }

    // Check time-based patterns (weekend vs weekday spending)
    final weekendExpenses = expenses.where((e) =>
    [6, 7].contains(e.date.weekday) &&
        e.date.isAfter(now.subtract(Duration(days: 30)))).fold(0.0, (sum, expense) => sum + expense.amount);

    final weekdayExpenses = expenses.where((e) =>
    ![6, 7].contains(e.date.weekday) &&
        e.date.isAfter(now.subtract(Duration(days: 30)))).fold(0.0, (sum, expense) => sum + expense.amount);

    if (weekendExpenses > weekdayExpenses * 1.5) {
      strategies.add('You spend ${(weekendExpenses/weekdayExpenses).toStringAsFixed(1)}x more on weekends. Plan weekend activities with budgets to save ₱${((weekendExpenses - weekdayExpenses) * 0.3).toStringAsFixed(2)} monthly.');
    }

    return strategies;
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isUser': true,
        'time': DateTime.now(),
      });
    });

    // Clear input field
    final userMessage = _messageController.text;
    _messageController.clear();

    // Scroll to bottom
    _scrollToBottom();

    // Simulate bot response after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _getBotResponse(userMessage);
    });
  }

  void _getBotResponse(String userMessage) {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    String response = '';

    // Simple response logic based on keywords
    if (userMessage.toLowerCase().contains('hello') ||
        userMessage.toLowerCase().contains('hi')) {
      response = 'Hello! How can I assist with your budget today?';
    } else if (userMessage.toLowerCase().contains('salary') ||
        userMessage.toLowerCase().contains('income')) {
      response = 'Your monthly salary is ₱${expenseProvider.monthlySalary.toStringAsFixed(2)}. '
          'You have ₱${expenseProvider.remainingBudget.toStringAsFixed(2)} remaining this month.';
    } else if (userMessage.toLowerCase().contains('expense') ||
        userMessage.toLowerCase().contains('spent')) {
      response = 'You\'ve spent ₱${expenseProvider.totalExpenses.toStringAsFixed(2)} this month. '
          'Your remaining budget is ₱${expenseProvider.remainingBudget.toStringAsFixed(2)}.';
    } else if (userMessage.toLowerCase().contains('budget') ||
        userMessage.toLowerCase().contains('remaining')) {
      response = 'Your remaining budget is ₱${expenseProvider.remainingBudget.toStringAsFixed(2)}.';
    } else if (userMessage.toLowerCase().contains('category') ||
        userMessage.toLowerCase().contains('categories')) {
      final categories = expenseProvider.expenses.map((e) => e.category).toSet();
      if (categories.isEmpty) {
        response = 'You haven\'t added any expenses with categories yet.';
      } else {
        response = 'Your expense categories: ${categories.join(', ')}.';
      }
    } else if (userMessage.toLowerCase().contains('suggestion') ||
        userMessage.toLowerCase().contains('advice') ||
        userMessage.toLowerCase().contains('tip') ||
        userMessage.toLowerCase().contains('save money') ||
        userMessage.toLowerCase().contains('saving')) {
      // Re-analyze and provide suggestions
      _analyzeExpensesAndProvideSuggestions();
      return;
    } else if (userMessage.toLowerCase().contains('help')) {
      response = 'I can help you with:\n'
          '- Checking your salary and remaining budget\n'
          '- Viewing your expenses\n'
          '- Understanding your spending categories\n'
          '- Providing personalized money-saving suggestions\n'
          '- General budget advice\n\n'
          'Try asking about your "salary", "expenses", or "budget", or ask for "suggestions" to save money.';
    } else if (userMessage.toLowerCase().contains('recurring') ||
        userMessage.toLowerCase().contains('subscription')) {
      final recurringExpenses = expenseProvider.expenses.where((e) => e.isRecurring).toList();
      if (recurringExpenses.isEmpty) {
        response = 'You don\'t have any recurring expenses tracked.';
      } else {
        final total = recurringExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
        response = 'You have ${recurringExpenses.length} recurring expenses totaling ₱${total.toStringAsFixed(2)} monthly. '
            'Consider reviewing these for potential savings.';
      }
    } else if (userMessage.toLowerCase().contains('daily') ||
        userMessage.toLowerCase().contains('day')) {
      final expenses = expenseProvider.expenses;
      if (expenses.isEmpty) {
        response = 'No expenses recorded yet.';
      } else {
        final now = DateTime.now();
        final firstExpenseDate = expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
        final daysTracked = now.difference(firstExpenseDate).inDays + 1;
        final dailySpending = expenseProvider.totalExpenses / daysTracked;
        response = 'Your average daily spending is ₱${dailySpending.toStringAsFixed(2)}. '
            'At this rate, you\'ll spend ₱${(dailySpending * 30).toStringAsFixed(2)} this month.';
      }
    } else {
      response = 'I\'m not sure how to help with that. Try asking about your budget, expenses, or request money-saving suggestions. Type "help" for more options.';
    }

    setState(() {
      _messages.add({
        'text': response,
        'isUser': false,
        'time': DateTime.now(),
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arco Budget Assistant'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isAnalyzing ? null : _analyzeExpensesAndProvideSuggestions,
            tooltip: 'Re-analyze expenses',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  message['text'],
                  message['isUser'],
                  message['time'],
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, DateTime time) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  Icons.memory, // AI/brain icon instead of stars
                  color: Colors.white,
                  size: 20,
                ),
                radius: 16,
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(time),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Icon(
                  Icons.person,
                  color: Colors.grey[700],
                ),
                radius: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.deepPurple,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}