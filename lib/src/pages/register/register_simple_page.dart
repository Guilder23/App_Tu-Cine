// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:peliculas/src/providers/auth_provider_simple.dart';
import 'package:peliculas/src/services/admin_service.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/utils_snackbar.dart';
import 'package:peliculas/src/widgets/input_decoration_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:provider/provider.dart';

class RegisterSimplePage extends StatefulWidget {
  const RegisterSimplePage({Key? key}) : super(key: key);

  @override
  State<RegisterSimplePage> createState() => _RegisterSimplePageState();
}

class _RegisterSimplePageState extends State<RegisterSimplePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  File? _profileImage;

  bool _obscureText = true;
  DateTime? _birthdate;
  bool _hasAdminUser = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkIfAdminExists();
  }

  // Verificar si ya existe un administrador
  Future<void> _checkIfAdminExists() async {
    try {
      final hasAdmin = await AdminService.hasAdminUser();
      if (mounted) {
        setState(() {
          _hasAdminUser = hasAdmin;
          _isCheckingAdmin = false;
        });
      }
    } catch (e) {
      print('Error al verificar admin: $e');
      if (mounted) {
        setState(() {
          _hasAdminUser = false;
          _isCheckingAdmin = false;
        });
      }
    }
  }

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
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(), // Añadir física de rebote para mejor UX
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width * 0.9,
                    // Sin limitar altura máxima para permitir scroll
                  ),
                  child: Card(
                    color: isDarkMode
                        ? AppColors.darkColor.withOpacity(0.8)
                        : Colors.white.withOpacity(0.8),
                    elevation: 8.0,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20.0), // Reducido de 24 a 20
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
                                  'Creando tu cuenta...',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
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
                                    'REGISTRO',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? AppColors.acentColor
                                          : AppColors.darkAcentsColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Botón secreto para crear administrador (solo si no existe uno)
                                  if (_isCheckingAdmin)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.orange
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Verificando admin...',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange
                                                      .withOpacity(0.7),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (!_hasAdminUser)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        TextButton.icon(
                                          onPressed: _fillAdminCredentials,
                                          icon: const Icon(
                                            Icons.admin_panel_settings,
                                            size: 18,
                                            color: Colors.orange,
                                          ),
                                          label: const Text(
                                            'Crear Admin',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            backgroundColor:
                                                Colors.orange.withOpacity(0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 14,
                                                color: Colors.green
                                                    .withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Admin ya configurado',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 16),

                                  // Imagen de perfil
                                  InkWell(
                                    onTap: _selectImage,
                                    child: Container(
                                      height: 120,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDarkMode
                                            ? AppColors.darkColor
                                            : AppColors.acentColor
                                                .withOpacity(0.2),
                                      ),
                                      child: _profileImage != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                              child: Image.file(
                                                _profileImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: isDarkMode
                                                  ? AppColors.acentColor
                                                  : AppColors.darkAcentsColor,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca para añadir foto',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? AppColors.acentColor
                                          : AppColors.darkAcentsColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Campo: Nombre de usuario
                                  InputDecorationWidget(
                                    color: isDarkMode
                                        ? AppColors.acentColor
                                        : AppColors.darkAcentsColor,
                                    hintText: "Nombre de usuario",
                                    labelText: "Usuario",
                                    prefixIcon: const Icon(Icons.person),
                                    controller: _usernameController,
                                    keyboardType: TextInputType.name,
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
                                  const SizedBox(height: 16),

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
                                      // Validar formato de email
                                      final emailRegExp = RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                      if (!emailRegExp.hasMatch(value)) {
                                        return 'Ingresa un correo válido';
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
                                        return 'Por favor ingresa una contraseña';
                                      }
                                      if (value.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Campo: Fecha de nacimiento
                                  InputDecorationWidget(
                                    color: isDarkMode
                                        ? AppColors.acentColor
                                        : AppColors.darkAcentsColor,
                                    hintText: "DD/MM/AAAA",
                                    labelText: "Fecha de nacimiento",
                                    prefixIcon:
                                        const Icon(Icons.calendar_today),
                                    controller: _birthdateController,
                                    readOnly: true,
                                    onTap: () => _selectDate(context),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor selecciona tu fecha de nacimiento';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Botón de registro
                                  MaterialButtomWidget(
                                    title: "CREAR CUENTA",
                                    color: isDarkMode
                                        ? AppColors.acentColor
                                        : AppColors.darkAcentsColor,
                                    onPressed: () => _registerUser(context),
                                  ),
                                  const SizedBox(height: 20),

                                  // Link para ir a Login
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "¿Ya tienes cuenta? ",
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black87,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.of(context)
                                            .pushReplacementNamed(
                                                '/login_simple'),
                                        child: Text(
                                          "Inicia sesión",
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
        ),
      ),
    );
  }

  // Método para seleccionar fecha de nacimiento
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(now.year - 100, 1, 1); // 100 años atrás
    final DateTime lastDate = DateTime(now.year - 12, 12, 31); // Mínimo 12 años

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != _birthdate) {
      setState(() {
        _birthdate = picked;
        _birthdateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Método para seleccionar una imagen de perfil
  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  // Método para verificar si es administrador
  bool _isAdminCredentials() {
    return _emailController.text.trim().toLowerCase() == 'admin@gmail.com' &&
        _passwordController.text == 'Admin123' &&
        _usernameController.text.trim() == 'Admin';
  }

  // Método para autocompletar credenciales de administrador
  void _fillAdminCredentials() {
    setState(() {
      _usernameController.text = 'Admin';
      _emailController.text = 'admin@gmail.com';
      _passwordController.text = 'Admin123';
      _birthdate = DateTime(1998, 9, 1);
      _birthdateController.text = '01/09/1998';
    });

    // Mostrar mensaje informativo
    showSnackbar(context, '🔑 Credenciales de administrador cargadas');
  }

  // Método para registrar un usuario
  Future<void> _registerUser(BuildContext context) async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verificar fecha de nacimiento
    if (_birthdate == null) {
      showSnackbar(context, ' Por favor selecciona tu fecha de nacimiento');
      return;
    }

    final authProvider =
        Provider.of<AuthProviderSimple>(context, listen: false);

    // Verificar si son credenciales de administrador
    if (_isAdminCredentials()) {
      // Establecer fecha de nacimiento específica para admin si no se seleccionó otra
      if (_birthdateController.text == '01/09/1998' || _birthdate == null) {
        _birthdate = DateTime(1998, 9, 1);
      }

      showSnackbar(context, '🔑 Creando cuenta de administrador...');
    }

    // Intentar registro
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      birthdate: _birthdate!,
      profileImage: _profileImage,
      isAdmin: _isAdminCredentials(), // Pasar flag de administrador
    );

    if (success && mounted) {
      if (_isAdminCredentials()) {
        // Actualizar estado para ocultar el botón de crear admin
        setState(() {
          _hasAdminUser = true;
        });
        showSnackbar(context,
            ' ✅ ¡Cuenta de administrador creada exitosamente! Tienes permisos especiales.');
      } else {
        showSnackbar(context,
            ' ¡Cuenta creada exitosamente! Ahora puedes iniciar sesión con tus credenciales.');
      }
      Navigator.pushReplacementNamed(context, '/login_simple');
    } else {
      showSnackbar(context, ' ${authProvider.errorMessage}');
    }
  }
}
