/// Modelo para operaciones en cola de sincronización
class QueueOperation {
  final String id;
  final String entity; // 'task'
  final String entityId;
  final String op; // 'CREATE' | 'UPDATE' | 'DELETE'
  final String payload; // JSON string
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;

  QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
  });

  /// Crea una operación desde un mapa de la base de datos
  factory QueueOperation.fromMap(Map<String, dynamic> map) {
    return QueueOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      op: map['op'] as String,
      payload: map['payload'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  /// Convierte la operación a un mapa para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': op,
      'payload': payload,
      'created_at': createdAt.millisecondsSinceEpoch,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  /// Crea una copia con campos opcionales modificados
  QueueOperation copyWith({
    String? id,
    String? entity,
    String? entityId,
    String? op,
    String? payload,
    DateTime? createdAt,
    int? attemptCount,
    String? lastError,
  }) {
    return QueueOperation(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  String toString() {
    return 'QueueOperation(id: $id, entity: $entity, entityId: $entityId, op: $op, attemptCount: $attemptCount)';
  }
}

