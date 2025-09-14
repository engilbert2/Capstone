import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/category_item.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _categoryController = TextEditingController();
  int _currentIndex = 3; // Category tab is selected (4th position)
  bool _commonCategoriesAdded = false;

  // Map of common categories with their icons
  final Map<String, IconData> _commonCategories = {
    'Internet': Icons.wifi,
    'Clothing': Icons.shopping_bag,
    'Foods': Icons.restaurant,
    'Electricity': Icons.bolt,
    'Water Bills': Icons.water_drop,
    'Pet Food': Icons.pets,
    'Rental': Icons.home,
    'Transportation': Icons.directions_car,
    'Health': Icons.local_hospital,
    'Shopping': Icons.shopping_cart,
  };

  @override
  void initState() {
    super.initState();
    // Add common categories when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addCommonCategories();
    });
  }

  void _addCommonCategories() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    // Check if we've already added the common categories
    if (_commonCategoriesAdded) return;

    // Check if any common categories are already present
    bool hasCommonCategories = expenseProvider.categories.any((category) =>
        _commonCategories.containsKey(category.name));

    if (!hasCommonCategories) {
      // Add all common categories
      _commonCategories.forEach((name, icon) {
        // Check if this specific category already exists
        bool categoryExists = expenseProvider.categories.any(
                (category) => category.name.toLowerCase() == name.toLowerCase());

        if (!categoryExists) {
          final newCategory = CategoryItem(
            name: name,
            limit: 0,
            icon: '💰', // Default emoji as fallback
            iconCodePoint: icon.codePoint,
          );
          expenseProvider.addCategory(newCategory);
        }
      });

      setState(() {
        _commonCategoriesAdded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categories = expenseProvider.categories;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Categories',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add new category section
              Container(
                padding: const EdgeInsets.all(16.0),
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
                  children: [
                    Text(
                      'ADD NEW CATEGORY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.green),
                        ),
                        prefixIcon: Icon(Icons.category, color: Colors.green),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_categoryController.text.isNotEmpty) {
                          // Auto-select icon based on category name or use default
                          IconData selectedIcon = Icons.category; // Default icon

                          // Try to find a matching icon for the category name
                          _commonCategories.forEach((name, icon) {
                            if (_categoryController.text.toLowerCase().contains(name.toLowerCase())) {
                              selectedIcon = icon;
                            }
                          });

                          final newCategory = CategoryItem(
                            name: _categoryController.text,
                            limit: 0,
                            icon: '💰',
                            iconCodePoint: selectedIcon.codePoint,
                          );

                          expenseProvider.addCategory(newCategory);
                          _categoryController.clear();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Category added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Add Category',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Categories list header
              Text(
                'Your Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              // Categories list
              Expanded(
                child: categories.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No categories yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first category to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];

                    // Use Material icon if available, otherwise fall back to emoji
                    Widget iconWidget;
                    if (category.iconCodePoint != null) {
                      iconWidget = Icon(
                        IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons'),
                        color: Colors.green,
                      );
                    } else {
                      iconWidget = Text(
                        category.icon,
                        style: TextStyle(fontSize: 20),
                      );
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(child: iconWidget),
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: _commonCategories.containsKey(category.name)
                            ? SizedBox(width: 40)
                            : IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteDialog(context, expenseProvider, index);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation bar matching your HomeScreen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
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
            // Already on category screen
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
          // This is the plus button in the middle
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 32, color: Colors.green),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category, color: Colors.blue),
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

  void _showDeleteDialog(
      BuildContext context, ExpenseProvider provider, int index) {
    final category = provider.categories[index];

    // Don't allow deletion of common categories
    if (_commonCategories.containsKey(category.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Common categories cannot be deleted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Category',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text('Are you sure you want to delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                provider.deleteCategory(index);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}