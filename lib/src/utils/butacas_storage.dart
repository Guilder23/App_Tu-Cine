import 'package:shared_preferences/shared_preferences.dart';

class ButacasStorage {
  /// Guardar butacas ocupadas localmente para una función específica
  static Future<void> guardarButacasOcupadas(
    String movieId,
    String day,
    String time,
    List<int> butacas,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String funcionKey = '${movieId}_${day}_$time';
    final List<String> seatStrings =
        butacas.map((seat) => seat.toString()).toList();
    await prefs.setStringList('butacas_ocupadas_$funcionKey', seatStrings);
  }

  /// Obtener butacas ocupadas localmente para una función específica
  static Future<List<int>> obtenerButacasOcupadas(
    String movieId,
    String day,
    String time,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String funcionKey = '${movieId}_${day}_$time';
    final List<String>? seatStrings =
        prefs.getStringList('butacas_ocupadas_$funcionKey');
    return seatStrings?.map((seat) => int.tryParse(seat) ?? 0).toList() ?? [];
  }

  /// Limpiar todas las butacas guardadas localmente
  static Future<void> limpiarTodasLasButacas() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith('butacas_ocupadas_')) {
        await prefs.remove(key);
      }
    }
  }

  /// Agregar butacas a las ya existentes para una función
  static Future<void> agregarButacasOcupadas(
    String movieId,
    String day,
    String time,
    List<int> nuevasButacas,
  ) async {
    final butacasExistentes = await obtenerButacasOcupadas(movieId, day, time);
    final todasLasButacas = {...butacasExistentes, ...nuevasButacas}.toList();
    await guardarButacasOcupadas(movieId, day, time, todasLasButacas);
  }
}
