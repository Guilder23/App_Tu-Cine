// login_provider_test.dart
// Versión de prueba que permite acceso con cualquier credencial
// Para facilitar el testing de funcionalidades internas

import 'package:peliculas/src/services/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  notAuthenticated,
  checking,
  authenticated,
}

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorage _localStorage = LocalStorage();

  AuthStatus authStatus = AuthStatus.notAuthenticated;

  String? _errorMessage;
  String get errorMessage => _errorMessage ?? '';

  bool obscureText = true;
  bool isLoggedIn = false;

  // Constructor
  LoginProvider() {
    checkAuthStatus();
  }

  // Verificar estado de autenticación - VERSIÓN DE PRUEBA
  Future<void> checkAuthStatus() async {
    print('Verificando estado de autenticación (MODO PRUEBA)...');
    authStatus = AuthStatus.checking;
    notifyListeners();

    try {
      // Verificamos si hay datos guardados en localStorage
      bool isLoggedInStorage = await _localStorage.getIsLoggedIn();

      if (isLoggedInStorage) {
        print(
            'Usuario encontrado en localStorage, autenticando automáticamente');
        isLoggedIn = true;
        authStatus = AuthStatus.authenticated;
        await _localStorage.setIsLoggedIn(true);
        await _localStorage.setIsSignedIn(true);
      } else {
        // Si no hay datos en localStorage, verificamos Firebase
        User? user = _auth.currentUser;
        if (user != null) {
          print('Usuario autenticado encontrado en Firebase: ${user.email}');
          isLoggedIn = true;
          authStatus = AuthStatus.authenticated;
          await _localStorage.setIsLoggedIn(true);
          await _localStorage.setIsSignedIn(true);
        } else {
          print('No hay usuario autenticado');
          isLoggedIn = false;
          authStatus = AuthStatus.notAuthenticated;
          await _localStorage.setIsLoggedIn(false);
        }
      }
    } catch (e) {
      print('Error al verificar autenticación: $e');
      // En modo de prueba, mantenemos la sesión activa incluso si hay errores
      bool isLoggedInStorage = await _localStorage.getIsLoggedIn();
      if (isLoggedInStorage) {
        isLoggedIn = true;
        authStatus = AuthStatus.authenticated;
      } else {
        isLoggedIn = false;
        authStatus = AuthStatus.notAuthenticated;
      }
    }

    notifyListeners();
  }

  // Método de login universal - VERSIÓN DE PRUEBA
  Future<Map<String, dynamic>?> loginWithEmailOrUsername(
      String email, String password) async {
    print('Iniciando login con email: $email (MODO PRUEBA - ACCESO UNIVERSAL)');

    try {
      _errorMessage = null;
      authStatus = AuthStatus.checking;
      notifyListeners();

      // BYPASS: Saltamos la autenticación real y asumimos éxito
      print('Modo de prueba: Saltando verificación con Firebase Auth');

      // Crear datos ficticios del usuario para pruebas
      Map<String, dynamic> userData = {
        'uid': 'test-user-${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'username': email.split('@')[0],
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': true,
        'estado': 'activo',
        'rol': 'admin', // Para tener acceso a todas las funcionalidades
      };

      // Actualizar estado local
      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;

      // Guardar en local storage
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, password);

      notifyListeners();

      print('Login simulado completado exitosamente');
      return userData;
    } catch (e) {
      print('Error en login simulado: $e');

      // En modo de prueba, ignoramos los errores y autenticamos de todos modos
      Map<String, dynamic> userData = {
        'uid': 'test-user-fallback',
        'email': email,
        'username': email.split('@')[0],
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': true,
        'estado': 'activo',
        'rol': 'admin',
      };

      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, password);

      notifyListeners();
      return userData;
    }
  }

  // Método de registro universal - VERSIÓN DE PRUEBA
  Future<Map<String, dynamic>?> registerWithEmail(
      String email, String password, String username) async {
    print('Iniciando registro con email: $email (MODO PRUEBA)');

    try {
      _errorMessage = null;
      authStatus = AuthStatus.checking;
      notifyListeners();

      // BYPASS: Saltamos la creación real de usuario
      print('Usuario simulado creado con éxito: $email');

      // Datos simulados de usuario
      final String uid =
          'test-user-reg-${DateTime.now().millisecondsSinceEpoch}';
      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email.trim(),
        'username': username.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': true,
        'estado': 'activo',
        'rol': 'admin',
      };

      print('Usuario simulado creado correctamente');

      // Actualizar estado local
      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;

      // Guardar en local storage
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, password);

      notifyListeners();

      print('Registro simulado completado exitosamente');
      return userData;
    } catch (e) {
      print('Error en registro simulado: $e');

      // En modo de prueba, aún así consideramos el registro exitoso
      Map<String, dynamic> userData = {
        'uid': 'test-user-fallback-${DateTime.now().millisecondsSinceEpoch}',
        'email': email.trim(),
        'username': username.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': true,
        'estado': 'activo',
        'rol': 'admin',
      };

      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, password);

      notifyListeners();
      return userData;
    }
  }

  // Método simulado para inicio de sesión con Google - VERSIÓN DE PRUEBA
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Iniciando proceso de Google Sign In (SIMULADO)...');

      // Simulación de inicio de sesión exitoso con Google
      String email = 'usuario.google@gmail.com';
      String displayName = 'Usuario Google';
      String uid = 'google-user-${DateTime.now().millisecondsSinceEpoch}';

      // Datos simulados del usuario
      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email,
        'username': displayName,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': true,
        'estado': 'activo',
        'rol': 'admin',
      };

      print('Login con Google simulado exitosamente');

      // Actualizar estado local
      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, '');

      notifyListeners();
      return userData;
    } catch (e) {
      print('Error en Google Sign-In simulado: $e');

      // Incluso en caso de error, simulamos éxito para pruebas
      Map<String, dynamic> userData = {
        'uid': 'google-fallback-user',
        'email': 'usuario.google.fallback@gmail.com',
        'username': 'Usuario Google Fallback',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': true,
        'estado': 'activo',
        'rol': 'admin',
      };

      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(userData['email'] ?? '', '');

      notifyListeners();
      return userData;
    }
  }

  // Método para cerrar sesión - VERSIÓN DE PRUEBA
  Future<void> logoutApp() async {
    print('Cerrando sesión (SIMULADO)...');

    try {
      // No es necesario cerrar sesión real en Firebase en modo de prueba
      // Solo limpiamos el almacenamiento local

      // Limpiar local storage
      await _localStorage.setIsLoggedIn(false);
      await _localStorage.setIsSignedIn(false);
      await _localStorage.clear();

      // Actualizar estado
      isLoggedIn = false;
      authStatus = AuthStatus.notAuthenticated;
      _errorMessage = null;

      notifyListeners();
      print('Sesión cerrada exitosamente');
    } catch (e) {
      print('Error al cerrar sesión: $e');

      // En modo de prueba, forzamos el cierre de sesión incluso con error
      isLoggedIn = false;
      authStatus = AuthStatus.notAuthenticated;
      await _localStorage.setIsLoggedIn(false);
      await _localStorage.setIsSignedIn(false);

      notifyListeners();
    }
  }

  // Cambiar visibilidad de contraseña
  void togglePasswordVisibility() {
    obscureText = !obscureText;
    notifyListeners();
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
