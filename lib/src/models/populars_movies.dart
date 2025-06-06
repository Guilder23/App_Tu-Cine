import 'dart:convert';

import 'package:peliculas/src/models/movie_models.dart';

class PopularsMovie {
  int page;
  List<Movie> results;
  int totalPages;
  int totalResults;

  PopularsMovie({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory PopularsMovie.fromRawJson(String str) =>
      PopularsMovie.fromJson(json.decode(str));

  factory PopularsMovie.fromJson(Map<String, dynamic> json) => PopularsMovie(
        page: json["page"] ?? 1,
        results: json["results"] != null
            ? List<Movie>.from(
                json["results"].map((x) => Movie.fromJson(x ?? {})))
            : [],
        totalPages: json["total_pages"] ?? 1,
        totalResults: json["total_results"] ?? 0,
      );
}
