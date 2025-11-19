import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/connectivity_indicator.dart';

/// Pantalla principal con la lista de tareas
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar tareas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
        actions: [
          // Indicador de conectividad
          const ConnectivityIndicator(),
          // Botón de sincronización
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.sync),
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final success = await provider.forceSync();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Sincronización completada'
                                    : 'Error al sincronizar',
                              ),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                        }
                      },
                tooltip: 'Sincronizar',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilterChips(),
          // Lista de tareas
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.allTasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.filter == TaskFilter.completed
                              ? 'No hay tareas completadas'
                              : provider.filter == TaskFilter.pending
                                  ? 'No hay tareas pendientes'
                                  : 'No hay tareas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadTasks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      return TaskItem(task: task);
                    },
                  ),
                );
              },
            ),
          ),
          // Mensaje de error
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              if (provider.errorMessage != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: provider.clearError,
                        color: Colors.red[700],
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Agregar tarea',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Construye los chips de filtro
  Widget _buildFilterChips() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context,
                        'Todas',
                        TaskFilter.all,
                        provider.filter == TaskFilter.all,
                        () => provider.setFilter(TaskFilter.all),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        'Pendientes',
                        TaskFilter.pending,
                        provider.filter == TaskFilter.pending,
                        () => provider.setFilter(TaskFilter.pending),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context,
                        'Completadas',
                        TaskFilter.completed,
                        provider.filter == TaskFilter.completed,
                        () => provider.setFilter(TaskFilter.completed),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construye un chip de filtro individual
  Widget _buildFilterChip(
    BuildContext context,
    String label,
    TaskFilter filter,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  /// Muestra el diálogo para agregar una nueva tarea
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }
}

