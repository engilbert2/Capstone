// user.dart - Updated for MongoDB
class User {
  final String? id; // MongoDB ObjectId
  final String username;
  final String firstName;
  String password;
  final String securityQuestion;
  final String securityAnswer;

  User({
    this.id,
    required this.username,
    required this.firstName,
    required this.password,
    required this.securityQuestion,
    required this.securityAnswer,
  });

  // Convert from MongoDB document to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      username: json['username'],
      firstName: json['firstName'],
      password: json['password'],
      securityQuestion: json['securityQuestion'],
      securityAnswer: json['securityAnswer'],
    );
  }

  // Convert User object to MongoDB document
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'firstName': firstName,
      'password': password,
      'securityQuestion': securityQuestion,
      'securityAnswer': securityAnswer,
    };

    // Only include _id if it exists (for updates)
    if (id != null) {
      data['_id'] = id;
    }

    return data;
  }

  // Update password method
  set updatePassword(String newPassword) {
    password = newPassword;
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, firstName: $firstName)';
  }
}