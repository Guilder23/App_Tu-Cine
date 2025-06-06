import 'dart:convert';

import 'package:peliculas/src/models/movie_models.dart';

class TopValorados {
  int page;
  List<Movie> results;
  int totalPages;
  int totalResults;

  TopValorados({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory TopValorados.fromRawJson(String str) =>
      TopValorados.fromJson(json.decode(str));

  factory TopValorados.fromJson(Map<String, dynamic> json) => TopValorados(
        page: json["page"] ?? 1,
        results: json["results"] != null
            ? List<Movie>.from(
                json["results"].map((x) => Movie.fromJson(x ?? {})))
            : [],
        totalPages: json["total_pages"] ?? 1,
        totalResults: json["total_results"] ?? 0,
      );
}
