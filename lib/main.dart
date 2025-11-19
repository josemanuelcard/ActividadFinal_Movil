import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'data/local/database_helper.dart';
import 'data/remote/api_service.dart';
import 'data/repositories/task_repository.dart';
import 'data/services/connectivity_service.dart';
import 'data/services/sync_service.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Verificar si está ejecutando en web
  if (kIsWeb) {
    runApp(const WebNotSupportedApp());
    return;
  }
  
  // Inicializar la base de datos antes de iniciar la app
  try {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.database; // Esto inicializa la BD
  } catch (e) {
    debugPrint('Error al inicializar la base de datos: $e');
    runApp(const DatabaseErrorApp());
    return;
  }
  
  runApp(const MyApp());
}

/// Widget para mostrar cuando se ejecuta en web
class WebNotSupportedApp extends StatelessWidget {
  const WebNotSupportedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Esta aplicación no es compatible con web',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Por favor, ejecuta la aplicación en un dispositivo Android o iOS, o en un emulador.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Para crear un emulador Android:\n'
                  '1. Abre Android Studio\n'
                  '2. Ve a Tools > Device Manager\n'
                  '3. Crea un nuevo dispositivo virtual',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar cuando hay error de base de datos
class DatabaseErrorApp extends StatelessWidget {
  const DatabaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error al inicializar la base de datos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Por favor, asegúrate de ejecutar la aplicación en un dispositivo Android o iOS.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializar servicios
    final dbHelper = DatabaseHelper.instance;
    final apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000', // Para Android Emulator
      // baseUrl: 'http://localhost:3000', // Para iOS Simulator o dispositivo físico
    );
    final connectivityService = ConnectivityService();
    final syncService = SyncService(
      dbHelper: dbHelper,
      apiService: apiService,
    );
    final taskRepository = TaskRepository(
      dbHelper: dbHelper,
      apiService: apiService,
      connectivityService: connectivityService,
      syncService: syncService,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(
            repository: taskRepository,
            connectivityService: connectivityService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'To-Do List',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
