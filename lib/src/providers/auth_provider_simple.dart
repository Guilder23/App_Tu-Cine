// auth_provider_simple.dart
// Versión simplificada del proveedor de autenticación para login y registro

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:peliculas/src/services/imgbb_service.dart';
import 'package:peliculas/src/services/local_storage.dart';

enum AuthStatus {
  notAuthenticated,
  checking,
  authenticated,
}

class AuthProviderSimple extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorage _localStorage = LocalStorage();

  AuthStatus authStatus = AuthStatus.notAuthenticated;
  bool isLoading = false;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Constructor - Verifica el estado de autenticación al iniciar
  AuthProviderSimple() {
    checkAuthStatus();
  }

  // Verificar estado de autenticación
  Future<void> checkAuthStatus() async {
    authStatus = AuthStatus.checking;
    notifyListeners();

    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      // El usuario está autenticado
      await _localStorage.setIsLoggedIn(true);
      authStatus = AuthStatus.authenticated;
    } else {
      // El usuario no está autenticado
      await _localStorage.setIsLoggedIn(false);
      authStatus = AuthStatus.notAuthenticated;
    }

    notifyListeners();
  }

  // Registrar nuevo usuario
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required DateTime birthdate,
    File? profileImage,
    bool isAdmin = false, // Nuevo parámetro para identificar administradores
  }) async {
    try {
      print('🚀 Iniciando proceso de registro para: $email');
      isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // 1. Registrar en Firebase Auth
      print('📧 Creando usuario en Firebase Auth...');
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Usuario creado en Firebase Auth: ${userCredential.user?.uid}');

      String? imageUrl;

      // 2. Subir imagen de perfil a ImgBB si existe
      if (profileImage != null) {
        print('📸 Subiendo imagen de perfil...');
        imageUrl = await ImgBBService.uploadImage(profileImage);
        print('✅ Imagen subida: $imageUrl');
      }

      // Si no se pudo subir la imagen o no hay imagen, usar avatar por defecto
      if (imageUrl == null) {
        imageUrl = 'https://via.placeholder.com/150?text=Usuario';
        print('📸 Usando imagen por defecto');
      } // 3. Guardar datos del usuario en Firestore
      print('💾 Guardando datos en Firestore...');

      // Determinar el rol basado en si es administrador
      String userRole = isAdmin ? 'admin' : 'user';
      if (isAdmin) {
        print('🔑 Registrando usuario como administrador');
      }

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'birthdate': birthdate,
        'profile_image': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'role': userRole, // Campo principal para roles
        'rol': userRole, // Campo de compatibilidad
        'uid': userCredential.user!.uid,
        'verified': isAdmin
            ? true
            : false, // Admins se consideran verificados automáticamente
        'active': true,
      });

      print('✅ Datos guardados exitosamente en Firestore');

      // 4. Guardar en almacenamiento local
      print('💾 Guardando en almacenamiento local...');
      await _localStorage.setIsLoggedIn(true);

      // 5. Actualizar estado de autenticación
      authStatus = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();

      print('🎉 Registro completado exitosamente');
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;

      switch (e.code) {
        case 'email-already-in-use':
          _errorMessage = 'El correo ya está registrado';
          break;
        case 'weak-password':
          _errorMessage = 'La contraseña es muy débil';
          break;
        case 'invalid-email':
          _errorMessage = 'El correo no es válido';
          break;
        default:
          _errorMessage = 'Error: ${e.message}';
      }

      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;

      // Manejo específico de errores conocidos
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('Error de compatibilidad detectado: $e');
        _errorMessage =
            'Error de configuración. Reintentando...'; // Verificar si el usuario se creó en Firebase Auth
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          try {
            print('Usuario creado en Auth, creando documento en Firestore...');

            // Determinar el rol basado en si es administrador
            String userRole = isAdmin ? 'admin' : 'user';

            // Usuario creado en Auth, intentar crear documento en Firestore
            await _firestore.collection('users').doc(currentUser.uid).set({
              'username': username,
              'email': email,
              'birthdate': birthdate,
              'profile_image': 'https://via.placeholder.com/150?text=Usuario',
              'created_at': FieldValue.serverTimestamp(),
              'role': userRole, // Campo principal para roles
              'rol': userRole, // Campo de compatibilidad
              'uid': currentUser.uid,
              'verified': isAdmin ? true : false,
              'active': true,
            });

            print('Documento de usuario creado exitosamente en Firestore');

            await _localStorage.setIsLoggedIn(true);
            authStatus = AuthStatus.authenticated;
            isLoading = false;
            _errorMessage = '';
            notifyListeners();
            return true;
          } catch (firestoreError) {
            print('Error al crear documento en Firestore: $firestoreError');
            _errorMessage =
                'Usuario creado pero error al guardar perfil: $firestoreError';
          }
        } else {
          _errorMessage = 'Error de configuración y usuario no creado';
        }
      } else {
        _errorMessage = 'Error inesperado: $e';
      }

      print('Error final en registro: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  // Iniciar sesión
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔑 Iniciando proceso de login para: $email');
      isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // 1. Autenticar con Firebase
      print('🔐 Autenticando con Firebase Auth...');
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Login exitoso en Firebase Auth: ${userCredential.user?.uid}');
      print('✅ Login exitoso en Firebase Auth: ${userCredential.user?.uid}');

      // 2. Verificar que el usuario existe en Firestore
      print('🔍 Verificando documento en Firestore...');
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // El usuario no existe en Firestore (raro, pero posible)
        print('❌ Usuario no encontrado en Firestore');
        _errorMessage = 'Usuario no encontrado';
        await _auth.signOut();
        isLoading = false;
        notifyListeners();
        return false;
      }

      print('✅ Usuario encontrado en Firestore');

      // 3. Guardar en almacenamiento local
      print('💾 Guardando estado en almacenamiento local...');
      await _localStorage.setIsLoggedIn(true);

      // 4. Actualizar estado
      print('🎯 Actualizando estado de autenticación...');
      authStatus = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();

      print('🎉 Login completado exitosamente');
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;

      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          _errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          _errorMessage = 'El correo no es válido';
          break;
        case 'user-disabled':
          _errorMessage = 'Usuario deshabilitado';
          break;
        default:
          _errorMessage = 'Error: ${e.message}';
      }

      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;

      // Manejo específico de errores conocidos para login
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>') ||
          e.toString().contains('type cast')) {
        print('⚠️ Error de compatibilidad detectado en login: $e');
        _errorMessage = 'Error de configuración. Verificando estado...';

        // Verificar si el usuario se autenticó correctamente a pesar del error
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == email) {
          try {
            print('✅ Usuario autenticado correctamente a pesar del error');
            print('🔍 Verificando documento en Firestore...');

            // Verificar que el usuario existe en Firestore
            final userDoc =
                await _firestore.collection('users').doc(currentUser.uid).get();

            if (!userDoc.exists) {
              print('❌ Usuario no encontrado en Firestore');
              _errorMessage = 'Usuario no encontrado en base de datos';
              await _auth.signOut();
              isLoading = false;
              notifyListeners();
              return false;
            }

            print('✅ Usuario encontrado en Firestore');

            // Completar el proceso de login
            await _localStorage.setIsLoggedIn(true);
            authStatus = AuthStatus.authenticated;
            isLoading = false;
            _errorMessage = '';
            notifyListeners();

            print('🎉 Login completado exitosamente (recuperado del error)');
            return true;
          } catch (recoveryError) {
            print('❌ Error en recuperación de login: $recoveryError');
            _errorMessage =
                'Error al verificar datos del usuario: $recoveryError';
            await _auth
                .signOut(); // Asegurar que se cierre la sesión si hay error
          }
        } else {
          print('❌ Usuario no autenticado después del error');
          _errorMessage = 'Error de autenticación';
        }
      } else {
        print('❌ Error inesperado en login: $e');
        _errorMessage = 'Error inesperado: $e';
      }

      notifyListeners();
      return false;
    }
  }

  // Obtener datos del usuario actual
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!userDoc.exists) {
        return null;
      }
      return {
        'uid': currentUser.uid,
        ...userDoc.data()!,
      };
    } catch (e) {
      _errorMessage = 'Error al obtener datos del usuario: $e';
      notifyListeners();
      return null;
    }
  }

  // Actualizar perfil del usuario
  Future<bool> updateUserProfile({
    String? profileImage,
    String? username,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'No hay usuario autenticado';
        return false;
      }

      Map<String, dynamic> updateData = {};

      if (profileImage != null) {
        updateData['profile_image'] = profileImage;
      }

      if (username != null) {
        updateData['username'] = username;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      // Actualizar en Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      // Notificar a todos los listeners que los datos han cambiado
      notifyListeners();

      return true;
    } catch (e) {
      print('Error al actualizar perfil: $e');
      _errorMessage = 'Error al actualizar perfil: $e';
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      // 1. Cerrar sesión en Firebase
      await _auth.signOut();

      // 2. Limpiar almacenamiento local
      await _localStorage.setIsLoggedIn(false);
      await _localStorage.clear();

      // 3. Actualizar estado
      authStatus = AuthStatus.notAuthenticated;
      _errorMessage = '';

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
      notifyListeners();
    }
  }
}
