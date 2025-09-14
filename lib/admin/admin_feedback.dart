import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Arko/services/api_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  @override
  _AdminFeedbackScreenState createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<dynamic> _feedbackMessages = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false; // not yet implemented in PHP API

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    try {
      final feedback = await ApiService.getFeedback();
      setState(() {
        _feedbackMessages = feedback;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feedback: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFeedback(String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Feedback'),
        content: Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ApiService.deleteFeedback(id);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Feedback deleted')),
          );
          _loadFeedback();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      DateTime date = DateTime.parse(dateValue.toString());
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDateShort(dynamic dateValue) {
    try {
      DateTime date = DateTime.parse(dateValue.toString());
      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Feedback Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('From', feedback['userName']),
                _buildDetailRow('Date', _formatDate(feedback['createdAt'])),
                SizedBox(height: 16),
                Text(
                  'Message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  feedback['message'],
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Feedback'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Chip(
                  label: Text('Total: ${_feedbackMessages.length}'),
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),
          ),

          // Feedback list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _feedbackMessages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No feedback messages',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _feedbackMessages.length,
              itemBuilder: (context, index) {
                final feedback = _feedbackMessages[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(feedback['userName'][0]),
                      backgroundColor: Colors.green,
                    ),
                    title: Text(
                      feedback['userName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      feedback['message'].length > 50
                          ? '${feedback['message'].substring(0, 50)}...'
                          : feedback['message'],
                    ),
                    trailing: Text(
                      _formatDateShort(feedback['createdAt']),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    onTap: () => _showFeedbackDetails(feedback),
                    onLongPress: () => _deleteFeedback(feedback['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
