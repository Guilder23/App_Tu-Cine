// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:peliculas/src/pages/inicio_page.dart';
import 'package:peliculas/src/providers/auth_provider_simple.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/utils_snackbar.dart';
import 'package:peliculas/src/widgets/input_decoration_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:provider/provider.dart';

class LoginSimplePage extends StatefulWidget {
  const LoginSimplePage({Key? key}) : super(key: key);

  @override
  State<LoginSimplePage> createState() => _LoginSimplePageState();
}

class _LoginSimplePageState extends State<LoginSimplePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers para los campos del formulario
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variables de estado
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authProvider = Provider.of<AuthProviderSimple>(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/peli2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: isDarkMode
                    ? AppColors.darkColor.withOpacity(0.8)
                    : Colors.white.withOpacity(0.8),
                elevation: 8.0,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: authProvider.isLoading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20),
                            CircularProgressIndicator(
                              color: isDarkMode
                                  ? AppColors.acentColor
                                  : AppColors.darkAcentsColor,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Iniciando sesión...',
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'INICIAR SESIÓN',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? AppColors.acentColor
                                      : AppColors.darkAcentsColor,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Logo o Imagen (opcional)
                              Image.asset(
                                'assets/icons/logo.png',
                                height: 80,
                                width: 80,
                              ),
                              const SizedBox(height: 24),

                              // Campo: Correo electrónico
                              InputDecorationWidget(
                                color: isDarkMode
                                    ? AppColors.acentColor
                                    : AppColors.darkAcentsColor,
                                hintText: "correo@ejemplo.com",
                                labelText: "Correo electrónico",
                                prefixIcon: const Icon(Icons.email),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu correo';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Campo: Contraseña
                              InputDecorationWidget(
                                color: isDarkMode
                                    ? AppColors.acentColor
                                    : AppColors.darkAcentsColor,
                                hintText: "Contraseña",
                                labelText: "Contraseña",
                                prefixIcon: const Icon(Icons.lock),
                                controller: _passwordController,
                                obscureText: _obscureText,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingresa tu contraseña';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Botón de inicio de sesión
                              MaterialButtomWidget(
                                title: "INICIAR SESIÓN",
                                color: isDarkMode
                                    ? AppColors.acentColor
                                    : AppColors.darkAcentsColor,
                                onPressed: () => _loginUser(context),
                              ),
                              const SizedBox(height: 20),

                              // Link para ir a Registro
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "¿No tienes cuenta? ",
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context)
                                        .pushReplacementNamed(
                                            '/register_simple'),
                                    child: Text(
                                      "Regístrate",
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? AppColors.acentColor
                                            : AppColors.darkAcentsColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método para iniciar sesión
  Future<void> _loginUser(BuildContext context) async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider =
        Provider.of<AuthProviderSimple>(context, listen: false);

    // Intentar login
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) {
      // Obtener datos del usuario después del login exitoso
      final userData = await authProvider.getCurrentUserData();

      if (userData != null) {
        // Verificar el rol del usuario para redirigir adecuadamente
        final String? role = userData['role'] ?? userData['rol'];

        // Mostrar mensaje según el tipo de usuario
        if (role?.toLowerCase() == 'admin') {
          showSnackbar(context, '✅ ¡Bienvenido Administrador!');
        } else {
          showSnackbar(context, '✅ ¡Sesión iniciada correctamente!');
        }

        // Siempre redirigimos a InicioPage, pero la interfaz se adaptará según el rol
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InicioPage(userData: userData),
          ),
        );
      } else {
        // Si no se pudieron obtener los datos, navegar a la ruta normal
        showSnackbar(context,
            '⚠️ Advertencia: No se pudieron cargar todos los datos del perfil');
        Navigator.pushReplacementNamed(context, '/inicio');
      }
    } else {
      showSnackbar(context, '❌ ${authProvider.errorMessage}');
    }
  }
}
