import 'dart:io';
import 'package:peliculas/src/providers/theme_controller.dart';
import 'package:peliculas/src/providers/auth_provider_simple.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/logout_widget.dart';
import 'package:peliculas/src/utils/utils_snackbar.dart';
import 'package:peliculas/src/services/imgbb_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final dynamic userData;
  const ProfilePage({Key? key, this.userData}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUpdatingImage = false;
  String _profileImageCacheKey =
      ''; // Clave para forzar actualización de imagen

  @override
  void initState() {
    super.initState();
    _profileImageCacheKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProviderSimple>(
          builder: (context, authProvider, child) {
            // Obtener datos directamente del provider usando un FutureBuilder que se reconstruye solo cuando sea necesario
            return FutureBuilder<Map<String, dynamic>?>(
              // Usar una clave que solo cambie cuando la imagen se actualice
              key: ValueKey('profile_$_profileImageCacheKey'),
              future: authProvider.getCurrentUserData(),
              builder: (context, snapshot) {
                // Si está cargando y no tenemos datos previos, mostrar indicador de carga
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.red,
                    ),
                  );
                }

                // Usar datos del snapshot o fallback si hay error
                final userData =
                    snapshot.hasData ? snapshot.data : widget.userData;

                return _buildProfileContent(userData, isDarkMode);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(dynamic userData, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontFamily: "CB",
                  color: isDarkMode ? AppColors.text : AppColors.darkColor,
                ),
              ),
            ),
            const Spacer(),
            const LogoutWidget(),
            const SizedBox(width: 10),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDarkMode ? AppColors.text : AppColors.acentColor,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: (userData != null && userData['profile_image'] != null)
                      ? FadeInImage(
                          placeholder:
                              const AssetImage('assets/gif/loading.gif'),
                          image: NetworkImage(userData['profile_image']),
                          imageErrorBuilder: (context, error, stackTrace) =>
                              const Image(
                            image: AssetImage('assets/images/avatar3.png'),
                            fit: BoxFit.cover,
                          ),
                          fit: BoxFit.cover,
                        )
                      : const Image(
                          image: AssetImage('assets/images/avatar3.png'),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData != null && userData['username'] != null
                          ? userData['username']
                          : 'Usuario',
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: "CB",
                      ),
                    ),
                    Text(
                      userData != null && userData['email'] != null
                          ? userData['email']
                          : 'Sin correo',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.red,
                        fontFamily: "CM",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _isUpdatingImage ? null : _editProfileImage,
                icon: _isUpdatingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.red),
                        ),
                      )
                    : const Icon(
                        Icons.edit,
                        color: AppColors.red,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            "Preferencias",
            style: TextStyle(
              fontSize: 20,
              fontFamily: "CB",
              color: isDarkMode ? AppColors.text : AppColors.darkColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListTile(
            leading: isDarkMode
                ? Image.asset(
                    'assets/icons/noche2.png',
                    height: 30,
                    color: isDarkMode ? AppColors.text : AppColors.darkColor,
                  )
                : Image.asset(
                    'assets/icons/dia1.png',
                    height: 30,
                    color: isDarkMode ? AppColors.text : AppColors.darkColor,
                  ),
            title: Text(
              isDarkMode ? "Modo Oscuro" : "Modo Claro",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.text : AppColors.darkColor,
              ),
            ),
            trailing: Consumer<ThemeController>(
              builder: (_, controller, __) => Switch(
                value: controller.isDarkMode,
                onChanged: (value) {
                  controller.toggle();
                },
                activeColor: AppColors.text,
                activeTrackColor: AppColors.red,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListTile(
            leading: Icon(
              Icons.notifications,
              color: isDarkMode ? AppColors.text : AppColors.darkColor,
            ),
            title: Text(
              "Notificaciones",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.text : AppColors.darkColor,
              ),
            ),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.text,
              activeTrackColor: AppColors.red,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListTile(
            leading: Icon(
              Icons.language,
              color: isDarkMode ? AppColors.text : AppColors.darkColor,
            ),
            title: Text(
              "Idioma",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.text : AppColors.darkColor,
              ),
            ),
            trailing: Text(
              "Español",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.text : AppColors.darkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Método para editar imagen de perfil
  Future<void> _editProfileImage() async {
    await _showImageSourceDialog();
  }

  // Método para mostrar opciones de selección de imagen
  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isDarkMode = context.isDarkMode;
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkColor : Colors.white,
          title: Text(
            'Cambiar imagen de perfil',
            style: TextStyle(
              color: isDarkMode ? AppColors.text : AppColors.darkColor,
              fontFamily: "CB",
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.red),
                title: Text(
                  'Galería',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.text : AppColors.darkColor,
                    fontFamily: "CM",
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.red),
                title: Text(
                  'Cámara',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.text : AppColors.darkColor,
                    fontFamily: "CM",
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _selectImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Seleccionar imagen desde galería
  Future<void> _selectImageFromGallery() async {
    await _updateProfileImage(ImageSource.gallery);
  }

  // Seleccionar imagen desde cámara
  Future<void> _selectImageFromCamera() async {
    await _updateProfileImage(ImageSource.camera);
  }

  // Actualizar imagen de perfil
  Future<void> _updateProfileImage(ImageSource source) async {
    try {
      setState(() {
        _isUpdatingImage = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // Subir imagen a ImgBB
        final File imageFile = File(pickedImage.path);
        final String? imageUrl = await ImgBBService.uploadImage(imageFile);

        if (imageUrl != null) {
          // Usar AuthProvider para actualizar el perfil globalmente
          final authProvider =
              Provider.of<AuthProviderSimple>(context, listen: false);
          final success = await authProvider.updateUserProfile(
            profileImage: imageUrl,
          );
          if (success) {
            // Actualizar la clave para forzar reconstrucción del FutureBuilder
            setState(() {
              _profileImageCacheKey =
                  DateTime.now().millisecondsSinceEpoch.toString();
            });

            // El Consumer se actualizará automáticamente cuando se llame notifyListeners()
            showSnackbar(
                context, '✅ Imagen de perfil actualizada correctamente');
          } else {
            showSnackbar(context, '❌ Error al actualizar el perfil');
          }
        } else {
          showSnackbar(context, '❌ Error al subir la imagen');
        }
      }
    } catch (e) {
      print('Error al actualizar imagen: $e');
      showSnackbar(context, '❌ Error al actualizar la imagen');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingImage = false;
        });
      }
    }
  }
}
