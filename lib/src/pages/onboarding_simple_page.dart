// ignore_for_file: library_private_types_in_public_api

import 'package:peliculas/src/routes/routes.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

class OnBoardingSimplePage extends StatefulWidget {
  const OnBoardingSimplePage({super.key});

  @override
  _OnBoardingSimplePageState createState() => _OnBoardingSimplePageState();
}

class _OnBoardingSimplePageState extends State<OnBoardingSimplePage> {
  int page = 0;
  final LiquidController liquidController = LiquidController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    checkPreviousSession();
  }

  void checkPreviousSession() async {
    setState(() {
      isLoading = true;
    });

    // Para desarrollo, siempre vamos al login
    await Future.delayed(const Duration(seconds: 2)); // Simular carga

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressWidget(
                text: "Cargando...",
              ),
            )
          : Stack(
              children: [
                LiquidSwipe(
                  liquidController: liquidController,
                  waveType: WaveType.liquidReveal,
                  enableLoop: false,
                  enableSideReveal: true,
                  preferDragFromRevealedArea: true,
                  ignoreUserGestureWhileAnimating: true,
                  fullTransitionValue: 500,
                  onPageChangeCallback: (index) => setState(() => page = index),
                  slideIconWidget: page == 2
                      ? const SizedBox.shrink()
                      : const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 30, color: AppColors.text),
                  pages: [
                    buildPage(
                      "Bienvenido a\nTu Cine",
                      "Descubre y disfruta de las mejores películas. ¡Compra tus entradas y vive la experiencia en el cine!",
                      "assets/images/peli1.jpg",
                    ),
                    buildPage(
                      "Explora",
                      "Explora entre miles de películas de diferentes géneros. Encuentra la película perfecta para tu próxima salida al cine.",
                      "assets/images/peli2.jpg",
                    ),
                    buildPage(
                      "Guarda tus favoritos",
                      "Guarda tus películas favoritas y míralas cuando quieras. ¡Compra tus entradas online y ahorra tiempo en la cola del cine!",
                      "assets/images/peli3.jpg",
                    ),
                  ],
                ),
                if (page != 0)
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: MaterialButton(
                      color: AppColors.greenColor2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Atrás",
                            style: TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontFamily: "CB")),
                      ),
                      onPressed: () => liquidController.animateToPage(
                          page: page - 1, duration: 350),
                    ),
                  ),
                if (page == 2)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: MaterialButton(
                      color: AppColors.acentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Continuar",
                          style: TextStyle(
                              fontSize: 16,
                              color: AppColors.text,
                              fontFamily: "CB"),
                        ),
                      ),
                      // Navegar a la nueva página de login simplificada
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(Routes.loginSimple),
                    ),
                  ),
                Positioned(
                  top: 25,
                  right: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: MaterialButton(
                      color: AppColors.acentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Omitir",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.text,
                          fontFamily: "CB",
                        ),
                      ),
                      // Navegar a la nueva página de login simplificada
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(Routes.loginSimple),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildPage(String title, String subtitle, String imagePath) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              stops: const [0.6, 1.0],
              colors: [
                AppColors.darkColor.withOpacity(0.85),
                AppColors.darkColor.withOpacity(0.0),
              ],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 100.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontFamily: "CB",
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: "CM",
                      color: AppColors.text,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
