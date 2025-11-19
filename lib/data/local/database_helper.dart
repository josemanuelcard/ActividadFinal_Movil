import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/task.dart';
import '../../models/queue_operation.dart';

/// Helper para gestionar la base de datos SQLite local
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Obtiene la instancia de la base de datos (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('tasks.db');
      return _database!;
    } catch (e) {
      throw Exception('Error al obtener la base de datos: $e');
    }
  }

  /// Inicializa la base de datos y crea las tablas
  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e) {
      throw Exception('Error al inicializar la base de datos: $e');
    }
  }

  /// Crea las tablas necesarias
  Future<void> _createDB(Database db, int version) async {
    // Tabla de tareas
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de operaciones en cola
    await db.execute('''
      CREATE TABLE queue_operations (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('CREATE INDEX idx_tasks_deleted ON tasks(deleted)');
    await db.execute('CREATE INDEX idx_queue_operations_entity ON queue_operations(entity, entity_id)');
  }

  // ==================== OPERACIONES DE TAREAS ====================

  /// Inserta una tarea en la base de datos local
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      {
        'id': task.id,
        'title': task.title,
        'completed': task.completed ? 1 : 0,
        'updated_at': task.updatedAt.toIso8601String(),
        'deleted': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las tareas (excluyendo las eliminadas)
  Future<List<Task>> getAllTasks({bool? completed}) async {
    final db = await database;
    String query = 'SELECT * FROM tasks WHERE deleted = 0';
    
    if (completed != null) {
      query += ' AND completed = ${completed ? 1 : 0}';
    }
    
    query += ' ORDER BY updated_at DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (i) => _taskFromMap(maps[i]));
  }

  /// Obtiene una tarea por su ID
  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _taskFromMap(maps.first);
  }

  /// Actualiza una tarea
  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      {
        'title': task.title,
        'completed': task.completed ? 1 : 0,
        'updated_at': task.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Marca una tarea como eliminada (soft delete)
  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.update(
      'tasks',
      {'deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Convierte un mapa de la base de datos a un objeto Task
  Task _taskFromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // ==================== OPERACIONES DE COLA ====================

  /// Inserta una operación en la cola
  Future<void> insertQueueOperation(QueueOperation operation) async {
    final db = await database;
    await db.insert(
      'queue_operations',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las operaciones pendientes
  Future<List<QueueOperation>> getPendingOperations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'queue_operations',
      orderBy: 'created_at ASC',
    );

    return List.generate(
      maps.length,
      (i) => QueueOperation.fromMap(maps[i]),
    );
  }

  /// Elimina una operación de la cola (después de sincronizar exitosamente)
  Future<void> deleteQueueOperation(String id) async {
    final db = await database;
    await db.delete(
      'queue_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza el contador de intentos y el último error
  Future<void> updateQueueOperation(
    String id,
    int attemptCount,
    String? lastError,
  ) async {
    final db = await database;
    await db.update(
      'queue_operations',
      {
        'attempt_count': attemptCount,
        'last_error': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

