import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Subir imagen de producto a Firebase Storage
  static Future<String?> uploadProductImage({
    required File imageFile,
    required String productName,
    String? productId,
  }) async {
    try {
      // Crear nombre único para la imagen
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = productId != null
          ? 'productos/${productId}_${productName.replaceAll(' ', '_')}.jpg'
          : 'productos/${timestamp}_${productName.replaceAll(' ', '_')}.jpg';

      // Referencia al archivo en Storage
      final Reference ref = _storage.ref().child(fileName);

      // Metadatos para optimización
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_by': 'admin',
          'upload_date': DateTime.now().toIso8601String(),
          'product_name': productName,
        },
      );

      // Subir archivo
      print('Subiendo imagen: $fileName');
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);

      // Obtener URL de descarga
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  /// Seleccionar imagen desde galería o cámara
  static Future<File?> pickProductImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await showDialog<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Seleccionar imagen',
              style: TextStyle(fontFamily: "CB"),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text(
                    'Galería',
                    style: TextStyle(fontFamily: "CM"),
                  ),
                  onTap: () async {
                    Navigator.pop(
                        context,
                        await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        ));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text(
                    'Cámara',
                    style: TextStyle(fontFamily: "CM"),
                  ),
                  onTap: () async {
                    Navigator.pop(
                        context,
                        await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                          maxWidth: 1024,
                          maxHeight: 1024,
                        ));
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontFamily: "CM"),
                ),
              ),
            ],
          );
        },
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      return null;
    }
  }

  /// Eliminar imagen de Firebase Storage
  static Future<bool> deleteProductImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Imagen eliminada exitosamente: $imageUrl');
      return true;
    } catch (e) {
      print('Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Obtener URL de imagen por defecto
  static String getDefaultProductImage() {
    return 'assets/images/noimage.png';
  }

  /// Validar si una URL es de Firebase Storage
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') ||
        url.contains('firebase.storage.app');
  }
}
