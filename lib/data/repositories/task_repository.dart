import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/task.dart';
import '../../models/queue_operation.dart';
import '../local/database_helper.dart';
import '../remote/api_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Repositorio que implementa la estrategia offline-first
class TaskRepository {
  final DatabaseHelper _dbHelper;
  final ApiService _apiService;
  final ConnectivityService _connectivityService;
  final SyncService _syncService;

  TaskRepository({
    required DatabaseHelper dbHelper,
    required ApiService apiService,
    required ConnectivityService connectivityService,
    required SyncService syncService,
  })  : _dbHelper = dbHelper,
        _apiService = apiService,
        _connectivityService = connectivityService,
        _syncService = syncService;

  /// Obtiene todas las tareas (offline-first: muestra datos locales primero)
  Future<List<Task>> getTasks({bool? completed}) async {
    // Siempre devolver datos locales primero
    final localTasks = await _dbHelper.getAllTasks(completed: completed);

    // Si hay conexión, sincronizar en segundo plano
    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      _syncInBackground();
    }

    return localTasks;
  }

  /// Sincroniza en segundo plano sin bloquear la UI
  Future<void> _syncInBackground() async {
    try {
      // Obtener tareas del servidor
      final remoteTasks = await _apiService.getTasks();

      // Aplicar estrategia Last-Write-Wins
      for (final remoteTask in remoteTasks) {
        final localTask = await _dbHelper.getTaskById(remoteTask.id);
        if (localTask == null) {
          // Nueva tarea del servidor
          await _dbHelper.insertTask(remoteTask);
        } else if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          // El servidor tiene una versión más reciente
          await _dbHelper.insertTask(remoteTask);
        }
      }

      // Procesar cola de operaciones pendientes
      await _syncService.syncPendingOperations();
    } catch (e) {
      // Silenciar errores en sincronización en segundo plano
      // Los datos locales ya están disponibles
      debugPrint('Error en sincronización en segundo plano: $e');
    }
  }

  /// Obtiene una tarea por su ID
  Future<Task?> getTaskById(String id) async {
    return await _dbHelper.getTaskById(id);
  }

  /// Crea una nueva tarea (offline-first: guarda localmente y encola)
  Future<Task> createTask(String title) async {
    final now = DateTime.now();
    final task = Task(
      id: const Uuid().v4(),
      title: title,
      completed: false,
      updatedAt: now,
    );

    // Guardar localmente primero (actualización optimista)
    await _dbHelper.insertTask(task);

    // Encolar operación para sincronizar
    final operation = QueueOperation(
      id: const Uuid().v4(),
      entity: 'task',
      entityId: task.id,
      op: 'CREATE',
      payload: json.encode(task.toJson()),
      createdAt: now,
    );
    await _dbHelper.insertQueueOperation(operation);

    // Sincronizar en segundo plano sin bloquear (fire and forget)
    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      _syncCreateInBackground(task, operation);
    }

    // Retornar inmediatamente con el estado local
    return task;
  }

  /// Sincroniza una creación en segundo plano
  Future<void> _syncCreateInBackground(Task task, QueueOperation operation) async {
    try {
      final syncedTask = await _apiService.createTask(
        task,
        idempotencyKey: operation.id,
      );
      // Actualizar con la respuesta del servidor (silenciosamente)
      await _dbHelper.insertTask(syncedTask);
      await _dbHelper.deleteQueueOperation(operation.id);
    } catch (e) {
      // Si falla, la operación queda en cola para más tarde
      debugPrint('Error al sincronizar creación: $e');
    }
  }

  /// Actualiza una tarea (offline-first: guarda localmente y encola)
  Future<Task> updateTask(Task task) async {
    final updatedTask = task.copyWith(updatedAt: DateTime.now());

    // Actualizar localmente primero (actualización optimista)
    await _dbHelper.updateTask(updatedTask);

    // Encolar operación para sincronizar
    final operation = QueueOperation(
      id: const Uuid().v4(),
      entity: 'task',
      entityId: task.id,
      op: 'UPDATE',
      payload: json.encode(updatedTask.toJson()),
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertQueueOperation(operation);

    // Sincronizar en segundo plano sin bloquear (fire and forget)
    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      _syncUpdateInBackground(updatedTask, operation);
    }

    // Retornar inmediatamente con el estado local actualizado
    return updatedTask;
  }

  /// Sincroniza una actualización en segundo plano
  Future<void> _syncUpdateInBackground(Task task, QueueOperation operation) async {
    try {
      final syncedTask = await _apiService.updateTask(
        task,
        idempotencyKey: operation.id,
      );
      // Actualizar con la respuesta del servidor (silenciosamente)
      await _dbHelper.insertTask(syncedTask);
      await _dbHelper.deleteQueueOperation(operation.id);
    } catch (e) {
      // Si falla, la operación queda en cola para más tarde
      debugPrint('Error al sincronizar actualización: $e');
    }
  }

  /// Marca una tarea como completada
  Future<Task> toggleTaskCompletion(Task task) async {
    return await updateTask(task.copyWith(completed: !task.completed));
  }

  /// Elimina una tarea (offline-first: marca como eliminada localmente y encola)
  Future<void> deleteTask(String id) async {
    // Marcar como eliminada localmente (soft delete) - actualización optimista
    await _dbHelper.deleteTask(id);

    // Encolar operación para sincronizar
    final operation = QueueOperation(
      id: const Uuid().v4(),
      entity: 'task',
      entityId: id,
      op: 'DELETE',
      payload: json.encode({'id': id}),
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertQueueOperation(operation);

    // Sincronizar en segundo plano sin bloquear (fire and forget)
    final isConnected = await _connectivityService.isConnected();
    if (isConnected) {
      _syncDeleteInBackground(id, operation);
    }
  }

  /// Sincroniza una eliminación en segundo plano
  Future<void> _syncDeleteInBackground(String id, QueueOperation operation) async {
    try {
      await _apiService.deleteTask(id, idempotencyKey: operation.id);
      await _dbHelper.deleteQueueOperation(operation.id);
    } catch (e) {
      // Si falla, la operación queda en cola para más tarde
      debugPrint('Error al sincronizar eliminación: $e');
    }
  }

  /// Fuerza una sincronización completa
  Future<void> forceSync() async {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      throw Exception('No hay conexión a internet');
    }

    await _syncInBackground();
    await _syncService.syncPendingOperations();
  }
}

