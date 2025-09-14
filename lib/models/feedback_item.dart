import 'package:hive/hive.dart';

part 'feedback_item.g.dart';

@HiveType(typeId: 3)
class FeedbackItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String userName;

  @HiveField(3)
  final String message;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isRead;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  static FeedbackItem fromMap(Map<String, dynamic> map) {
    return FeedbackItem(
      id: map['id'],
      userId: map['userId'],
      userName: map['userName'],
      message: map['message'],
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }
}