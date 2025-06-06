import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreReservationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  static const String _reservationsCollection = 'reservations';
  static const String _comprasCollection = 'compras';

  /// Obtener butacas reservadas para una función específica en tiempo real
  static Stream<List<int>> getReservedSeatsStream(
    String movieId,
    String date,
    String time,
  ) {
    return _firestore
        .collection(_reservationsCollection)
        .where('movieId', isEqualTo: movieId)
        .where('date', isEqualTo: date)
        .where('time', isEqualTo: time)
        .snapshots()
        .map((snapshot) {
      List<int> reservedSeats = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['seats'] != null) {
          reservedSeats.addAll(List<int>.from(data['seats']));
        }
      }
      return reservedSeats;
    });
  }

  /// Verificar disponibilidad de butacas antes de reservar
  static Future<bool> areSeatsAvailable(
    String movieId,
    String date,
    String time,
    List<int> seats,
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_reservationsCollection)
          .where('movieId', isEqualTo: movieId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      List<int> occupiedSeats = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['seats'] != null) {
          occupiedSeats.addAll(List<int>.from(data['seats']));
        }
      }

      // Verificar si alguna butaca ya está ocupada
      for (int seat in seats) {
        if (occupiedSeats.contains(seat)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error verificando disponibilidad: $e');
      return false;
    }
  }

  /// Crear reserva temporal (válida por tiempo limitado)
  static Future<String?> createTemporaryReservation({
    required String movieId,
    required String userId,
    required String date,
    required String time,
    required List<int> seats,
    int durationMinutes = 10,
  }) async {
    try {
      // Verificar disponibilidad primero
      bool available = await areSeatsAvailable(movieId, date, time, seats);
      if (!available) {
        throw Exception('Una o más butacas ya están reservadas');
      }

      // Crear reserva temporal
      final docRef = await _firestore.collection(_reservationsCollection).add({
        'movieId': movieId,
        'userId': userId,
        'date': date,
        'time': time,
        'seats': seats,
        'isTemporary': true,
        'expiresAt': DateTime.now().add(Duration(minutes: durationMinutes)),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Reserva temporal creada: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creando reserva temporal: $e');
      rethrow;
    }
  }

  /// Convertir reserva temporal a permanente (cuando se completa el pago)
  static Future<bool> confirmReservation(
    String reservationId,
    String compraId,
  ) async {
    try {
      await _firestore
          .collection(_reservationsCollection)
          .doc(reservationId)
          .update({
        'isTemporary': false,
        'compraId': compraId,
        'confirmedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Reserva confirmada: $reservationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error confirmando reserva: $e');
      return false;
    }
  }

  /// Cancelar reserva temporal
  static Future<bool> cancelTemporaryReservation(String reservationId) async {
    try {
      await _firestore
          .collection(_reservationsCollection)
          .doc(reservationId)
          .delete();
      debugPrint('🗑️ Reserva temporal cancelada: $reservationId');
      return true;
    } catch (e) {
      debugPrint('❌ Error cancelando reserva: $e');
      return false;
    }
  }

  /// Limpiar reservas temporales expiradas
  static Future<int> cleanExpiredReservations() async {
    try {
      final QuerySnapshot expiredReservations = await _firestore
          .collection(_reservationsCollection)
          .where('isTemporary', isEqualTo: true)
          .where('expiresAt', isLessThan: DateTime.now())
          .get();

      int deletedCount = 0;
      for (DocumentSnapshot doc in expiredReservations.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      if (deletedCount > 0) {
        debugPrint('🧹 Limpiadas $deletedCount reservas expiradas');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ Error limpiando reservas expiradas: $e');
      return 0;
    }
  }

  /// Obtener reservas del usuario
  static Future<List<Map<String, dynamic>>> getUserReservations(
      String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_reservationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isTemporary', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas del usuario: $e');
      return [];
    }
  }

  /// Obtener estadísticas de ocupación para una función
  static Future<Map<String, dynamic>> getOccupancyStats(
    String movieId,
    String date,
    String time,
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_reservationsCollection)
          .where('movieId', isEqualTo: movieId)
          .where('date', isEqualTo: date)
          .where('time', isEqualTo: time)
          .get();

      List<int> allReservedSeats = [];
      int temporaryReservations = 0;
      int permanentReservations = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['seats'] != null) {
          allReservedSeats.addAll(List<int>.from(data['seats']));
        }

        if (data['isTemporary'] == true) {
          temporaryReservations++;
        } else {
          permanentReservations++;
        }
      }

      const int totalSeats = 34; // Total de butacas en el cine

      return {
        'totalSeats': totalSeats,
        'reservedSeats': allReservedSeats.length,
        'availableSeats': totalSeats - allReservedSeats.length,
        'occupancyPercentage':
            (allReservedSeats.length / totalSeats * 100).round(),
        'temporaryReservations': temporaryReservations,
        'permanentReservations': permanentReservations,
        'reservedSeatNumbers': allReservedSeats,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return {
        'totalSeats': 34,
        'reservedSeats': 0,
        'availableSeats': 34,
        'occupancyPercentage': 0,
        'temporaryReservations': 0,
        'permanentReservations': 0,
        'reservedSeatNumbers': <int>[],
      };
    }
  }

  /// Crear compra completa (incluyendo reserva permanente)
  static Future<String?> createPurchase({
    required Map<String, dynamic> purchaseData,
    required String movieId,
    required String userId,
    required String date,
    required String time,
    required List<int> seats,
  }) async {
    try {
      // Crear la compra
      final compraRef =
          await _firestore.collection(_comprasCollection).add(purchaseData);

      // Crear reserva permanente
      await _firestore.collection(_reservationsCollection).add({
        'movieId': movieId,
        'userId': userId,
        'date': date,
        'time': time,
        'seats': seats,
        'isTemporary': false,
        'compraId': compraRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compra y reserva permanente creadas: ${compraRef.id}');
      return compraRef.id;
    } catch (e) {
      debugPrint('❌ Error creando compra: $e');
      rethrow;
    }
  }

  /// Programar limpieza automática de reservas expiradas
  static Future<void> scheduleCleanup() async {
    // En una implementación real, esto se manejaría con Cloud Functions
    // Por ahora, limpiamos cada vez que se inicia la app
    await cleanExpiredReservations();
  }
}
