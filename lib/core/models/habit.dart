class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final int targetCount;
  final String color;
  final String icon;
  final bool isArchived;
  final List<String> activeMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.frequency = 'daily',
    this.targetCount = 30,
    this.color = '#ff6b35',
    this.icon = '✓',
    this.isArchived = false,
    this.activeMonths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      frequency: json['frequency'] as String? ?? 'daily',
      targetCount: json['target_count'] as int? ?? 30,
      color: json['color'] as String? ?? '#ff6b35',
      icon: json['icon'] as String? ?? '✓',
      isArchived: json['is_archived'] as bool? ?? false,
      activeMonths: json['active_months'] != null
          ? List<String>.from(json['active_months'] as List)
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'target_count': targetCount,
      'color': color,
      'icon': icon,
      'is_archived': isArchived,
      'active_months': activeMonths,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? frequency,
    int? targetCount,
    String? color,
    String? icon,
    bool? isArchived,
    List<String>? activeMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      targetCount: targetCount ?? this.targetCount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isArchived: isArchived ?? this.isArchived,
      activeMonths: activeMonths ?? this.activeMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if habit is active in a specific month
  bool isActiveInMonth(DateTime month) {
    if (activeMonths.isEmpty) return true; // Active in all months if not specified
    
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return activeMonths.contains(monthKey);
  }

  @override
  String toString() {
    return 'Habit(id: $id, name: $name, activeMonths: $activeMonths)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
