// lib/models/todo_model.dart

class Todo {
  final int id;
  final int userId;
  final String title;
  final String description;
  final DateTime reminderAt;
  final bool isDone;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.reminderAt,
    required this.isDone,
    required this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        userId: (json['user_id'] is num) ? (json['user_id'] as num).toInt() : 0,
        title: json['title'],
        description: json['description'] ?? '',
        reminderAt: DateTime.parse(json['reminder_at']),
        isDone: json['is_done'] == 1 || json['is_done'] == true,
        createdAt: DateTime.parse(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'reminder_at': reminderAt.toString().substring(0, 19),
      };
}
