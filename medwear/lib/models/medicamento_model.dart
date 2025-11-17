import 'package:cloud_firestore/cloud_firestore.dart';

class Medicamento {
  String? id;
  String nombre;
  String dosis;
  List<String> horarios;
  List<int> diasSemana;
  DateTime fechaInicio;
  DateTime? fechaFin;
  bool activo;
  DateTime createdAt;
  DateTime updatedAt;

  Medicamento({
    this.id,
    required this.nombre,
    required this.dosis,
    required this.horarios,
    required this.diasSemana,
    required this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'dosis': dosis,
      'horarios': horarios,
      'diasSemana': diasSemana,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin!) : null,
      'activo': activo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Medicamento.fromMap(Map<String, dynamic> map, String id) {
    return Medicamento(
      id: id,
      nombre: map['nombre'] ?? '',
      dosis: map['dosis'] ?? '',
      horarios: List<String>.from(map['horarios'] ?? []),
      diasSemana: List<int>.from(map['diasSemana'] ?? []),
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      fechaFin: map['fechaFin'] != null
          ? (map['fechaFin'] as Timestamp).toDate()
          : null,
      activo: map['activo'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Medicamento copyWith({
    String? id,
    String? nombre,
    String? dosis,
    List<String>? horarios,
    List<int>? diasSemana,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicamento(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      dosis: dosis ?? this.dosis,
      horarios: horarios ?? this.horarios,
      diasSemana: diasSemana ?? this.diasSemana,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
