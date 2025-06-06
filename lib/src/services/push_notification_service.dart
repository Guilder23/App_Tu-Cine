import 'package:peliculas/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static String? token;

  static Future initializeApp() async {
    try {
      // Inicializar Firebase primero
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);

      // Solicitar permisos para notificaciones
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Obtener token
      token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Configurar manejadores de notificaciones si se necesita
      // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //   // Manejar notificaciones en primer plano
      // });
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }
}
