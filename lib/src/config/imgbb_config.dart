// CONFIGURACIÓN DE IMGBB
// ======================
//
// INSTRUCCIONES PARA CONFIGURAR IMGBB:
//
// 1. Regístrate GRATIS en: https://api.imgbb.com/
// 2. Inicia sesión y ve a tu panel
// 3. Copia tu API Key
// 4. Reemplaza "TU_API_KEY_AQUI" con tu API Key real
//
// EJEMPLO:
// static const String API_KEY = "a1b2c3d4e5f6789"; // Tu API key real
//
// NOTA: ImgBB es completamente GRATIS sin límites de almacenamiento

class ImgBBConfig {
  // 🔑 CAMBIA ESTA LÍNEA CON TU API KEY
  static const String API_KEY = "a1da1aea152b5a8ddc59128700a3bbb6";

  // URL base de la API de ImgBB
  static const String BASE_URL = "https://api.imgbb.com/1/upload";

  // Verificar si está configurado
  static bool get isConfigured =>
      API_KEY != "TU_API_KEY_AQUI" && API_KEY.isNotEmpty;

  // Obtener mensaje de estado
  static String get statusMessage {
    if (isConfigured) {
      return "✅ ImgBB configurado correctamente";
    } else {
      return "⚠️ Necesitas configurar tu API Key de ImgBB";
    }
  }
}

/*
PASOS DETALLADOS PARA OBTENER TU API KEY:

1. Ve a: https://api.imgbb.com/
2. Haz clic en "Get API Key"
3. Regístrate con tu email o usa Google/GitHub
4. Una vez dentro, verás tu API Key
5. Cópiala y pégala arriba reemplazando "TU_API_KEY_AQUI"

¡Eso es todo! ImgBB es gratis y no requiere tarjeta de crédito.
*/
