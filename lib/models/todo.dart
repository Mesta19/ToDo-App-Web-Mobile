// lib/models/todo.dart

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

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id:          json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId:      json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      title:       json['title'] ?? '',
      description: json['description'] ?? '',
      reminderAt:  DateTime.parse(json['reminder_at']),
      isDone:      json['is_done'].toString() == '1',
      createdAt:   DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'user_id':     userId,
    'title':       title,
    'description': description,
    'reminder_at': reminderAt.toString().substring(0, 19),
    'is_done':     isDone ? 1 : 0,
  };

  // Apakah waktu pengingat sudah lewat?
  bool get isExpired => reminderAt.isBefore(DateTime.now());

  // Sisa waktu dalam format ramah baca
  String get timeLeft {
    if (isExpired) return 'Sudah lewat';
    final diff = reminderAt.difference(DateTime.now());
    if (diff.inDays > 0)    return '${diff.inDays} hari lagi';
    if (diff.inHours > 0)   return '${diff.inHours} jam lagi';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lagi';
    return 'Sebentar lagi';
  }
}
