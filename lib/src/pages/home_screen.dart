// ignore_for_file: library_private_types_in_public_api

import 'package:card_swiper/card_swiper.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/pages/admin/admin_page.dart';
import 'package:peliculas/src/providers/movies_provider.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final dynamic userData;
  const HomeScreen({Key? key, this.userData}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final moviesProvider = Provider.of<MoviesProvider>(context);

    if (moviesProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressWidget(text: "Cargando películas..."),
        ),
      );
    }

    if (moviesProvider.onDisplayMovies.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie_creation_outlined,
                  size: 100, color: AppColors.red),
              const SizedBox(height: 20),
              const Text(
                'No hay películas disponibles',
                style: TextStyle(fontSize: 20, fontFamily: "CB"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    moviesProvider.getNowPlayingMovies();
                    moviesProvider.getPopularMovies();
                    moviesProvider.getTopRatedMovies();
                    moviesProvider.getComingSoonMovies();
                  });
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final imagesWithTop = moviesProvider.topRatedMovies
        .where((movie) => movie.posterPath != null)
        .toList();
    final imagesWithPopular = moviesProvider.popularMovies
        .where((movie) => movie.posterPath != null)
        .toList();

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          if (moviesProvider.onDisplayMovies.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              itemCount: moviesProvider.onDisplayMovies.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final movie = moviesProvider.onDisplayMovies[index];
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(movie.fullPosterImg),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moviesProvider.onDisplayMovies.isNotEmpty)
                  CardSwiper(
                    userData: widget.userData,
                    movies: moviesProvider.onDisplayMovies,
                    onIndexChanged: (index) {},
                  ),
                const SizedBox(height: 20),
                if (imagesWithPopular.isNotEmpty)
                  CardMoviesSlider(
                    userData: widget.userData,
                    movies: imagesWithPopular,
                    title: 'Populares',
                    onNextPage: moviesProvider.getPopularMovies,
                  ),
                if (imagesWithTop.isNotEmpty)
                  CardMoviesSlider(
                    userData: widget.userData,
                    movies: imagesWithTop,
                    title: 'Mejor valoradas',
                    onNextPage: moviesProvider.getTopRatedMovies,
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.userData["rol"] == "admin"
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                backgroundColor: AppColors.greenColor2,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return AdminPage(userData: widget.userData);
                  }));
                },
                child: const Icon(
                  Icons.add,
                  size: 30,
                  color: AppColors.text,
                ),
              ),
            )
          : null,
    );
  }
}

class CardMoviesSlider extends StatefulWidget {
  final dynamic userData;
  final List<Movie> movies;
  final String title;
  final Function onNextPage;
  const CardMoviesSlider({
    super.key,
    required this.userData,
    required this.movies,
    required this.onNextPage,
    required this.title,
  });

  @override
  State<CardMoviesSlider> createState() => _CardMoviesSliderState();
}

class _CardMoviesSliderState extends State<CardMoviesSlider> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 500) {
        widget.onNextPage();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: widget.movies.length,
        controller: scrollController,
        itemBuilder: (context, index) {
          final movie = widget.movies[index];

          return _cardSlider(context, movie,
              "${widget.title}-$index-${widget.movies[index].id}");
        },
      ),
    );
  }

  Widget _cardSlider(BuildContext context, Movie movie, String heroId) {
    movie.heroId = heroId;

    return GestureDetector(
      onTap: () {
        //Navigator.pushNamed(context, "/detalle", arguments: movie);
        Navigator.pushNamed(
          context,
          "/detalle",
          arguments: {
            'movie': movie,
            'userData': widget.userData,
          },
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Hero(
              tag: movie.heroId!,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FadeInImage(
                    placeholderFit: BoxFit.fill,
                    height: 240,
                    width: 180,
                    placeholder: const AssetImage("assets/gif/vertical.gif"),
                    imageErrorBuilder: (context, error, stackTrace) {
                      return const Image(
                        image: AssetImage("assets/images/noimage.png"),
                        height: 220,
                        width: 180,
                        fit: BoxFit.fill,
                      );
                    },
                    image: NetworkImage(movie.fullPosterImg),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: "CB",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardSwiper extends StatelessWidget {
  final dynamic userData;
  final List<Movie> movies;
  final Function(int) onIndexChanged;

  const CardSwiper({
    super.key,
    required this.userData,
    required this.movies,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const SizedBox(
        width: double.infinity,
        height: 300,
        child: Center(
          child: CircularProgressWidget(text: "Cargando..."),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 300,
      child: Swiper(
        itemCount: movies.length,
        onIndexChanged: onIndexChanged,
        layout: SwiperLayout.STACK,
        itemWidth: 200,
        itemHeight: 300,
        itemBuilder: (_, int index) {
          final movie = movies[index];
          movie.heroId = 'swiper-${movie.id}';

          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              "/detalle",
              arguments: {
                'movie': movie,
                'userData': userData,
              },
            ),
            child: Hero(
              tag: movie.heroId!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FadeInImage(
                  placeholder: const AssetImage('assets/gif/vertical.gif'),
                  image: NetworkImage(movie.fullPosterImg),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
