// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:peliculas/src/pages/login/login_page.dart';
import 'package:peliculas/src/providers/login_provider.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/utils_snackbar.dart';
import 'package:peliculas/src/validators/validator.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/input_decoration_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  bool obscureText = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final loginProvider = Provider.of<LoginProvider>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/cine1.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                'REGISTRO',
                style: TextStyle(
                  color: ColoresApp.colorPrimario,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      // Campo de nombre de usuario
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecorations.authInputDecoration(
                          hintText: 'Nombre de usuario',
                          labelText: 'Nombre de usuario',
                          prefixIcon: Icons.person,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre de usuario';
                          }
                          if (value.length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo de email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecorations.authInputDecoration(
                          hintText: 'correo@email.com',
                          labelText: 'Correo electrónico',
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo electrónico';
                          }
                          if (!Validator.isEmail(value)) {
                            return 'Ingresa un correo electrónico válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Campo de contraseña
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscureText,
                        decoration: InputDecorations.authInputDecoration(
                          hintText: '********',
                          labelText: 'Contraseña',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureText = !obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // Botón de registro
                      isLoading
                          ? const CircularProgressWidget(
                              text: 'Procesando registro...',
                            )
                          : MaterialButton(
                              text: 'Registrarse',
                              color: ColoresApp.colorGeneral,
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  final result =
                                      await loginProvider.registerWithEmail(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                    usernameController.text.trim(),
                                  );

                                  if (result != null && mounted) {
                                    showSnackbar(
                                      context,
                                      'Usuario registrado con éxito. Se ha enviado un correo de verificación.',
                                      type: SnackBarType.success,
                                    );

                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                    );
                                  } else {
                                    showSnackbar(
                                      context,
                                      loginProvider.errorMessage,
                                      type: SnackBarType.error,
                                    );
                                  }
                                } catch (e) {
                                  showSnackbar(
                                    context,
                                    'Error al registrar usuario: $e',
                                    type: SnackBarType.error,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Enlace para ir a login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes una cuenta?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Inicia sesión',
                      style: TextStyle(
                        color: ColoresApp.colorGeneral,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
