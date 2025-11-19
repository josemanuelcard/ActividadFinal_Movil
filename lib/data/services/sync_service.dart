import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/task.dart';
import '../../models/queue_operation.dart';
import '../local/database_helper.dart';
import '../remote/api_service.dart';

/// Servicio para sincronizar operaciones pendientes con el servidor
class SyncService {
  final DatabaseHelper _dbHelper;
  final ApiService _apiService;
  final int maxRetries = 5;

  SyncService({
    required DatabaseHelper dbHelper,
    required ApiService apiService,
  })  : _dbHelper = dbHelper,
        _apiService = apiService;

  /// Sincroniza todas las operaciones pendientes
  Future<void> syncPendingOperations() async {
    final operations = await _dbHelper.getPendingOperations();

    for (final operation in operations) {
        // Verificar si se ha excedido el número máximo de intentos
      if (operation.attemptCount >= maxRetries) {
        // Marcar como fallida permanentemente o notificar al usuario
        debugPrint('Operación ${operation.id} excedió el máximo de intentos');
        continue;
      }

      try {
        await _processOperation(operation);
        // Si tiene éxito, eliminar de la cola
        await _dbHelper.deleteQueueOperation(operation.id);
      } catch (e) {
        // Incrementar contador de intentos y guardar error
        final newAttemptCount = operation.attemptCount + 1;
        await _dbHelper.updateQueueOperation(
          operation.id,
          newAttemptCount,
          e.toString(),
        );
        debugPrint('Error al procesar operación ${operation.id}: $e');
      }

      // Backoff exponencial entre operaciones
      if (operation.attemptCount > 0) {
        final delay = min(
          pow(2, operation.attemptCount).toInt() * 1000,
          30000, // Máximo 30 segundos
        );
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  /// Procesa una operación individual
  Future<void> _processOperation(QueueOperation operation) async {
    switch (operation.op) {
      case 'CREATE':
        await _processCreate(operation);
        break;
      case 'UPDATE':
        await _processUpdate(operation);
        break;
      case 'DELETE':
        await _processDelete(operation);
        break;
      default:
        throw Exception('Operación desconocida: ${operation.op}');
    }
  }

  /// Procesa una operación CREATE
  Future<void> _processCreate(QueueOperation operation) async {
    final taskJson = json.decode(operation.payload) as Map<String, dynamic>;
    final task = Task.fromJson(taskJson);

    final syncedTask = await _apiService.createTask(
      task,
      idempotencyKey: operation.id,
    );

    // Actualizar con la respuesta del servidor
    await _dbHelper.insertTask(syncedTask);
  }

  /// Procesa una operación UPDATE
  Future<void> _processUpdate(QueueOperation operation) async {
    final taskJson = json.decode(operation.payload) as Map<String, dynamic>;
    final task = Task.fromJson(taskJson);

    final syncedTask = await _apiService.updateTask(
      task,
      idempotencyKey: operation.id,
    );

    // Actualizar con la respuesta del servidor
    await _dbHelper.insertTask(syncedTask);
  }

  /// Procesa una operación DELETE
  Future<void> _processDelete(QueueOperation operation) async {
    final payload = json.decode(operation.payload) as Map<String, dynamic>;
    final taskId = payload['id'] as String;

    await _apiService.deleteTask(
      taskId,
      idempotencyKey: operation.id,
    );
  }
}

