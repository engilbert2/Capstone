import 'package:flutter/material.dart';
import 'package:Arko/services/auth_service.dart';
import 'dart:async'; // For Timer

// Simple debouncer class
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedSecurityQuestion;

  // Enhanced username validation variables
  bool _checkingUsername = false;
  bool _usernameAvailable = false;
  String _usernameMessage = '';
  bool _hasCheckedUsername = false; // Track if we've checked at least once
  final Debouncer _usernameDebouncer = Debouncer(delay: const Duration(milliseconds: 600));

  // Track username field focus
  bool _usernameFieldFocused = false;

  // Username suggestions
  List<String> _usernameSuggestions = [];
  bool _showSuggestions = false;

  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();

  // Focus nodes
  final FocusNode _usernameFocusNode = FocusNode();

  final List<String> _securityQuestions = [
    'In what town was your first job?',
    'What is your mother\'s maiden name?',
    'What was the name of your first pet?',
    'What elementary school did you attend?',
    'What is the name of your favorite teacher?',
  ];

  @override
  void initState() {
    super.initState();

    // Set up username focus listener
    _usernameFocusNode.addListener(() {
      setState(() {
        _usernameFieldFocused = _usernameFocusNode.hasFocus;
        _showSuggestions = _usernameFieldFocused && _usernameSuggestions.isNotEmpty;
      });
    });

    // Listen to username changes
    _usernameController.addListener(() {
      final username = _usernameController.text.trim();

      setState(() {
        _hasCheckedUsername = false;
        _showSuggestions = _usernameFieldFocused && _usernameSuggestions.isNotEmpty;
      });

      if (username.length >= 3) {
        _usernameDebouncer.call(() {
          _checkUsernameAvailability(username);
        });
      } else if (username.isNotEmpty && username.length < 3) {
        setState(() {
          _usernameMessage = 'Username must be at least 3 characters';
          _usernameAvailable = false;
          _checkingUsername = false;
          _hasCheckedUsername = false;
        });
      } else {
        setState(() {
          _usernameMessage = '';
          _usernameAvailable = false;
          _checkingUsername = false;
          _hasCheckedUsername = false;
        });
      }
    });

    // Listen to name changes to generate suggestions
    _firstNameController.addListener(_generateUsernameSuggestions);
    _lastNameController.addListener(_generateUsernameSuggestions);
  }

  // Generate username suggestions
  void _generateUsernameSuggestions() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      setState(() {
        _usernameSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    List<String> suggestions = [];

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      suggestions.add('${firstName.toLowerCase()}${lastName.toLowerCase()}');
      suggestions.add('${firstName.toLowerCase()}.${lastName.toLowerCase()}');
      suggestions.add('${firstName.toLowerCase()}_${lastName.toLowerCase()}');
      suggestions.add('${firstName[0].toLowerCase()}${lastName.toLowerCase()}');
      suggestions.add('${firstName.toLowerCase()}${lastName[0].toLowerCase()}');
    }

    if (firstName.isNotEmpty) {
      suggestions.add(firstName.toLowerCase());
      suggestions.add('${firstName.toLowerCase()}123');
      suggestions.add('${firstName.toLowerCase()}${DateTime.now().year % 100}');
    }

    if (lastName.isNotEmpty) {
      suggestions.add(lastName.toLowerCase());
      suggestions.add('${lastName.toLowerCase()}${DateTime.now().year % 100}');
    }

    suggestions = suggestions.take(6).toList();

    setState(() {
      _usernameSuggestions = suggestions;
      _showSuggestions = _usernameFieldFocused && suggestions.isNotEmpty;
    });
  }

  void _applySuggestion(String suggestion) {
    _usernameController.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    if (_formKey.currentState != null) _formKey.currentState!.validate();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) return;

    setState(() {
      _checkingUsername = true;
      _usernameMessage = 'Checking availability...';
    });

    try {
      final result = await _authService.checkUsernameAvailability(username);

      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _checkingUsername = false;
          _hasCheckedUsername = true;
          _usernameAvailable = result['available'] ?? false;
          _usernameMessage = _usernameAvailable ? 'Username is available' : 'Username already exists';
        });
      }
    } catch (e) {
      if (mounted && _usernameController.text.trim() == username) {
        setState(() {
          _checkingUsername = false;
          _hasCheckedUsername = true;
          _usernameAvailable = false;
          _usernameMessage = 'Error checking username availability';
        });
      }
    }
  }

  String? _usernameValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter a username';
    if (value.trim().length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  Future<void> _handleSignUp() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();

    if (username.isNotEmpty && (!_hasCheckedUsername || !_usernameAvailable)) {
      await _checkUsernameAvailability(username);
      if (!_usernameAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username "$username" is already taken. Please choose another username.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUpUser(
        username: username,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
        securityQuestion: _selectedSecurityQuestion,
        securityAnswer: _securityAnswerController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: constraints.maxWidth > 500 ? 500 : constraints.maxWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your first name' : null,
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your last name' : null,
                    ),

                    const SizedBox(height: 16),

                    // Username Field (with suggestions)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade400),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _hasCheckedUsername && !_usernameAvailable
                                    ? Colors.red
                                    : Colors.grey.shade400,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _hasCheckedUsername && !_usernameAvailable
                                    ? Colors.red
                                    : Colors.teal,
                                width: 2,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            suffixIcon: _checkingUsername
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                                ),
                              ),
                            )
                                : _hasCheckedUsername && _usernameController.text.isNotEmpty
                                ? Icon(
                              _usernameAvailable ? Icons.check_circle : Icons.error,
                              color: _usernameAvailable ? Colors.green : Colors.red,
                            )
                                : null,
                          ),
                          validator: _usernameValidator,
                        ),

                        if (_showSuggestions && _usernameSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Suggestions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _usernameSuggestions.map((s) => GestureDetector(
                                    onTap: () => _applySuggestion(s),
                                    child: Chip(
                                      label: Text(s, style: const TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.teal[50],
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),

                        if (_usernameMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 12),
                            child: Row(
                              children: [
                                Icon(
                                  _checkingUsername
                                      ? Icons.hourglass_empty
                                      : _usernameAvailable
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline,
                                  size: 16,
                                  color: _checkingUsername
                                      ? Colors.grey
                                      : _usernameAvailable
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _usernameMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _checkingUsername
                                        ? Colors.grey
                                        : _usernameAvailable
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: _usernameAvailable ? FontWeight.normal : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Security Question
                    DropdownButtonFormField<String>(
                      value: _selectedSecurityQuestion,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Security Question',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.security),
                      ),
                      items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (value) => setState(() => _selectedSecurityQuestion = value),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please select a security question' : null,
                    ),

                    const SizedBox(height: 16),

                    // Security Answer
                    TextFormField(
                      controller: _securityAnswerController,
                      decoration: InputDecoration(
                        labelText: 'Security Answer',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(Icons.quiz),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter your security answer' : null,
                    ),

                    const SizedBox(height: 30),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: (_isLoading || (_hasCheckedUsername && !_usernameAvailable)) ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_hasCheckedUsername && !_usernameAvailable) ? Colors.grey : Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text((_hasCheckedUsername && !_usernameAvailable) ? 'Change Username' : 'Sign Up', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text('Already have an account? Sign In', style: TextStyle(color: Colors.teal[700])),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _usernameDebouncer.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _securityAnswerController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }
}
