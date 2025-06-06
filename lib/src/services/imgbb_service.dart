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

      print('Subiendo imagen a ImgBB...');

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

  /// Método de prueba con imagen de ejemplo
  static Future<void> testUpload() async {
    try {
      // Este método es solo para pruebas
      print('🧪 Método de prueba - implementar con imagen real');
    } catch (e) {
      print('❌ Error en test: $e');
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
}
