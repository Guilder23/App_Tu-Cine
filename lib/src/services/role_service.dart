// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  user('user'),
  admin('admin'),
  manager('manager');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.user;
    }
  }
}

class RoleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener el rol del usuario actual
  static Future<UserRole> getCurrentUserRole() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No hay usuario autenticado');
        return UserRole.user;
      }

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print('❌ Usuario no encontrado en Firestore');
        return UserRole.user;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;

      // Verificar tanto 'role' como 'rol' por compatibilidad
      final String? role = userData?['role'] ?? userData?['rol'];

      print('✅ Rol obtenido: $role');
      return UserRole.fromString(role);
    } catch (e) {
      print('❌ Error al obtener rol del usuario: $e');
      return UserRole.user;
    }
  }

  /// Verificar si el usuario actual es administrador
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  /// Verificar si el usuario actual es manager
  static Future<bool> isManager() async {
    final role = await getCurrentUserRole();
    return role == UserRole.manager;
  }

  /// Verificar si el usuario tiene permisos administrativos (admin o manager)
  static Future<bool> hasAdminPrivileges() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin || role == UserRole.manager;
  }

  /// Obtener el rol de un usuario específico por UID
  static Future<UserRole> getUserRole(String uid) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return UserRole.user;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      final String? role = userData?['role'] ?? userData?['rol'];

      return UserRole.fromString(role);
    } catch (e) {
      print('❌ Error al obtener rol del usuario $uid: $e');
      return UserRole.user;
    }
  }

  /// Establecer el rol de un usuario (solo para administradores)
  static Future<bool> setUserRole(String uid, UserRole role) async {
    try {
      // Verificar si el usuario actual es administrador
      final currentUserRole = await getCurrentUserRole();
      if (currentUserRole != UserRole.admin) {
        print('❌ Acceso denegado: Solo administradores pueden cambiar roles');
        return false;
      }

      await _firestore.collection('users').doc(uid).update({
        'role': role.value,
        'rol': role.value, // Mantener ambos campos por compatibilidad
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Rol actualizado para usuario $uid: ${role.value}');
      return true;
    } catch (e) {
      print('❌ Error al establecer rol del usuario: $e');
      return false;
    }
  }

  /// Obtener todos los usuarios con un rol específico
  static Future<List<Map<String, dynamic>>> getUsersByRole(
      UserRole role) async {
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.value)
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('❌ Error al obtener usuarios por rol: $e');
      return [];
    }
  }

  /// Crear un usuario administrador desde Firebase Console
  /// Este método es solo para documentación - debe ejecutarse desde Firebase Console
  static Map<String, dynamic> getAdminUserTemplate() {
    return {
      'username': 'Administrador',
      'email': 'admin@cineapp.com',
      'role': 'admin',
      'rol': 'admin', // Compatibilidad
      'created_at': FieldValue.serverTimestamp(),
      'profile_image': 'https://via.placeholder.com/150?text=Admin',
      'is_admin': true, // Campo adicional para queries rápidas
      'birthdate': DateTime.now()
          .subtract(const Duration(days: 10000))
          .toIso8601String(),
      'verified': true,
      'active': true,
    };
  }

  /// Logs para debugging de roles
  static Future<void> debugUserRole() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('🔍 DEBUG: No hay usuario autenticado');
        return;
      }

      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        print('🔍 DEBUG: Usuario no encontrado en Firestore');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;

      print('🔍 DEBUG: Datos del usuario:');
      print('   - UID: ${currentUser.uid}');
      print('   - Email: ${currentUser.email}');
      print('   - Role field: ${userData?['role']}');
      print('   - Rol field: ${userData?['rol']}');
      print('   - Is Admin: ${await isAdmin()}');
      print('   - Has Admin Privileges: ${await hasAdminPrivileges()}');
    } catch (e) {
      print('🔍 DEBUG ERROR: $e');
    }
  }
}
