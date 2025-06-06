import 'package:peliculas/src/pages/inicio_page.dart';
import 'package:peliculas/src/pages/register/register_page.dart';
import 'package:peliculas/src/providers/login_provider.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/utils_snackbar.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/input_decoration_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailOrUserController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscureText = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void onFormSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);

      // Intentar login con email o username
      final userData = await loginProvider.loginWithEmailOrUsername(
        emailOrUserController.text.trim(),
        passwordController.text.trim(),
      );

      if (userData != null && mounted) {
        // Login exitoso, navegar a la página principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InicioPage(
              userData: userData,
            ),
          ),
        );
      } else {
        // Mostrar error
        if (mounted) {
          showSnackbar(context, loginProvider.errorMessage);
        }
      }
    } catch (e) {
      print('Error en inicio de sesión: $e');
      if (mounted) {
        showSnackbar(context, 'Error al iniciar sesión. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/peli3.jpg"),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.lightColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Login",
                          style: TextStyle(
                            color: AppColors.darkColor,
                            fontSize: 30,
                            fontFamily: "CB",
                          ),
                        ),
                        const SizedBox(height: 20),
                        InputDecorationWidget(
                          hintText: "Cine@gmail.com",
                          labelText: "Ingresa tu email o usuario",
                          suffixIcon: const Icon(
                            Icons.person,
                            color: AppColors.darkColor,
                          ),
                          controller: emailOrUserController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa un email o nombre de usuario';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        InputDecorationWidget(
                          hintText: "********",
                          labelText: "Ingresa tu contraseña",
                          maxLines: 1,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.darkColor,
                            ),
                          ),
                          controller: passwordController,
                          obscureText: obscureText,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La contraseña es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        isLoading
                            ? const CircularProgressWidget(text: "Validando..")
                            : MaterialButtomWidget(
                                title: "Iniciar sesión",
                                color: AppColors.darkColor,
                                onPressed: onFormSubmit,
                              ),
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Registrarse",
                            style: TextStyle(
                              color: AppColors.darkColor,
                              fontFamily: "CB",
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "O inicia sesión con:",
                          style: TextStyle(
                            color: AppColors.darkColor,
                            fontFamily: "CM",
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  final loginProvider =
                                      Provider.of<LoginProvider>(context,
                                          listen: false);
                                  final userData =
                                      await loginProvider.signInWithGoogle();

                                  if (userData != null && mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => InicioPage(
                                          userData: userData,
                                        ),
                                      ),
                                    );
                                  } else {
                                    if (mounted) {
                                      showSnackbar(context,
                                          'Error al iniciar sesión con Google');
                                    }
                                  }
                                } catch (e) {
                                  print('Error Google Sign-In: $e');
                                  if (mounted) {
                                    showSnackbar(context,
                                        'Error al iniciar sesión con Google');
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                              icon: Image.asset(
                                "assets/icons/google.png",
                                height: 40,
                                width: 40,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
