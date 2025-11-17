import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoToma {
  tomado,
  pospuesto,
  omitido,
}

class Toma {
  String? id;
  String medicamentoId;
  String medicamentoNombre;
  String dosis;
  DateTime fechaHoraProgramada;
  DateTime? fechaHoraReal;
  EstadoToma estado;
  String? notas;
  DateTime createdAt;

  Toma({
    this.id,
    required this.medicamentoId,
    required this.medicamentoNombre,
    required this.dosis,
    required this.fechaHoraProgramada,
    this.fechaHoraReal,
    this.estado = EstadoToma.omitido,
    this.notas,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'medicamentoId': medicamentoId,
      'medicamentoNombre': medicamentoNombre,
      'dosis': dosis,
      'fechaHoraProgramada': Timestamp.fromDate(fechaHoraProgramada),
      'fechaHoraReal':
          fechaHoraReal != null ? Timestamp.fromDate(fechaHoraReal!) : null,
      'estado': estado.name,
      'notas': notas,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Toma.fromMap(Map<String, dynamic> map, String id) {
    return Toma(
      id: id,
      medicamentoId: map['medicamentoId'] ?? '',
      medicamentoNombre: map['medicamentoNombre'] ?? '',
      dosis: map['dosis'] ?? '',
      fechaHoraProgramada: (map['fechaHoraProgramada'] as Timestamp).toDate(),
      fechaHoraReal: map['fechaHoraReal'] != null
          ? (map['fechaHoraReal'] as Timestamp).toDate()
          : null,
      estado: EstadoToma.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoToma.omitido,
      ),
      notas: map['notas'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
