import 'package:peliculas/src/utils/export.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() async {
  // Esto garantiza que Flutter esté inicializado antes de cualquier otra operación
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración regional
  Intl.defaultLocale = 'es';
  await initializeDateFormatting();

  // Inicializar Firebase y el servicio de notificaciones
  await PushNotificationService.initializeApp();

  // Inicializar almacenamiento local
  await LocalStorage().init();
  final isLoggedIn = LocalStorage().getIsLoggedIn();

  // Bloquear orientación de la pantalla
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // Inyectar dependencias
  await injectDependencies();

  // Iniciar la aplicación
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Nuevo provider de autenticación simplificado
        ChangeNotifierProvider(
            lazy: false, create: (_) => AuthProviderSimple()),
        ChangeNotifierProvider(lazy: false, create: (_) => MoviesProvider()),
      ],
      child: ChangeNotifierProvider(
        create: (_) => ThemeController(),
        child: Consumer<ThemeController>(
          builder: (_, controller, __) => MaterialApp(
            // navigatorKey: NavigationServices.navigatorKey,
            navigatorObservers: [OrientationResetObserver()],
            scaffoldMessengerKey: NotificationService.messengerKey,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
              );
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('es', 'ES'),
            ],
            debugShowCheckedModeBanner: false,
            themeMode: controller.themeMode,
            theme: controller.lightTheme,
            darkTheme: controller.darkTheme,
            initialRoute: Routes.onboard, // Empezamos con el onboarding
            routes: appRoutes,
          ),
        ),
      ),
    );
  }
}
