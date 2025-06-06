// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/services/imgbb_service.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/utils/export.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/input_decoration_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:peliculas/src/widgets/upload_image_user.dart';
import 'package:flutter/material.dart';

class AddProducto extends StatefulWidget {
  final dynamic userData;
  const AddProducto({Key? key, this.userData}) : super(key: key);

  @override
  State<AddProducto> createState() => _AddProductoState();
}

class _AddProductoState extends State<AddProducto> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameProductController = TextEditingController();
  final TextEditingController priceProductController = TextEditingController();
  File? image;
  bool isLoading = false;

  void selectedImage() async {
    image = await pickImageUser(context);
    setState(() {});
  }

  void subirProducto() async {
    final firestore = FirebaseFirestore.instance;

    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      //cerrar el teclado
      FocusScope.of(context).unfocus();

      String imageUrl = '';

      // 🆕 NUEVA IMPLEMENTACIÓN CON IMGBB
      if (image != null) {
        if (!ImgBBService.isConfigured()) {
          showSnackbar(context,
              "⚠️ ImgBB no está configurado. Contacta al administrador.");
          setState(() {
            isLoading = false;
          });
          return;
        }

        try {
          showSnackbar(context, "📤 Subiendo imagen...");

          // Subir imagen a ImgBB
          String? uploadedUrl = await ImgBBService.uploadImage(image!);

          if (uploadedUrl != null) {
            imageUrl = uploadedUrl;
            showSnackbar(context, "✅ Imagen subida exitosamente");
          } else {
            showSnackbar(context, "❌ Error al subir la imagen");
            setState(() {
              isLoading = false;
            });
            return;
          }
        } catch (e) {
          showSnackbar(context, "❌ Error al subir imagen: ${e.toString()}");
          setState(() {
            isLoading = false;
          });
          return;
        }
      } else {
        // Si no hay imagen, usar imagen por defecto
        imageUrl =
            'https://via.placeholder.com/400x300/cccccc/666666?text=Sin+Imagen';
      } //obtener la ref a la coleccion productos
      final ref = firestore.collection('productos');
      //obtener el id del documento
      final id = ref.doc().id;

      //fecha
      final date = DateTime.now();

      //convertir el precio a double
      final price = double.parse(priceProductController.text);

      // Crear el producto
      final datos = {
        "id": id,
        "created_at": date,
        "id_usuario": widget.userData['id'],
        "nombre": nameProductController.text,
        "precio": price,
        "imagen": imageUrl,
      };

      try {
        //subir el producto a la coleccion
        await ref.doc(id).set(datos);

        // Mostrar un SnackBar con un mensaje de éxito
        showSnackbar(context, "🎉 Producto agregado correctamente");
        setState(() {
          isLoading = false;
        });
        Navigator.pop(context);
      } catch (e) {
        // Mostrar un SnackBar con un mensaje de error
        showSnackbar(
            context, "❌ Error al agregar el producto: ${e.toString()}");
        setState(() {
          isLoading = false;
        });
      } finally {
        //subir producto
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;

    // Verificar configuración de ImgBB
    bool isImgBBConfigured = ImgBBService.isConfigured();
    String configStatus = ImgBBService.getConfigInfo();
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkColor : AppColors.acentColor,
        centerTitle: true,
        title: const Text(
          'Agregar Producto',
          style: TextStyle(
            color: AppColors.text,
            fontFamily: "CB",
          ),
        ),
      ),
      body: isLoading
          ? const CircularProgressWidget(text: "Agregando producto...")
          : SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // 🆕 INDICADOR DE ESTADO DE IMGBB
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isImgBBConfigured
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isImgBBConfigured
                                ? Colors.green
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isImgBBConfigured
                                  ? Icons.cloud_done
                                  : Icons.warning,
                              color: isImgBBConfigured
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                configStatus,
                                style: TextStyle(
                                  color: isImgBBConfigured
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                  fontFamily: "CM",
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      InkWell(
                        onTap: () {
                          selectedImage();
                        },
                        child: image == null
                            ? Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.acentColor
                                      : AppColors.darkAcentsColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: isDarkMode
                                      ? AppColors.darkColor
                                      : AppColors.acentColor,
                                  size: 50,
                                ),
                              )
                            : Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.acentColor
                                      : AppColors.darkAcentsColor,
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: FileImage(image!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      InputDecorationWidget(
                        color: isDarkMode
                            ? AppColors.acentColor
                            : AppColors.darkAcentsColor,
                        hintText: "Pipoca dulce",
                        labelText: "Nombre del producto",
                        suffixIcon: const Icon(Icons.add),
                        controller: nameProductController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Por favor ingrese el nombre del producto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      //precio
                      InputDecorationWidget(
                        color: isDarkMode
                            ? AppColors.acentColor
                            : AppColors.darkAcentsColor,
                        hintText: "Bs/ 5.00",
                        labelText: "Precio",
                        suffixIcon: const Icon(Icons.attach_money),
                        controller: priceProductController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Por favor ingrese el precio del producto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      MaterialButtomWidget(
                        title: "Agregar Producto",
                        color: isDarkMode
                            ? AppColors.acentColor
                            : AppColors.darkAcentsColor,
                        onPressed: subirProducto,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
