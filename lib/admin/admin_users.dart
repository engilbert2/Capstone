import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Arko/services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  @override
  _AdminUsersScreenState createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await ApiService.getUsers(); // Replace with your API
      setState(() {
        _users = users.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _archiveUser(String userId, String username) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Archive User'),
        content: Text('Are you sure you want to archive $username?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ApiService.archiveUser(userId); // Implement in ApiService
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User archived')));
          _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to archive user')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _unarchiveUser(String userId, String username) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unarchive User'),
        content: Text('Are you sure you want to unarchive $username?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Unarchive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ApiService.unarchiveUser(userId); // Implement in ApiService
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User unarchived')));
          _loadUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unarchive user')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredUsers = _users.where((user) {
      bool isArchived = user['isArchived'] == true;
      if (_statusFilter == 'active') return !isArchived;
      if (_statusFilter == 'archived') return isArchived;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _loadUsers(); // Consider filtering locally for speed
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _roleFilter,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text('All Roles')),
                        DropdownMenuItem(value: 'user', child: Text('Users')),
                        DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      ],
                      onChanged: (value) {
                        setState(() => _roleFilter = value!);
                        _loadUsers();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Active'),
                      selected: _statusFilter == 'active',
                      onSelected: (selected) => setState(() => _statusFilter = 'active'),
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Archived'),
                      selected: _statusFilter == 'archived',
                      onSelected: (selected) => setState(() => _statusFilter = 'archived'),
                    ),
                    SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('All'),
                      selected: _statusFilter == 'all',
                      onSelected: (selected) => setState(() => _statusFilter = 'all'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                bool isArchived = user['isArchived'] == true;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: isArchived ? Colors.grey[200] : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text((user['first_name'] ?? user['firstName'] ?? 'U')[0]),
                      backgroundColor: isArchived ? Colors.grey : null,
                    ),
                    title: Text(
                      '${user['first_name'] ?? user['firstName'] ?? ''} ${user['last_name'] ?? user['lastName'] ?? ''}',
                      style: TextStyle(color: isArchived ? Colors.grey : null),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${user['username']}'),
                        Text('Role: ${user['role']}', style: TextStyle(fontSize: 12)),
                        if (isArchived)
                          Text(
                            'Archived',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        if (!isArchived) PopupMenuItem(child: Text('Archive User'), value: 'archive'),
                        if (isArchived) PopupMenuItem(child: Text('Unarchive User'), value: 'unarchive'),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'archive':
                            _archiveUser(user['id'].toString(), user['username']);
                            break;
                          case 'unarchive':
                            _unarchiveUser(user['id'].toString(), user['username']);
                            break;
                        }
                      },
                    ),
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