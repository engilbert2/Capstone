import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense_item.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _monthlySalaryController = TextEditingController();
  final _maxAmountController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  bool _isRecurring = false;
  bool _isLoading = true;
  Map<String, double> _recurringExpenseTotals = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      if (!expenseProvider.isInitialized) {
        await expenseProvider.initialize();
      }

      // Calculate recurring expense totals
      _calculateRecurringExpenseTotals(expenseProvider.expenses);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (expenseProvider.monthlySalary > 0) {
            _monthlySalaryController.text = expenseProvider.monthlySalary.toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateRecurringExpenseTotals(List<ExpenseItem> expenses) {
    _recurringExpenseTotals.clear();
    for (var expense in expenses) {
      if (expense.isRecurring && expense.category.isNotEmpty) {
        _recurringExpenseTotals.update(
          expense.category,
              (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50] ?? Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey[700] ?? Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categories = expenseProvider.categories;

    // Check if we're currently in a budget limit period
    final isInLimitPeriod = expenseProvider.isBudgetLimitActive;

    // Calculate total spent in the current limit period
    double totalSpentInPeriod = expenseProvider.totalSpentInLimitPeriod;

    // Check if adding this expense would exceed the limit
    final proposedAmount = double.tryParse(_amountController.text) ?? 0;
    final wouldExceedLimit = expenseProvider.wouldExceedBudgetLimit(proposedAmount);

    // Check if this would exceed category limit
    final wouldExceedCategoryLimit = _selectedCategory != null ?
    expenseProvider.wouldExceedCategoryLimit(_selectedCategory!, proposedAmount) : false;

    // Check if this would exceed recurring expense max amount using provider
    bool wouldExceedMaxAmount = false;
    String maxAmountMessage = '';

    if (_selectedCategory != null) {
      final maxAmount = expenseProvider.getCategoryMaxAmount(_selectedCategory!);
      if (maxAmount > 0) {
        final currentTotal = _recurringExpenseTotals[_selectedCategory!] ?? 0;
        if ((currentTotal + proposedAmount) > maxAmount) {
          wouldExceedMaxAmount = true;
          maxAmountMessage = 'Would exceed maximum amount of ₱${maxAmount.toStringAsFixed(2)} for this category';
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[50] ?? Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Add New Expense',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Show warning if limit would be exceeded
                if (wouldExceedLimit)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[50] ?? Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200] ?? Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: This expense would exceed your budget limit of ₱${expenseProvider.budgetLimit.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.red[700] ?? Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show warning if category limit would be exceeded
                if (wouldExceedCategoryLimit)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50] ?? Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200] ?? Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: This expense would exceed your category limit',
                            style: TextStyle(
                              color: Colors.orange[700] ?? Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show warning if max amount would be exceeded for recurring expense
                if (wouldExceedMaxAmount)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50] ?? Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200] ?? Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.purple, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            maxAmountMessage,
                            style: TextStyle(
                              color: Colors.purple[700] ?? Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show info if currently in a limit period
                if (isInLimitPeriod && expenseProvider.budgetLimit > 0)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.green[50] ?? Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200] ?? Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'BUDGET LIMIT ACTIVE',
                              style: TextStyle(
                                color: Colors.green[700] ?? Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          expenseProvider.limitEndDate != null
                              ? 'Valid until: ${DateFormat('MMM dd, yyyy').format(expenseProvider.limitEndDate!)}'
                              : 'Budget limit is active',
                          style: TextStyle(
                            color: Colors.green[800] ?? Colors.green.shade800,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: totalSpentInPeriod / expenseProvider.budgetLimit,
                          backgroundColor: Colors.green[100] ?? Colors.green.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Spent: ₱${totalSpentInPeriod.toStringAsFixed(2)} of ₱${expenseProvider.budgetLimit.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[800] ?? Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Basic Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPENSE DETAILS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600] ?? Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            labelStyle: TextStyle(
                              color: Colors.grey[700] ?? Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            prefixIcon: Icon(Icons.attach_money,
                                color: Colors.grey[600] ?? Colors.grey.shade600, size: 20),
                            prefixText: '₱ ',
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(
                              color: Colors.grey[700] ?? Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            prefixIcon: Icon(Icons.category,
                                color: Colors.grey[600] ?? Colors.grey.shade600, size: 20),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Select a category',
                                  style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ),
                            ...categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(category.name, style: TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              // Update max amount field when category changes
                              if (value != null) {
                                final maxAmount = expenseProvider.getCategoryMaxAmount(value);
                                if (maxAmount > 0) {
                                  _maxAmountController.text = maxAmount.toStringAsFixed(2);
                                } else {
                                  _maxAmountController.clear();
                                }
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _monthlySalaryController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Monthly Salary',
                            labelStyle: TextStyle(
                              color: Colors.grey[700] ?? Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.green),
                            ),
                            prefixIcon: Icon(Icons.account_balance_wallet,
                                color: Colors.grey[600] ?? Colors.grey.shade600, size: 20),
                            prefixText: '₱ ',
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your monthly salary';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50] ?? Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Icon(Icons.calendar_today, color: Colors.green, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Recurring Expense Card - Always visible
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECURRING EXPENSE SETTINGS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600] ?? Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(
                                _isRecurring ? Icons.toggle_on : Icons.toggle_off,
                                color: _isRecurring ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'This is a recurring expense',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          value: _isRecurring,
                          onChanged: (value) {
                            setState(() {
                              _isRecurring = value;
                              if (!value) {
                                _maxAmountController.clear();
                              }
                            });
                          },
                        ),
                        if (_isRecurring) ...[
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: _dueDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _dueDate = pickedDate;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50] ?? Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dueDate != null
                                        ? 'Due Date: ${DateFormat('MMM dd, yyyy').format(_dueDate!)}'
                                        : 'Set Due Date',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Icon(Icons.calendar_today, color: Colors.green, size: 20),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Maximum Amount to Spend',
                              labelStyle: TextStyle(
                                color: Colors.grey[700] ?? Colors.grey.shade700,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50] ?? Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.green),
                              ),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: Colors.grey[600] ?? Colors.grey.shade600, size: 20),
                              prefixText: '₱ ',
                              hintText: 'Set maximum limit for this expense',
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            onChanged: (value) {
                              // Save max amount to provider when user changes it
                              if (_selectedCategory != null && value.isNotEmpty) {
                                final maxAmount = double.tryParse(value) ?? 0;
                                if (maxAmount > 0) {
                                  expenseProvider.setCategoryMaxAmount(_selectedCategory!, maxAmount);
                                }
                              }
                            },
                            validator: _isRecurring ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please set a maximum amount for recurring expenses';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            } : null,
                          ),
                          if (_selectedCategory != null && _recurringExpenseTotals.containsKey(_selectedCategory))
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Already spent: ₱${_recurringExpenseTotals[_selectedCategory]!.toStringAsFixed(2)} of ₱${_maxAmountController.text.isEmpty ? "0.00" : _maxAmountController.text}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24), // Increased spacing for better visual separation

                // Enhanced Add Expense Button
                Container(
                  width: double.infinity,
                  height: 56, // Increased height for better visibility
                  child: ElevatedButton(
                    onPressed: wouldExceedLimit || wouldExceedCategoryLimit || wouldExceedMaxAmount ? null : () {
                      if (_formKey.currentState!.validate()) {
                        // Check if recurring expense exceeds maximum amount
                        if (_isRecurring && _selectedCategory != null) {
                          final maxAmount = expenseProvider.getCategoryMaxAmount(_selectedCategory!);
                          if (maxAmount > 0) {
                            final expenseAmount = double.parse(_amountController.text);
                            final currentTotal = _recurringExpenseTotals[_selectedCategory!] ?? 0;

                            if ((currentTotal + expenseAmount) > maxAmount) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: This would exceed the maximum amount of ₱${maxAmount.toStringAsFixed(2)} for this category'),
                                  backgroundColor: Colors.purple,
                                ),
                              );
                              return;
                            }
                          }
                        }

                        final newExpense = ExpenseItem(
                          name: _selectedCategory ?? 'Uncategorized',
                          amount: double.parse(_amountController.text),
                          date: _selectedDate,
                          category: _selectedCategory ?? 'Uncategorized',
                          isRecurring: _isRecurring,
                          dueDate: _dueDate,
                        );

                        try {
                          expenseProvider.addExpense(newExpense);

                          // Update monthly salary
                          if (_monthlySalaryController.text.isNotEmpty) {
                            expenseProvider.monthlySalary = double.parse(_monthlySalaryController.text);
                          }

                          // Show success message for max amount reached
                          if (_isRecurring && _selectedCategory != null) {
                            final maxAmount = expenseProvider.getCategoryMaxAmount(_selectedCategory!);
                            if (maxAmount > 0) {
                              final newTotal = (_recurringExpenseTotals[_selectedCategory!] ?? 0) + newExpense.amount;

                              if (newTotal >= maxAmount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('You have reached the maximum amount of ₱${maxAmount.toStringAsFixed(2)} for ${_selectedCategory!}'),
                                    backgroundColor: Colors.purple,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: wouldExceedLimit || wouldExceedCategoryLimit || wouldExceedMaxAmount
                          ? Colors.grey
                          : Colors.green[700], // Darker green for better contrast
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Colors.green.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 22,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 18, // Slightly larger font
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthlySalaryController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }
}