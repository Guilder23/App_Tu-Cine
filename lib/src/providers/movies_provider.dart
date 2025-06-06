import 'dart:convert';
import 'dart:math' as math;
import 'package:peliculas/src/models/actores_models.dart';
import 'package:peliculas/src/models/categoria_models.dart';
import 'package:peliculas/src/models/generos_models.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/models/now_playing_models.dart';
import 'package:peliculas/src/models/peliculas_proximas.dart';
import 'package:peliculas/src/models/populars_movies.dart';
import 'package:peliculas/src/models/similar_movies.dart';
import 'package:peliculas/src/models/top_valorados.dart';
import 'package:peliculas/src/models/trailer_models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MoviesProvider extends ChangeNotifier {
  final String _apiKey = '21477dd8ae24984ee6df0ca23f39e3ac';
  final String _baseUrl = 'api.themoviedb.org';
  final String _language = 'es-ES';

  List<Movie> _searchedMovies = [];
  List<Movie> get searchedMovies => _searchedMovies;

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];
  List<Movie> topRatedMovies = [];
  List<Movie> comingSoonMovies = [];

  int _popularPage = 0;
  int _comingSoonPage = 0;
  int _topRatedPage = 0;
  int _genrePage = 0;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Map<int, List<Cast>> movieCast = {};
  Map<int, List<Genre>> genres = {};
  Map<int, List<Video>> videoTrailer = {};
  Map<int, List<Movie>> similarMovies = {};
  List<Genre> genresList = [];

  MoviesProvider() {
    print('MoviesProvider Inicializado');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Iniciando carga de datos iniciales...');

      // Inicializar listas vacías antes de cargar
      onDisplayMovies = [];
      popularMovies = [];
      topRatedMovies = [];
      comingSoonMovies = [];

      // Cargar datos uno por uno para mejor diagnóstico
      print('Cargando películas en cartelera...');
      await _getNowPlayingMovies();

      print('Cargando películas populares...');
      await _getPopularMovies();

      print('Cargando películas mejor valoradas...');
      await _getTopRatedMovies();

      print('Cargando próximos estrenos...');
      await _getComingSoonMovies();

      print('Datos iniciales cargados correctamente');
      print('Películas en cartelera: ${onDisplayMovies.length}');
      print('Películas populares: ${popularMovies.length}');
      print('Películas mejor valoradas: ${topRatedMovies.length}');
      print('Próximos estrenos: ${comingSoonMovies.length}');
    } catch (e, stackTrace) {
      print('Error cargando datos iniciales: $e');
      print('Stack trace: $stackTrace');
      // Inicializar listas vacías en caso de error
      onDisplayMovies = [];
      popularMovies = [];
      topRatedMovies = [];
      comingSoonMovies = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> getJsonData(String endPoint, [int page = 1]) async {
    try {
      final url = Uri.https(_baseUrl, endPoint, {
        'api_key': _apiKey,
        'language': _language,
        'page': '$page',
      });

      print('Fetching URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Timeout al cargar datos de: $endPoint');
          throw Exception('Timeout al cargar datos');
        },
      );

      print('Response status for $endPoint: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('Respuesta vacía de la API para: $endPoint');
          return _getEmptyJsonResponse();
        }

        // Verificar que la respuesta sea JSON válido
        try {
          json.decode(response.body);
          return response.body;
        } catch (e) {
          print('Error al parsear JSON de la API para: $endPoint');
          print('Error: $e');
          return _getEmptyJsonResponse();
        }
      }

      print(
          'Error HTTP en $endPoint: ${response.statusCode} - ${response.body}');
      return _getEmptyJsonResponse();
    } catch (e) {
      print('Error en getJsonData para $endPoint: $e');
      return _getEmptyJsonResponse();
    }
  }

  String _getEmptyJsonResponse() {
    return '''
    {
      "page": 1,
      "results": [],
      "dates": {
        "maximum": "${DateTime.now().toIso8601String()}",
        "minimum": "${DateTime.now().toIso8601String()}"
      },
      "total_pages": 1,
      "total_results": 0
    }''';
  }

  Future<void> _getNowPlayingMovies() async {
    try {
      final jsonData = await getJsonData('3/movie/now_playing');
      final data = json.decode(jsonData);
      if (data != null && data['results'] != null) {
        final nowPlayingResponse = NowPlaying.fromJson(data);
        onDisplayMovies = nowPlayingResponse.results;
        notifyListeners();
      }
    } catch (e) {
      print('Error en getNowPlayingMovies: $e');
      onDisplayMovies = [];
    }
  }

  Future<void> _getPopularMovies() async {
    try {
      _popularPage++;
      final jsonData = await getJsonData('3/movie/popular', _popularPage);
      final data = json.decode(jsonData);
      if (data != null && data['results'] != null) {
        final popularResponse = PopularsMovie.fromJson(data);
        popularMovies = [...popularMovies, ...popularResponse.results];
        notifyListeners();
      }
    } catch (e) {
      print('Error en getPopularMovies: $e');
      _popularPage = math.max(0, _popularPage - 1);
    }
  }

  Future<void> _getTopRatedMovies() async {
    try {
      _topRatedPage++;
      final jsonData = await getJsonData('3/movie/top_rated', _topRatedPage);
      final data = json.decode(jsonData);
      if (data != null && data['results'] != null) {
        final topRatedResponse = TopValorados.fromJson(data);
        topRatedMovies = [...topRatedMovies, ...topRatedResponse.results];
        notifyListeners();
      }
    } catch (e) {
      print('Error en getTopRatedMovies: $e');
      _topRatedPage = math.max(0, _topRatedPage - 1);
    }
  }

  Future<void> _getComingSoonMovies() async {
    try {
      _comingSoonPage++;
      final jsonData = await getJsonData('3/movie/upcoming', _comingSoonPage);
      final data = json.decode(jsonData);
      if (data != null && data['results'] != null) {
        final comingSoonResponse = PeliculasProximas.fromJson(data);
        comingSoonMovies = [...comingSoonMovies, ...comingSoonResponse.results];
        notifyListeners();
      }
    } catch (e) {
      print('Error en getComingSoonMovies: $e');
      _comingSoonPage = math.max(0, _comingSoonPage - 1);
    }
  }

  // Métodos públicos para cargar más películas
  void getNowPlayingMovies() => _getNowPlayingMovies();
  void getPopularMovies() => _getPopularMovies();
  void getTopRatedMovies() => _getTopRatedMovies();
  void getComingSoonMovies() => _getComingSoonMovies();

  // Método para recargar todos los datos
  Future<void> reloadAll() async {
    onDisplayMovies = [];
    popularMovies = [];
    topRatedMovies = [];
    comingSoonMovies = [];
    _popularPage = 0;
    _comingSoonPage = 0;
    _topRatedPage = 0;
    await _loadInitialData();
  }

  //mostrar actores por película
  Future<List<Cast>> getMovieCast(int movieId) async {
    if (movieCast.containsKey(movieId)) return movieCast[movieId]!;

    final jsonData = await getJsonData('3/movie/$movieId/credits');
    final creditsResponse = ActoresModels.fromJson(json.decode(jsonData));
    movieCast[movieId] = creditsResponse.cast;
    return creditsResponse.cast;
  }

  //mostrar películas similares
  Future<List<Movie>> getSimilarMovies(int movieId) async {
    if (similarMovies.containsKey(movieId)) return similarMovies[movieId]!;

    final jsonData = await getJsonData('3/movie/$movieId/similar');
    final similarMoviesResponse = SimilarMovie.fromJson(json.decode(jsonData));
    similarMovies[movieId] = similarMoviesResponse.results;
    return similarMoviesResponse.results;
  }

  //mostrar géneros por película
  Future<List<Genre>> getMovieGenres(int movieId) async {
    if (genres.containsKey(movieId)) return genres[movieId]!;

    final jsonData = await getJsonData('3/movie/$movieId');
    final movieDetailResponse = GenerosModels.fromJson(json.decode(jsonData));
    genres[movieId] = movieDetailResponse.genres;
    return movieDetailResponse.genres;
  }

  //para obtener el runtime
  Future<int> getMovieRuntime(int movieId) async {
    final jsonData = await getJsonData('3/movie/$movieId');
    final movieDetailResponse = GenerosModels.fromJson(json.decode(jsonData));
    return movieDetailResponse.runtime;
  }

  //mostrar géneros
  Future<List<Genre>> getGenres() async {
    final jsonData = await getJsonData('3/genre/movie/list');
    final genresResponse = CategoriaModels.fromJson(json.decode(jsonData));
    genresList = genresResponse.genres;
    return genresResponse.genres;
  }

  //mostrar películas por género
  Future<List<Movie>> getMoviesByGenre(int genreId) async {
    _genrePage++;
    var url = Uri.https(_baseUrl, '3/discover/movie', {
      'api_key': _apiKey,
      'language': _language,
      'with_genres': '$genreId',
      'page': '$_genrePage',
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      final List<Movie> movies =
          results.map((json) => Movie.fromJson(json)).toList();
      return movies;
    } else {
      throw Exception('Fallo al leer la lista de películas por género');
    }
  }

  // Buscar películas por nombre
  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.https(_baseUrl, '3/search/movie', {
      'api_key': _apiKey,
      'language': _language,
      'query': query,
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      final List<Movie> movies =
          results.map((json) => Movie.fromJson(json)).toList();
      _searchedMovies = movies;
      return movies;
    } else {
      throw Exception('Fallo al leer la lista de películas');
    }
  }

  // Buscar películas por nombre solo en las próximas películas
  Future<List<Movie>> searchComingSoonMovies(String query) async {
    final url = Uri.https(_baseUrl, '3/search/movie', {
      'api_key': _apiKey,
      'language': _language,
      'query': query,
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      final List<Movie> movies =
          results.map((json) => Movie.fromJson(json)).toList();
      _searchedMovies =
          movies.where((movie) => comingSoonMovies.contains(movie)).toList();
      return _searchedMovies;
    } else {
      throw Exception('Fallo al leer la lista de películas');
    }
  }

  //mostrar trailers por película
  Future<List<Video>> getMovieTrailer(int movieId) async {
    if (videoTrailer.containsKey(movieId)) return videoTrailer[movieId]!;

    final jsonData = await getJsonData('3/movie/$movieId/videos');
    final trailerResponse = TrailerModels.fromJson(json.decode(jsonData));
    videoTrailer[movieId] = trailerResponse.results;
    return trailerResponse.results;
  }
}
