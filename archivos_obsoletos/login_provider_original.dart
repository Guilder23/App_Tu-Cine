// login_provider.dart
// Proveedor de autenticación completo con email/password y Google Sign-In mejorado
// Versión corregida para resolver problemas de compatibilidad

import 'package:peliculas/src/services/local_storage.dart';
import 'package:peliculas/src/services/push_notification_service.dart';
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

      // Crear datos del usuario para Firestore
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
  }  // Método corregido para inicio de sesión con Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Iniciando proceso de Google Sign In...');

      // Configurar GoogleSignIn con configuración específica
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Limpiar sesiones anteriores
      try {
        await googleSignIn.signOut();
        await _auth.signOut();
      } catch (e) {
        print('Error al limpiar sesiones anteriores: $e');
      }

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

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _errorMessage = 'No se pudieron obtener tokens de autenticación';
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

      // Paso 4: Crear o actualizar usuario en Firestore
      Map<String, dynamic> userData;
      try {
        // Verificar si el usuario ya existe
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          // Usuario nuevo - crear registro
          print('Creando nuevo usuario en Firestore');
          userData = {
            'id': user.uid,
            'uid': user.uid,
            'username': user.displayName ?? 'Usuario Google',
            'username_lowercase':
                (user.displayName ?? 'usuario google').toLowerCase(),
            'email': user.email ?? '',
            'imageUser': user.photoURL ?? 'assets/images/avatar3.png',
            'biografia': '¡Hola! Soy nuevo en Peliculas',
            'birth': '',
            'edad': '0',
            'createdAt': DateTime.now().toIso8601String(),
            'estado': true,
            'premium': false,
            'aprobado': false,
            'verificado': true, // Los usuarios de Google se consideran verificados
            'favoritos': 0,
            'compartidos': 0,
            'favoritosJson': [],
            'compartidosJson': [],
            'rol': 'user',
            'token': PushNotificationService.token ?? '',
            'departamento': '',
            'ciudad': '',
            'telefono': '',
          };

          // Usar transacción para garantizar la creación del usuario
          await _firestore.runTransaction((transaction) async {
            transaction.set(docRef, userData);
          });

          print('Usuario creado con éxito en Firestore');
        } else {
          // Usuario existente - actualizar algunos campos
          userData = docSnapshot.data() as Map<String, dynamic>;

          // Actualizar campos importantes
          Map<String, dynamic> updateData = {
            'lastLogin': DateTime.now().toIso8601String(),
          };

          if (PushNotificationService.token != null) {
            updateData['token'] = PushNotificationService.token;
          }

          await docRef.update(updateData);
          print('Usuario existente actualizado en Firestore');
        }

        // Paso 5: Actualizar estado local
        await LocalStorage().setIsSignedIn(true);
        await LocalStorage().setIsLoggedIn(true);
        await LocalStorage().saveUserData(userData['email'] ?? '', '');

        authStatus = AuthStatus.authenticated;
        isLoggedIn = true;
        _errorMessage = null;
        notifyListeners();

        return userData;
      } catch (e) {
        print('Error en operaciones de Firestore: $e');

        // Intento de recuperación - crear usuario mínimo
        try {
          final Map<String, dynamic> fallbackUserData = {
            'id': user.uid,
            'uid': user.uid,
            'email': user.email ?? '',
            'username': user.displayName ?? 'Usuario',
            'createdAt': DateTime.now().toIso8601String(),
            'verificado': true,
          };

          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(fallbackUserData, SetOptions(merge: true));

          authStatus = AuthStatus.authenticated;
          isLoggedIn = true;

          return fallbackUserData;
        } catch (finalError) {
          _errorMessage = 'Error al guardar datos de usuario';
          notifyListeners();
          return null;
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Error de FirebaseAuth: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'account-exists-with-different-credential':
          _errorMessage =
              'Ya existe una cuenta con este email usando otro método';
          break;
        default:
          _errorMessage = 'Error de autenticación: ${e.message}';
      }
      notifyListeners();
      return null;
    } catch (e) {
      print('Error general: $e');
      _errorMessage = 'Error inesperado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
