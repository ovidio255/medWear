import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../controllers/medicamento_controller.dart';
import '../models/medicamento_model.dart';

class AgregarMedicamentoPage extends StatefulWidget {
  const AgregarMedicamentoPage({super.key});

  @override
  State<AgregarMedicamentoPage> createState() => _AgregarMedicamentoPageState();
}

class _AgregarMedicamentoPageState extends State<AgregarMedicamentoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _dosisController = TextEditingController();

  final List<String> _horarios = [];
  final List<int> _diasSemana = [1, 2, 3, 4, 5, 6, 7];
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  final controller = Get.find<MedicamentoController>();

  @override
  void dispose() {
    _nombreController.dispose();
    _dosisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Medicamento'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del medicamento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosisController,
              decoration: const InputDecoration(
                labelText: 'Dosis (ej: 500mg, 1 tableta)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.colorize),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa la dosis';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Horarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle), onPressed: _agregarHorario),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_horarios.isEmpty)
                      const Text('Presiona + para agregar horarios', style: TextStyle(color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _horarios.map((hora) {
                          return Chip(
                            label: Text(hora),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _horarios.remove(hora);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Días de la semana', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDiaChip('L', 1),
                        _buildDiaChip('M', 2),
                        _buildDiaChip('X', 3),
                        _buildDiaChip('J', 4),
                        _buildDiaChip('V', 5),
                        _buildDiaChip('S', 6),
                        _buildDiaChip('D', 7),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Fecha de inicio'),
                subtitle: Text('${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}'),
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaInicio,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fecha != null) {
                    setState(() {
                      _fechaInicio = fecha;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Fecha de fin (opcional)'),
                subtitle: Text(_fechaFin != null ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}' : 'Sin fecha de fin'),
                trailing: _fechaFin != null
                    ? IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() { _fechaFin = null; }); })
                    : null,
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: _fechaFin ?? _fechaInicio.add(const Duration(days: 30)),
                    firstDate: _fechaInicio,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fecha != null) {
                    setState(() {
                      _fechaFin = fecha;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardarMedicamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Guardar Medicamento', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaChip(String letra, int dia) {
    final seleccionado = _diasSemana.contains(dia);
    return FilterChip(
      label: Text(letra),
      selected: seleccionado,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _diasSemana.add(dia);
          } else {
            _diasSemana.remove(dia);
          }
        });
      },
    );
  }

  Future<void> _agregarHorario() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      final hora = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (!_horarios.contains(hora)) {
          _horarios.add(hora);
          _horarios.sort();
        }
      });
    }
  }

  Future<void> _guardarMedicamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_horarios.isEmpty) {
      _mostrarError('Debes agregar al menos un horario');
      return;
    }
    if (_diasSemana.isEmpty) {
      _mostrarError('Debes seleccionar al menos un día');
      return;
    }
    final medicamento = Medicamento(
      nombre: _nombreController.text.trim(),
      dosis: _dosisController.text.trim(),
      horarios: _horarios,
      diasSemana: _diasSemana,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      activo: true,
    );
    final exito = await controller.agregarMedicamento(medicamento);
    if (exito) {
      Get.back();
    }
  }

  void _mostrarError(String mensaje) {
    if (kIsWeb) {
      print('Error: $mensaje');
    } else {
      Get.snackbar('Error', mensaje, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
