import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:peliculas/src/config/imgbb_config.dart';

class ImgBBService {
  // Usar configuración centralizada
  static String get _apiKey => ImgBBConfig.API_KEY;
  static String get _baseUrl => ImgBBConfig.BASE_URL;

  /// Sube una imagen a ImgBB y retorna la URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Verificar que el archivo existe
      if (!imageFile.existsSync()) {
        print('Error: El archivo no existe');
        return null;
      }

      // Verificar configuración
      if (!isConfigured()) {
        print('❌ ImgBB no está configurado');
        return null;
      }

      // Leer la imagen como bytes y convertir a base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Preparar la petición
      var uri = Uri.parse(_baseUrl);
      var request = http.MultipartRequest('POST', uri);

      // Agregar parámetros
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;

      // Opcional: agregar un nombre único para la imagen
      String fileName = 'producto_${DateTime.now().millisecondsSinceEpoch}';
      request.fields['name'] = fileName;

      print('📤 Subiendo imagen a ImgBB...');

      // Enviar la petición
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseBody);

        if (jsonResponse['success'] == true) {
          String imageUrl = jsonResponse['data']['url'];
          print('✅ Imagen subida exitosamente: $imageUrl');
          return imageUrl;
        } else {
          print('❌ Error en la respuesta: ${jsonResponse['error']['message']}');
          return null;
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('Respuesta: $responseBody');
        return null;
      }
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      return null;
    }
  }

  /// Sube una imagen desde XFile (para image_picker)
  static Future<String?> uploadXFile(XFile imageFile) async {
    try {
      File file = File(imageFile.path);
      return await uploadImage(file);
    } catch (e) {
      print('❌ Error al convertir XFile: $e');
      return null;
    }
  }

  /// Verifica si el servicio está configurado correctamente
  static bool isConfigured() {
    return ImgBBConfig.isConfigured;
  }

  /// Obtiene información sobre la configuración
  static String getConfigInfo() {
    return ImgBBConfig.statusMessage;
  }

  /// Obtiene información de ayuda para configurar
  static String getHelpInfo() {
    return """
🔧 CONFIGURAR IMGBB:

1. Ve a: https://api.imgbb.com/
2. Regístrate gratis (sin tarjeta)
3. Obtén tu API Key
4. Copia la API Key
5. Ve al archivo: lib/src/config/imgbb_config.dart
6. Reemplaza "TU_API_KEY_AQUI" con tu API Key

¡Es completamente gratis y sin límites!
""";
  }

  /// Método de prueba para verificar la configuración
  static Future<bool> testConfiguration() async {
    if (!isConfigured()) {
      print('⚠️ ImgBB no está configurado');
      return false;
    }

    try {
      // Hacer una petición de prueba (sin imagen)
      print('🧪 Probando configuración de ImgBB...');

      var uri = Uri.parse(_baseUrl);
      var response = await http.post(
        uri,
        body: {
          'key': _apiKey,
          'image':
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', // 1x1 pixel transparente
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          print('✅ Configuración de ImgBB funcionando correctamente');
          return true;
        }
      }

      print('❌ Error en la configuración de ImgBB');
      return false;
    } catch (e) {
      print('❌ Error al probar configuración: $e');
      return false;
    }
  }
}
