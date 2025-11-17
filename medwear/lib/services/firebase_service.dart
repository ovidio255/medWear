import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicamento_model.dart';
import '../models/toma_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get medicamentosCollection =>
      _firestore.collection('medicamentos');
  CollectionReference get tomasCollection => _firestore.collection('tomas');

  
  Future<String> crearMedicamento(Medicamento medicamento) async {
    try {
      final docRef = await medicamentosCollection.add(medicamento.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear medicamento: $e');
    }
  }

  Stream<List<Medicamento>> obtenerMedicamentosActivos() {
    return medicamentosCollection
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final medicamentos = snapshot.docs.map((doc) {
        return Medicamento.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      
      medicamentos.sort((a, b) => a.nombre.compareTo(b.nombre));
      return medicamentos;
    });
  }

  Stream<List<Medicamento>> obtenerTodosMedicamentos() {
    return medicamentosCollection.snapshots().map((snapshot) {
      final medicamentos = snapshot.docs.map((doc) {
        return Medicamento.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      
      medicamentos.sort((a, b) => a.nombre.compareTo(b.nombre));
      return medicamentos;
    });
  }

  Future<Medicamento?> obtenerMedicamentoPorId(String id) async {
    try {
      final doc = await medicamentosCollection.doc(id).get();
      if (doc.exists) {
        return Medicamento.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener medicamento: $e');
    }
  }

  Future<void> actualizarMedicamento(Medicamento medicamento) async {
    try {
      if (medicamento.id == null) {
        throw Exception('El medicamento debe tener un ID');
      }
      await medicamentosCollection.doc(medicamento.id).update({
        ...medicamento.toMap(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al actualizar medicamento: $e');
    }
  }

  Future<void> desactivarMedicamento(String id) async {
    try {
      await medicamentosCollection.doc(id).update({
        'activo': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al desactivar medicamento: $e');
    }
  }

  Future<void> eliminarMedicamento(String id) async {
    try {
      await medicamentosCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar medicamento: $e');
    }
  }

  
  Future<String> registrarToma(Toma toma) async {
    try {
      final docRef = await tomasCollection.add(toma.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Error al registrar toma: $e');
    }
  }

  Stream<List<Toma>> obtenerHistorialTomas({int dias = 30}) {
    final fechaLimite = DateTime.now().subtract(Duration(days: dias));
    
    return tomasCollection
        .where('fechaHoraProgramada',
            isGreaterThanOrEqualTo: Timestamp.fromDate(fechaLimite))
        .snapshots()
        .map((snapshot) {
      final tomas = snapshot.docs.map((doc) {
        return Toma.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      
      tomas.sort((a, b) => b.fechaHoraProgramada.compareTo(a.fechaHoraProgramada));
      return tomas;
    });
  }

  Stream<List<Toma>> obtenerTomasPorMedicamento(String medicamentoId) {
    return tomasCollection
        .where('medicamentoId', isEqualTo: medicamentoId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final tomas = snapshot.docs.map((doc) {
        return Toma.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      
      tomas.sort((a, b) => b.fechaHoraProgramada.compareTo(a.fechaHoraProgramada));
      return tomas;
    });
  }

  Stream<List<Toma>> obtenerTomasHoy() {
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));

    return tomasCollection
        .where('fechaHoraProgramada',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
        .where('fechaHoraProgramada',
            isLessThan: Timestamp.fromDate(finHoy))
        .snapshots()
        .map((snapshot) {
      final tomas = snapshot.docs.map((doc) {
        return Toma.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      
      tomas.sort((a, b) => a.fechaHoraProgramada.compareTo(b.fechaHoraProgramada));
      return tomas;
    });
  }

  Future<void> actualizarEstadoToma(
    String tomaId,
    EstadoToma estado, {
    DateTime? fechaHoraReal,
    String? notas,
  }) async {
    try {
      final updateData = {
        'estado': estado.name,
        'fechaHoraReal': fechaHoraReal != null
            ? Timestamp.fromDate(fechaHoraReal)
            : Timestamp.now(),
      };
      
      if (notas != null) {
        updateData['notas'] = notas;
      }

      await tomasCollection.doc(tomaId).update(updateData);
    } catch (e) {
      throw Exception('Error al actualizar estado de toma: $e');
    }
  }

  Future<Map<String, dynamic>> obtenerEstadisticas({int dias = 7}) async {
    try {
      final fechaLimite = DateTime.now().subtract(Duration(days: dias));
      
      final snapshot = await tomasCollection
          .where('fechaHoraProgramada',
              isGreaterThanOrEqualTo: Timestamp.fromDate(fechaLimite))
          .get();

      int totalTomas = snapshot.docs.length;
      int tomadas = 0;
      int pospuestas = 0;
      int omitidas = 0;

      for (var doc in snapshot.docs) {
        final toma = Toma.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        
        switch (toma.estado) {
          case EstadoToma.tomado:
            tomadas++;
            break;
          case EstadoToma.pospuesto:
            pospuestas++;
            break;
          case EstadoToma.omitido:
            omitidas++;
            break;
        }
      }

      double porcentajeAdherencia = totalTomas > 0
          ? (tomadas / totalTomas * 100)
          : 0;

      return {
        'totalTomas': totalTomas,
        'tomadas': tomadas,
        'pospuestas': pospuestas,
        'omitidas': omitidas,
        'porcentajeAdherencia': porcentajeAdherencia,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
