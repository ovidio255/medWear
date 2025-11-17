import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/medicamento_controller.dart';
import '../models/toma_model.dart';

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MedicamentoController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Tomas'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: controller.obtenerEstadisticas(dias: 7),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final stats = snapshot.data!;
              final porcentaje = stats['porcentajeAdherencia'] as double;

              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Últimos 7 días',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Adherencia',
                            '${porcentaje.toStringAsFixed(1)}%',
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'Tomadas',
                            '${stats['tomadas']}',
                            Colors.green,
                          ),
                          _buildStatItem(
                            'Omitidas',
                            '${stats['omitidas']}',
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Expanded(
            child: Obx(() {
              if (controller.historialTomas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay historial de tomas',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final tomasPorFecha = <String, List<Toma>>{};
              for (var toma in controller.historialTomas) {
                final fecha = DateFormat('yyyy-MM-dd')
                    .format(toma.fechaHoraProgramada);
                if (!tomasPorFecha.containsKey(fecha)) {
                  tomasPorFecha[fecha] = [];
                }
                tomasPorFecha[fecha]!.add(toma);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tomasPorFecha.length,
                itemBuilder: (context, index) {
                  final fecha = tomasPorFecha.keys.elementAt(index);
                  final tomas = tomasPorFecha[fecha]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _formatearFecha(fecha),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...tomas.map((toma) => _TomaCard(toma: toma)),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _formatearFecha(String fecha) {
    final date = DateTime.parse(fecha);
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(hoy)) {
      return 'Hoy';
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(ayer)) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE, d MMMM', 'es').format(date);
    }
  }
}

class _TomaCard extends StatelessWidget {
  final Toma toma;

  const _TomaCard({required this.toma});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getIcono(),
          color: _getColor(),
        ),
        title: Text(toma.medicamentoNombre),
        subtitle: Text('${toma.dosis} - ${_formatearHora(toma.fechaHoraProgramada)}'),
        trailing: Chip(
          label: Text(
            _getEstadoTexto(),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: _getColor().withOpacity(0.2),
        ),
      ),
    );
  }

  IconData _getIcono() {
    switch (toma.estado) {
      case EstadoToma.tomado:
        return Icons.check_circle;
      case EstadoToma.pospuesto:
        return Icons.schedule;
      case EstadoToma.omitido:
        return Icons.cancel;
    }
  }

  Color _getColor() {
    switch (toma.estado) {
      case EstadoToma.tomado:
        return Colors.green;
      case EstadoToma.pospuesto:
        return Colors.orange;
      case EstadoToma.omitido:
        return Colors.red;
    }
  }

  String _getEstadoTexto() {
    switch (toma.estado) {
      case EstadoToma.tomado:
        return 'Tomado';
      case EstadoToma.pospuesto:
        return 'Pospuesto';
      case EstadoToma.omitido:
        return 'Omitido';
    }
  }

  String _formatearHora(DateTime fecha) {
    return DateFormat('HH:mm').format(fecha);
  }
}
