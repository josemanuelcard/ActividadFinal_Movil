import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

/// Widget que muestra el estado de conectividad
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                provider.isConnected ? Icons.wifi : Icons.wifi_off,
                size: 20,
                color: provider.isConnected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                provider.isConnected ? 'En línea' : 'Sin conexión',
                style: TextStyle(
                  fontSize: 12,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

