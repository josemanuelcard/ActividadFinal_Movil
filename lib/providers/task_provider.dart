import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/connectivity_service.dart';

/// Provider para gestionar el estado de las tareas
class TaskProvider with ChangeNotifier {
  final TaskRepository _repository;
  final ConnectivityService _connectivityService;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  TaskFilter _filter = TaskFilter.all;
  bool _isConnected = true;

  TaskProvider({
    required TaskRepository repository,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _connectivityService = connectivityService {
    _init();
  }

  /// Inicializa el provider y escucha cambios de conectividad
  Future<void> _init() async {
    await checkConnectivity();
    _connectivityService.onConnectivityChanged.listen((_) async {
      await checkConnectivity();
    });
    await loadTasks();
  }

  /// Lista de tareas filtradas
  List<Task> get tasks {
    switch (_filter) {
      case TaskFilter.all:
        return _tasks;
      case TaskFilter.pending:
        return _tasks.where((task) => !task.completed).toList();
      case TaskFilter.completed:
        return _tasks.where((task) => task.completed).toList();
    }
  }

  /// Todas las tareas sin filtrar
  List<Task> get allTasks => _tasks;

  /// Estado de carga
  bool get isLoading => _isLoading;

  /// Mensaje de error
  String? get errorMessage => _errorMessage;

  /// Filtro actual
  TaskFilter get filter => _filter;

  /// Estado de conexión
  bool get isConnected => _isConnected;

  /// Verifica la conectividad
  Future<void> checkConnectivity() async {
    _isConnected = await _connectivityService.isConnected();
    notifyListeners();
  }

  /// Carga las tareas
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool? completed;
      if (_filter == TaskFilter.pending) {
        completed = false;
      } else if (_filter == TaskFilter.completed) {
        completed = true;
      }

      _tasks = await _repository.getTasks(completed: completed);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar las tareas: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia el filtro y recarga las tareas
  Future<void> setFilter(TaskFilter filter) async {
    if (_filter != filter) {
      _filter = filter;
      await loadTasks();
    }
  }

  /// Crea una nueva tarea
  Future<bool> createTask(String title) async {
    if (title.trim().isEmpty) {
      _errorMessage = 'El título no puede estar vacío';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = await _repository.createTask(title.trim());
      _tasks.insert(0, task);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error al crear la tarea: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza una tarea
  Future<bool> updateTask(Task task, {String? title, bool? completed}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTask = task.copyWith(
        title: title ?? task.title,
        completed: completed ?? task.completed,
      );

      final result = await _repository.updateTask(updatedTask);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = result;
      }
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar la tarea: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca una tarea como completada o pendiente
  Future<bool> toggleTaskCompletion(Task task) async {
    // Actualización optimista: actualizar UI inmediatamente
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final optimisticTask = task.copyWith(
        completed: !task.completed,
        updatedAt: DateTime.now(),
      );
      _tasks[index] = optimisticTask;
      notifyListeners(); // Notificar inmediatamente para UI fluida
    }

    // Sincronizar en segundo plano sin bloquear (fire and forget)
    _repository.toggleTaskCompletion(task).then((syncedTask) {
      // Actualizar con el resultado del servidor si es diferente
      final currentIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (currentIndex != -1) {
        _tasks[currentIndex] = syncedTask;
        notifyListeners();
      }
    }).catchError((e) {
      debugPrint('Error al sincronizar toggle: $e');
      // Revertir cambio optimista en caso de error
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    });

    _errorMessage = null;
    return true; // Retornar inmediatamente
  }

  /// Elimina una tarea
  Future<bool> deleteTask(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteTask(id);
      _tasks.removeWhere((task) => task.id == id);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar la tarea: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fuerza una sincronización completa
  Future<bool> forceSync() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.forceSync();
      await loadTasks();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Error al sincronizar: $e';
      debugPrint(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Enum para los filtros de tareas
enum TaskFilter {
  all,
  pending,
  completed,
}

