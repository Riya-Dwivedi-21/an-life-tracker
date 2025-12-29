class HabitLog {
  final String id;
  final String userId;
  final String habitId;
  final DateTime date;
  final bool completed;
  final int count;
  final String? notes;
  final DateTime createdAt;

  HabitLog({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    this.completed = false,
    this.count = 0,
    this.notes,
    required this.createdAt,
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      habitId: json['habit_id'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'date': date.toIso8601String().split('T')[0], // Date only (YYYY-MM-DD)
      'completed': completed,
      'count': count,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HabitLog copyWith({
    String? id,
    String? userId,
    String? habitId,
    DateTime? date,
    bool? completed,
    int? count,
    String? notes,
    DateTime? createdAt,
  }) {
    return HabitLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completed: completed ?? this.completed,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get date key in format YYYY-MM-DD
  String get dateKey => date.toIso8601String().split('T')[0];

  @override
  String toString() {
    return 'HabitLog(id: $id, habitId: $habitId, date: $dateKey, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
