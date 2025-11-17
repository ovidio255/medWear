import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/medicamento_controller.dart';
import '../services/wear_sync_service.dart';

/// Pantalla principal optimizada para Wear OS (reloj)
/// Muestra medicamentos pendientes con acciones rápidas
class WearHomePage extends StatefulWidget {
  const WearHomePage({super.key});

  @override
  State<WearHomePage> createState() => _WearHomePageState();
}

class _WearHomePageState extends State<WearHomePage> {
  late final MedicamentoController _medicamentoController;
  late final WearSyncService _wearSyncService;
  
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _medicamentoController = Get.find<MedicamentoController>();
    _wearSyncService = Get.find<WearSyncService>();
    
    // Sincronizar medicamentos del día al reloj
    _sincronizarMedicamentos();
  }

  Future<void> _sincronizarMedicamentos() async {
    final medicamentos = _medicamentoController.obtenerMedicamentosHoy();
    await _wearSyncService.sincronizarMedicamentosAlReloj(medicamentos);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 300;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(
          () {
            final medicamentosHoy =
                _medicamentoController.obtenerMedicamentosHoy();

            if (medicamentosHoy.isEmpty) {
              return _buildEmptyState(isSmallScreen);
            }

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: medicamentosHoy.length,
              itemBuilder: (context, index) {
                return _buildMedicamentoCard(
                  medicamentosHoy[index],
                  index,
                  medicamentosHoy.length,
                  isSmallScreen,
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Estado vacío - sin medicamentos para hoy
  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isSmallScreen)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          const SizedBox(height: 8),
          const Text(
            'Sin medicamentos\npara hoy',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              _wearSyncService.isWearConnected.value
                  ? '✅ Reloj conectado'
                  : '⚠️ Reloj desconectado',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta individual para cada medicamento
  Widget _buildMedicamentoCard(
    medicamento,
    int index,
    int total,
    bool isSmallScreen,
  ) {
    // Determinar próximo horario
    final ahora = DateTime.now();
    final proximoHorario = _obtenerProximoHorario(medicamento, ahora);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1e1e1e), Color(0xFF0a0a0a)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Indicador de página
            if (!isSmallScreen)
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '${index + 1}/$total',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),

            // Nombre del medicamento
            Column(
              children: [
                Text(
                  medicamento.nombre,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Dosis
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    medicamento.dosis,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isSmallScreen) ...[
                  const SizedBox(height: 12),
                  // Próximo horario
                  if (proximoHorario != null)
                    Text(
                      'Próximo: $proximoHorario',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                ],
              ],
            ),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón Posponer
                _buildActionButton(
                  icon: Icons.schedule,
                  label: 'Posponer',
                  color: Colors.orange,
                  onPressed: () async {
                    await _medicamentoController.postponerToma(medicamento);
                    _mostrarConfirmacion('Pospuesto 10 min');
                  },
                ),
                // Botón Tomado
                _buildActionButton(
                  icon: Icons.check_circle,
                  label: 'Tomado',
                  color: Colors.green,
                  onPressed: () async {
                    await _medicamentoController
                        .marcarComoTomado(medicamento);
                    _mostrarConfirmacion('¡Listo!');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Botón de acción para la tarjeta
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtener próximo horario para un medicamento
  String? _obtenerProximoHorario(medicamento, DateTime ahora) {
    try {
      for (final horario in medicamento.horarios) {
        final parts = horario.split(':');
        final hora = DateTime(
          ahora.year,
          ahora.month,
          ahora.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (hora.isAfter(ahora)) {
          return horario;
        }
      }
    } catch (e) {
      print('Error parseando horario: $e');
    }
    return null;
  }

  /// Mostrar confirmación visual
  void _mostrarConfirmacion(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
