import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/task.dart';

/// Servicio para interactuar con la API REST
class ApiService {
  final String baseUrl;
  final http.Client client;
  final Duration timeout;

  ApiService({
    this.baseUrl = 'http://localhost:3000',
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : client = client ?? http.Client();

  /// Headers comunes para las peticiones
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Maneja errores HTTP y lanza excepciones descriptivas
  void _handleError(http.Response response) {
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw ApiException(
        'Error del cliente: ${response.statusCode}',
        response.statusCode,
      );
    } else if (response.statusCode >= 500) {
      throw ApiException(
        'Error del servidor: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  /// Obtiene todas las tareas
  Future<List<Task>> getTasks() async {
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/tasks'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Task.fromJson(json)).toList();
      } else {
        _handleError(response);
        return [];
      }
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}', 0);
    } on Exception catch (e) {
      throw ApiException('Error inesperado: $e', 0);
    }
  }

  /// Obtiene una tarea por su ID
  Future<Task> getTaskById(String id) async {
    try {
      final response = await client
          .get(
            Uri.parse('$baseUrl/tasks/$id'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else {
        _handleError(response);
        throw ApiException('Tarea no encontrada', response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}', 0);
    } on Exception catch (e) {
      throw ApiException('Error inesperado: $e', 0);
    }
  }

  /// Crea una nueva tarea
  Future<Task> createTask(Task task, {String? idempotencyKey}) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (idempotencyKey != null) {
        headers['Idempotency-Key'] = idempotencyKey;
      }

      final response = await client
          .post(
            Uri.parse('$baseUrl/tasks'),
            headers: headers,
            body: json.encode(task.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Task.fromJson(json.decode(response.body));
      } else {
        _handleError(response);
        throw ApiException('Error al crear la tarea', response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}', 0);
    } on Exception catch (e) {
      throw ApiException('Error inesperado: $e', 0);
    }
  }

  /// Actualiza una tarea
  Future<Task> updateTask(Task task, {String? idempotencyKey}) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (idempotencyKey != null) {
        headers['Idempotency-Key'] = idempotencyKey;
      }

      final response = await client
          .put(
            Uri.parse('$baseUrl/tasks/${task.id}'),
            headers: headers,
            body: json.encode(task.toJson()),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      } else {
        _handleError(response);
        throw ApiException('Error al actualizar la tarea', response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}', 0);
    } on Exception catch (e) {
      throw ApiException('Error inesperado: $e', 0);
    }
  }

  /// Elimina una tarea
  Future<void> deleteTask(String id, {String? idempotencyKey}) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (idempotencyKey != null) {
        headers['Idempotency-Key'] = idempotencyKey;
      }

      final response = await client
          .delete(
            Uri.parse('$baseUrl/tasks/$id'),
            headers: headers,
          )
          .timeout(timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        _handleError(response);
        throw ApiException('Error al eliminar la tarea', response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}', 0);
    } on Exception catch (e) {
      throw ApiException('Error inesperado: $e', 0);
    }
  }
}

/// Excepción personalizada para errores de API
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

