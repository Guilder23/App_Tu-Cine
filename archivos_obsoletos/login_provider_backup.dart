// ignore_for_file: unused_local_variable

import 'package:peliculas/src/services/local_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { notAuthenticated, checking, authenticated }

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
    String emailOrUsername,
    String password,
  ) async {
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
    await _auth.signOut();
    authStatus = AuthStatus.notAuthenticated;
    isLoggedIn = false;
    notifyListeners();
    // Elimina la clave 'is_signedin' de la caja usando LocalStorage
    await LocalStorage().deleteIsSignedIn();
    //cambiar a false el valor de isLoggedIn
    await LocalStorage().setIsLoggedIn(false);
    //limpiar la caja
    await LocalStorage().clear();
  }

  //PARA OBTENER LOS DATOS DEL USUARIO
  Future<dynamic> getUserData(String email) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final userData = snapshot.docs[0].data();
      return userData;
    }

    return null;
  }

  //Inicio de sesión con Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Iniciando proceso de Google Sign In...');

      // Limpiar sesiones anteriores
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Intentar login con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Usuario canceló el inicio de sesión con Google');
        _errorMessage = 'Login cancelado por el usuario';
        notifyListeners();
        return null;
      }

      print('Usuario seleccionado: ${googleUser.email}');

      // Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('No se pudieron obtener los tokens de autenticación');
        _errorMessage = 'Error al obtener tokens de Google';
        notifyListeners();
        return null;
      }

      // Crear credencial de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );

      // Autenticar con Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        print('Usuario autenticado con Firebase: ${user.email}');

        // Verificar si el usuario existe en Firestore
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        Map<String, dynamic> userData;

        if (!userDoc.exists) {
          print('Creando nuevo usuario en Firestore');
          // Crear usuario con datos de Google
          userData = {
            'id': user.uid,
            'username': user.displayName ?? 'GoogleUser',
            'username_lowercase':
                (user.displayName ?? 'googleuser').toLowerCase(),
            'email': user.email ?? '',
            'imageUser': user.photoURL ?? 'assets/images/avatar3.png',
            'biografia': '¡Hola! Soy nuevo en CodeWarriors',
            'birth': '',
            'edad': '0',
            'createdAt': DateTime.now().toString(),
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
            'token': '',
            'departamento': '',
            'ciudad': '',
            'telefono': '',
          };

          await _firestore.collection('users').doc(user.uid).set(userData);
          print('Usuario creado en Firestore');
        } else {
          userData = userDoc.data() as Map<String, dynamic>;
          print('Usuario existente encontrado en Firestore');
        }

        // Actualizar estado local
        await LocalStorage().setIsSignedIn(true);
        await LocalStorage().setIsLoggedIn(true);
        await LocalStorage().saveUserData(userData['email'], '');

        authStatus = AuthStatus.authenticated;
        isLoggedIn = true;
        notifyListeners();

        print('Proceso de inicio de sesión completado exitosamente');
        return userData;
      }

      _errorMessage = 'No se pudo obtener información del usuario';
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      print(
        'Error de Firebase Auth en Google Sign-In: ${e.code} - ${e.message}',
      );
      switch (e.code) {
        case 'account-exists-with-different-credential':
          _errorMessage =
              'Ya existe una cuenta con este email usando otro método de login';
          break;
        case 'invalid-credential':
          _errorMessage = 'Las credenciales de Google no son válidas';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'El login con Google no está habilitado';
          break;
        default:
          _errorMessage = 'Error de autenticación: ${e.message}';
      }
      notifyListeners();
      return null;
    } catch (e) {
      print('Error general en signInWithGoogle: $e');
      // Manejar errores específicos conocidos
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        _errorMessage =
            'Error de compatibilidad con Google Sign-In. Usa email/contraseña mientras solucionamos este problema.';
      } else {
        _errorMessage = 'Error inesperado: ${e.toString()}';
      }
      notifyListeners();
      return null;
    }
  }
}
