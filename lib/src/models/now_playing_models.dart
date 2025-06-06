import 'dart:convert';

import 'package:peliculas/src/models/movie_models.dart';

class NowPlaying {
  Dates dates;
  int page;
  List<Movie> results;
  int totalPages;
  int totalResults;

  NowPlaying({
    required this.dates,
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory NowPlaying.fromRawJson(String str) =>
      NowPlaying.fromJson(json.decode(str));

  factory NowPlaying.fromJson(Map<String, dynamic> json) => NowPlaying(
        dates: json["dates"] != null
            ? Dates.fromJson(json["dates"])
            : Dates.empty(),
        page: json["page"] ?? 1,
        results: json["results"] != null
            ? List<Movie>.from(
                json["results"].map((x) => Movie.fromJson(x ?? {})))
            : [],
        totalPages: json["total_pages"] ?? 1,
        totalResults: json["total_results"] ?? 0,
      );
}

class Dates {
  DateTime maximum;
  DateTime minimum;

  Dates({
    required this.maximum,
    required this.minimum,
  });

  factory Dates.fromRawJson(String str) => Dates.fromJson(json.decode(str));

  factory Dates.fromJson(Map<String, dynamic> json) => Dates(
        maximum: json["maximum"] != null
            ? DateTime.parse(json["maximum"])
            : DateTime.now(),
        minimum: json["minimum"] != null
            ? DateTime.parse(json["minimum"])
            : DateTime.now(),
      );

  factory Dates.empty() => Dates(
        maximum: DateTime.now(),
        minimum: DateTime.now(),
      );
}
