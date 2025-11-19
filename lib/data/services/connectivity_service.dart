import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio para verificar la conectividad
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Verifica si hay conexión a internet
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream de cambios de conectividad
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

