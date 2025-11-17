import 'dart:convert';

/// Tipo de acción realizada en el reloj
enum TipoAccion { tomado, pospuesto }

/// Modelo ligero para medicamentos en el reloj Wear
/// Contiene solo la información necesaria para mostrar recordatorios
class WearMedicamento {
  final String id;
  final String nombre;
  final String dosis;
  final List<String> horarios; // Formato: "HH:mm"
  final DateTime ultimaToma;
  final bool tomadoHoy;

  WearMedicamento({
    required this.id,
    required this.nombre,
    required this.dosis,
    required this.horarios,
    required this.ultimaToma,
    required this.tomadoHoy,
  });

  /// Serializar a JSON para enviar al reloj
  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'dosis': dosis,
    'horarios': horarios,
    'ultimaToma': ultimaToma.toIso8601String(),
    'tomadoHoy': tomadoHoy,
  };

  /// Deserializar desde JSON
  factory WearMedicamento.fromJson(Map<String, dynamic> json) =>
    WearMedicamento(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      dosis: json['dosis'] as String,
      horarios: List<String>.from(json['horarios'] as List),
      ultimaToma: DateTime.parse(json['ultimaToma'] as String),
      tomadoHoy: json['tomadoHoy'] as bool,
    );

  /// Crear desde string JSON
  factory WearMedicamento.fromJsonString(String jsonString) =>
    WearMedicamento.fromJson(jsonDecode(jsonString));

  /// Convertir a string JSON
  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() =>
    'WearMedicamento(id: $id, nombre: $nombre, dosis: $dosis, horarios: $horarios)';
}

/// Respuesta del reloj cuando toma un medicamento
class WearMedicamentoAccion {
  final String medicamentoId;
  final TipoAccion accion;
  final DateTime timestamp;

  WearMedicamentoAccion({
    required this.medicamentoId,
    required this.accion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'medicamento_id': medicamentoId,
    'accion': accion.toString().split('.').last,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WearMedicamentoAccion.fromJson(Map<String, dynamic> json) =>
    WearMedicamentoAccion(
      medicamentoId: json['medicamento_id'] as String,
      accion: json['accion'] == 'tomado' 
        ? TipoAccion.tomado 
        : TipoAccion.pospuesto,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

  @override
  String toString() =>
    'WearMedicamentoAccion(id: $medicamentoId, accion: ${accion.name}, timestamp: $timestamp)';
}

/// Payload sincronización completa de medicamentos
class WearSyncPayload {
  final List<WearMedicamento> medicamentos;
  final DateTime timestampSync;
  final String version;

  WearSyncPayload({
    required this.medicamentos,
    required this.timestampSync,
    this.version = '1.0',
  });

  Map<String, dynamic> toJson() => {
    'medicamentos': medicamentos.map((m) => m.toJson()).toList(),
    'timestamp': timestampSync.toIso8601String(),
    'version': version,
  };

  factory WearSyncPayload.fromJson(Map<String, dynamic> json) =>
    WearSyncPayload(
      medicamentos: (json['medicamentos'] as List)
        .map((m) => WearMedicamento.fromJson(m as Map<String, dynamic>))
        .toList(),
      timestampSync: DateTime.parse(json['timestamp'] as String),
      version: json['version'] as String? ?? '1.0',
    );
}
