// admin_service.dart
// Servicio para gestionar funcionalidades específicas de administradores

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifica si ya existe al menos un usuario con rol de administrador
  static Future<bool> hasAdminUser() async {
    try {
      print('🔍 Verificando si existe un administrador...');

      // Buscar usuarios con rol 'admin' en ambos campos por compatibilidad
      final QuerySnapshot adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        print('✅ Se encontró administrador existente');
        return true;
      }

      // Verificar también en el campo 'rol' por compatibilidad
      final QuerySnapshot adminQueryCompat = await _firestore
          .collection('users')
          .where('rol', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (adminQueryCompat.docs.isNotEmpty) {
        print('✅ Se encontró administrador existente (campo compatibilidad)');
        return true;
      }

      print('❌ No se encontró ningún administrador');
      return false;
    } catch (e) {
      print('❌ Error al verificar administrador: $e');
      // En caso de error, asumir que no hay admin para permitir creación
      return false;
    }
  }

  /// Obtiene la lista de todos los administradores
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final QuerySnapshot adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return adminQuery.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error al obtener administradores: $e');
      return [];
    }
  }

  /// Cuenta el número total de administradores
  static Future<int> getAdminCount() async {
    try {
      final QuerySnapshot adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return adminQuery.docs.length;
    } catch (e) {
      print('Error al contar administradores: $e');
      return 0;
    }
  }
}
