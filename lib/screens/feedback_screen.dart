import 'package:flutter/material.dart';
import 'package:Arko/services/api_service.dart';
import 'package:Arko/services/auth_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isSubmitting = false;
  int _rating = 0;

  Future<void> _submitFeedback() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        final success = await ApiService.submitFeedback(
          currentUser['id'].toString(),
          '${currentUser['firstName']} ${currentUser['lastName']}',
          _messageController.text,
          rating: _rating > 0 ? _rating : null,
        );

        if (success) {
          _messageController.clear();
          setState(() => _rating = 0);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit feedback'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Feedback'),
        backgroundColor: Colors.green,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We\'d love to hear your feedback!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your suggestions help us improve the app.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Star rating section
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Rate your experience',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildStarRating(),
                    const SizedBox(height: 16),
                    Text(
                      _rating == 0 ? 'Tap stars to rate' : '$_rating ${_rating == 1 ? 'star' : 'stars'}',
                      style: TextStyle(
                        color: _rating == 0 ? Colors.grey : Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Feedback message section
              const Text(
                'Your feedback:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tell us what you think...',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Submit Feedback',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}