import 'package:peliculas/src/pages/boleteria/boleteria_page_fixed.dart';
import 'package:peliculas/src/pages/boleteria/detalle_compra_mejorado.dart';
import 'package:peliculas/src/pages/boleteria/payment_page_fixed.dart';
import 'package:peliculas/src/pages/boleteria/boleto_generado_page.dart';
import 'package:peliculas/src/pages/details_movie.dart';
import 'package:peliculas/src/pages/inicio_page.dart';
import 'package:peliculas/src/pages/login/login_simple_page.dart';
import 'package:peliculas/src/pages/onboarding_simple_page.dart';
import 'package:peliculas/src/pages/register/register_simple_page.dart';
import 'package:peliculas/src/routes/routes.dart';
import 'package:flutter/material.dart';

Map<String, Widget Function(BuildContext)> get appRoutes {
  return {
    Routes.onboard: (_) => const OnBoardingSimplePage(),
    Routes.loginSimple: (_) => const LoginSimplePage(),
    Routes.registerSimple: (_) => const RegisterSimplePage(),
    Routes.inicio: (context) {
      // Simplemente devuelve la página de inicio, la lógica de obtener userData
      // ya está implementada dentro de la página
      return const InicioPage();
    },
    Routes.details: (_) => const DetailsMoviePage(),
    Routes.boleteria: (_) => const BoleteriaPageFixed(),
    Routes.detalleCompra: (_) => const DetalleCompraMejorado(),
    Routes.payment: (_) => const PaymentPageFixed(),
    Routes.boletoGenerado: (_) => const BoletoGeneradoPage(),
  };
}
