// filepath: c:\Users\Tommy\Desktop\cine\code_warriors_gs\lib\src\providers\login_provider.dart
// ignore_for_file: unused_local_variable

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
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus authStatus = AuthStatus.notAuthenticated;

  String? _errorMessage;
  String get errorMessage => _errorMessage ?? '';

  bool obscureText = true;
  bool isLoggedIn = false;

  //para el login
  Future<UserCredential?> loginUser(String email, String password) async {
    try {
      print('Iniciando sesión con email: $email');

      // Intentar login con email/contraseña
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // En modo desarrollo, permitir login sin verificación de email
      // En producción, comentar estas líneas y descomentar la validación
      /*
      // Verificar si el email está verificado
      if (!userCredential.user!.emailVerified) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Por favor verifica tu email antes de iniciar sesión',
        );
      }
      */

      print('Login exitoso con Firebase Auth');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No se encontró una cuenta con este email';
          break;
        case 'wrong-password':
          _errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          _errorMessage = 'El formato del email no es válido';
          break;
        case 'user-disabled':
          _errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'email-not-verified':
          _errorMessage = 'Debes verificar tu email antes de iniciar sesión';
          break;
        case 'too-many-requests':
          _errorMessage = 'Demasiados intentos fallidos. Inténtalo más tarde';
          break;
        case 'invalid-credential':
          _errorMessage = 'Email o contraseña incorrectos';
          break;
        default:
          _errorMessage = 'Error de autenticación: ${e.message}';
      }
      notifyListeners();
      return null;
    } catch (e) {
      print('Error general en login: $e');
      _errorMessage = 'Error inesperado al iniciar sesión';
      notifyListeners();
      return null;
    }
  }

  // Login con email o username
  Future<Map<String, dynamic>?> loginWithEmailOrUsername(
      String emailOrUsername, String password) async {
    try {
      String email = emailOrUsername.trim().toLowerCase();

      // Si no es un email, buscar por username
      if (!email.contains('@')) {
        final userDoc = await _firestore
            .collection('users')
            .where('username_lowercase', isEqualTo: email)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          _errorMessage = 'Usuario no encontrado';
          notifyListeners();
          return null;
        }

        email = userDoc.docs.first.data()['email'];
      }

      // Intentar login
      final userCredential = await loginUser(email, password);
      if (userCredential == null) return null;

      // Obtener datos del usuario
      final userData = await getUserData(email);
      if (userData != null) {
        await LocalStorage().setIsSignedIn(true);
        await LocalStorage().setIsLoggedIn(true);
        await LocalStorage().saveUserData(email, password);

        authStatus = AuthStatus.authenticated;
        isLoggedIn = true;
        _errorMessage = null; // Limpiar errores previos
        notifyListeners();

        return userData;
      }

      return null;
    } catch (e) {
      print('Error en loginWithEmailOrUsername: $e');
      _errorMessage = 'Error al iniciar sesión';
      notifyListeners();
      return null;
    }
  }

  void getObscureText() {
    obscureText == true ? obscureText = false : obscureText = true;
    notifyListeners();
  }

  //SALIR DE LA APP
  Future<void> logoutApp() async {
    try {
      // Limpiar Google Sign-In
      await _googleSignIn.signOut();
      // Limpiar Firebase Auth
      await _auth.signOut();

      authStatus = AuthStatus.notAuthenticated;
      isLoggedIn = false;
      _errorMessage = null;
      notifyListeners();

      // Limpiar almacenamiento local
      await LocalStorage().deleteIsSignedIn();
      await LocalStorage().setIsLoggedIn(false);
      await LocalStorage().clear();
    } catch (e) {
      print('Error en logout: $e');
    }
  }

  //PARA OBTENER LOS DATOS DEL USUARIO
  Future<dynamic> getUserData(String email) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs[0].data();
        return userData;
      }

      return null;
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  // Método corregido para inicio de sesión con Google
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
      Map<String, dynamic> userData = {};
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
            'verificado':
                true, // Los usuarios de Google se consideran verificados
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

  // Método para limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
