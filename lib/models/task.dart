/// Modelo de datos para una tarea
class Task {
  final String id;
  final String title;
  final bool completed;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.updatedAt,
  });

  /// Crea una tarea desde un mapa JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convierte la tarea a un mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crea una copia de la tarea con campos opcionales modificados
  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.completed == completed &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        completed.hashCode ^
        updatedAt.hashCode;
  }
}

