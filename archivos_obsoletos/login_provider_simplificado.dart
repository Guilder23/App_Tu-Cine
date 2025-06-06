// login_provider_simplificado.dart
// Proveedor de autenticación muy simplificado con solo datos básicos
// Para resolver problemas con login y registro

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

  // Verificar estado de autenticación
  Future<void> checkAuthStatus() async {
    print('Verificando estado de autenticación...');
    authStatus = AuthStatus.checking;
    notifyListeners();

    try {
      User? user = _auth.currentUser;

      if (user != null) {
        print('Usuario autenticado encontrado: ${user.email}');
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
    } catch (e) {
      print('Error al verificar autenticación: $e');
      isLoggedIn = false;
      authStatus = AuthStatus.notAuthenticated;
    }

    notifyListeners();
  }

  // Método simplificado para login con email
  Future<Map<String, dynamic>?> loginWithEmailOrUsername(
      String email, String password) async {
    print('Iniciando login con email: $email');

    try {
      _errorMessage = null;
      authStatus = AuthStatus.checking;
      notifyListeners();

      // Autenticación con Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        _errorMessage = 'Error al obtener datos del usuario';
        authStatus = AuthStatus.notAuthenticated;
        notifyListeners();
        return null;
      }

      print('Login exitoso para: ${user.email}');

      // Verificar si el usuario existe en Firestore, si no, crearlo
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      Map<String, dynamic> userData;

      if (!userDoc.exists) {
        print('Usuario no existe en Firestore, creando...');

        // Crear datos básicos del usuario
        userData = {
          'uid': user.uid,
          'email': user.email,
          'username':
              user.displayName ?? user.email?.split('@')[0] ?? 'usuario',
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': DateTime.now().toIso8601String(),
          'verificado': user.emailVerified,
          'estado': 'activo',
        };

        // Guardar en Firestore
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('Usuario creado en Firestore');
      } else {
        print('Usuario existe en Firestore, actualizando lastLogin...');
        userData = userDoc.data() as Map<String, dynamic>;

        // Actualizar último login
        userData['lastLogin'] = DateTime.now().toIso8601String();
        await _firestore.collection('users').doc(user.uid).update({
          'lastLogin': DateTime.now().toIso8601String(),
        });
      }

      // Actualizar estado local
      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;

      // Guardar en local storage
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, password);

      notifyListeners();

      print('Login completado exitosamente');
      return userData;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No existe una cuenta con este email';
          break;
        case 'wrong-password':
          _errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          _errorMessage = 'Email inválido';
          break;
        case 'user-disabled':
          _errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'too-many-requests':
          _errorMessage = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          _errorMessage = 'Error de autenticación: ${e.message}';
      }

      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error general en login: $e');
      _errorMessage = 'Error de conexión. Verifica tu internet';
      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return null;
    }
  }

  // Método para registro de nuevos usuarios
  Future<Map<String, dynamic>?> registerWithEmail(
      String email, String password, String username) async {
    print('Iniciando registro con email: $email');

    try {
      _errorMessage = null;
      authStatus = AuthStatus.checking;
      notifyListeners();

      // Crear usuario en Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = userCredential.user;
      if (user == null) {
        _errorMessage = 'Error al crear el usuario';
        authStatus = AuthStatus.notAuthenticated;
        notifyListeners();
        return null;
      }

      print('Usuario creado en Firebase Auth: ${user.email}');

      // Actualizar displayName
      await user.updateDisplayName(username);

      // Crear datos básicos del usuario para Firestore
      Map<String, dynamic> userData = {
        'uid': user.uid,
        'email': user.email,
        'username': username.trim(),
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'verificado': false,
        'estado': 'activo',
      };

      // Guardar en Firestore
      await _firestore.collection('users').doc(user.uid).set(userData);
      print('Usuario guardado en Firestore');

      // Enviar email de verificación
      try {
        await user.sendEmailVerification();
        print('Email de verificación enviado');
      } catch (e) {
        print('Error al enviar email de verificación: $e');
      }

      // Actualizar estado local
      isLoggedIn = true;
      authStatus = AuthStatus.authenticated;

      // Guardar en local storage
      await _localStorage.setIsLoggedIn(true);
      await _localStorage.setIsSignedIn(true);
      await _localStorage.saveUserData(email, password);

      notifyListeners();

      print('Registro completado exitosamente');
      return userData;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth en registro: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'weak-password':
          _errorMessage = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          _errorMessage = 'Ya existe una cuenta con este email';
          break;
        case 'invalid-email':
          _errorMessage = 'Email inválido';
          break;
        default:
          _errorMessage = 'Error al crear cuenta: ${e.message}';
      }

      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return null;
    } catch (e) {
      print('Error general en registro: $e');
      _errorMessage = 'Error de conexión. Verifica tu internet';
      authStatus = AuthStatus.notAuthenticated;
      notifyListeners();
      return null;
    }
  }

  // Método simplificado para inicio de sesión con Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Iniciando proceso de Google Sign In...');

      // Configurar GoogleSignIn con configuración específica
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Paso 1: Iniciar sesión con Google
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
      } catch (e) {
        print('Error en Google Sign-In: $e');
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('List<Object?>') ||
            e.toString().contains('type cast')) {
          _errorMessage =
              'Error de compatibilidad con Google Sign-In. Por favor usa email/contraseña.';
          notifyListeners();
          return null;
        }
        throw e;
      }

      if (googleUser == null) {
        _errorMessage = 'Inicio de sesión cancelado';
        notifyListeners();
        return null;
      }

      // Paso 2: Obtener credenciales
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        print('Error al obtener credenciales: $e');
        _errorMessage = 'Error al obtener credenciales de Google';
        notifyListeners();
        return null;
      }

      // Paso 3: Iniciar sesión en Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } catch (e) {
        print('Error al autenticar con Firebase: $e');
        _errorMessage = 'Error al autenticar con Firebase';
        notifyListeners();
        return null;
      }

      final user = userCredential.user;
      if (user == null) {
        _errorMessage = 'No se pudo obtener información del usuario';
        notifyListeners();
        return null;
      }

      print('Usuario autenticado con Firebase: ${user.email}');

      // Guardar información básica del usuario en Firestore
      try {
        final docRef = _firestore.collection('users').doc(user.uid);

        // Datos básicos del usuario para Google Sign-In
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'username': user.displayName ?? 'Usuario Google',
          'createdAt': DateTime.now().toIso8601String(),
          'lastLogin': DateTime.now().toIso8601String(),
          'verificado': true,
        };

        // Guardar en firestore con opción de merge (actualiza si existe)
        await docRef.set(userData, SetOptions(merge: true));
        print('Usuario guardado en Firestore correctamente');

        // Actualizar estado local
        await _localStorage.setIsSignedIn(true);
        await _localStorage.setIsLoggedIn(true);
        await _localStorage.saveUserData(userData['email'] ?? '', '');

        authStatus = AuthStatus.authenticated;
        isLoggedIn = true;
        _errorMessage = null;
        notifyListeners();

        return userData;
      } catch (e) {
        print('Error al guardar en Firestore: $e');
        _errorMessage = 'Error al guardar datos de usuario';
        notifyListeners();
        return null;
      }
    } catch (e) {
      print('Error general: $e');
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Método para cerrar sesión
  Future<void> logoutApp() async {
    print('Cerrando sesión...');

    try {
      await _auth.signOut();

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
      _errorMessage = 'Error al cerrar sesión';
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
