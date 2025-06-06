// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/providers/auth_provider_simple.dart';
import 'package:peliculas/src/routes/routes.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/utils/export.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/richi_icon_widget.dart';
import 'package:peliculas/src/widgets/row_price_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PaymentPageFixed extends StatefulWidget {
  const PaymentPageFixed({Key? key}) : super(key: key);

  @override
  State<PaymentPageFixed> createState() => _PaymentPageFixedState();
}

class _PaymentPageFixedState extends State<PaymentPageFixed> {
  bool isLoading = false;
  String _profileImageCacheKey =
      ''; // Clave para forzar actualización de imagen cuando cambie
  Map<String, dynamic>? userDataFinal;
  Movie? movie;
  String selectedDay = '';
  String selectedTime = '';
  List<int> selectedSeats = [];
  String selectedCity = '';
  List<Map<String, dynamic>> selectedProducts = [];
  double productTotalPrice = 0.0;
  double totalPrice = 0.0;
  double totalPriceFinal = 0.0;

  @override
  void initState() {
    super.initState();
    // Inicializar la clave de caché con un timestamp
    _profileImageCacheKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadArguments();
    _loadUserData();
  }

  void _loadArguments() {
    // Verificar si hay argumentos disponibles
    final routeSettings = ModalRoute.of(context)?.settings;
    final Map? arguments = routeSettings?.arguments as Map?;

    if (arguments == null) {
      // No hay argumentos, usar valores predeterminados
      _setupDefaultValues();
      return;
    }

    try {
      // Obtener los precios separados de forma segura
      final double ticketPrice = (arguments['totalPrice'] as double?) ?? 70.0;
      final double productsPrice =
          (arguments['productTotalPrice'] as double?) ?? 0.0;

      // Obtener más datos con manejo seguro
      movie = arguments['movie'] as Movie?;
      if (movie == null) {
        movie = _createDefaultMovie();
      }

      selectedDay = arguments['selectedDay'] ??
          'Hoy, ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}';
      selectedTime = arguments['selectedTime'] ?? '18:00';
      selectedSeats = List<int>.from(arguments['selectedSeats'] ?? [1, 2]);
      selectedCity = arguments['selectedCity'] as String? ?? 'La Paz';

      // Calcular el total final
      setState(() {
        totalPriceFinal = ticketPrice + productsPrice;
        selectedProducts = List<Map<String, dynamic>>.from(
            arguments['selectedProducts'] ?? []);
        productTotalPrice = productsPrice;
        totalPrice = ticketPrice;

        // Como respaldo en caso de fallo del provider, usamos los datos de los argumentos
        final userData = arguments['userData'];
        if (userData != null && userDataFinal == null) {
          userDataFinal = userData as Map<String, dynamic>;
        }
      });
    } catch (e) {
      // En caso de error, usar valores predeterminados
      print('Error al cargar argumentos: $e');
      _setupDefaultValues();
    }
  }

  // Método para crear una película predeterminada
  Movie _createDefaultMovie() {
    return Movie(
      adult: false,
      backdropPath: '/path/to/default/backdrop.jpg',
      genreIds: [28, 12, 14], // Códigos genéricos de acción, aventura, fantasía
      id: 0,
      originalLanguage: 'es',
      originalTitle: 'Película Ejemplo',
      overview: 'Descripción de ejemplo para una película predeterminada',
      popularity: 4.5,
      posterPath: '/path/to/default/poster.jpg',
      releaseDate: '2023-01-01',
      title: 'Película de Ejemplo',
      video: false,
      voteAverage: 4.5,
      voteCount: 100,
    );
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return months[month - 1];
  }

  // Configurar valores predeterminados cuando no hay argumentos
  void _setupDefaultValues() {
    movie = _createDefaultMovie();
    selectedDay =
        'Hoy, ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}';
    selectedTime = '18:00';
    selectedSeats = [1, 2];
    selectedCity = 'La Paz';

    setState(() {
      totalPriceFinal = 70.0;
      selectedProducts = [];
      productTotalPrice = 0.0;
      totalPrice = 70.0;
    });
  }

  void _loadUserData() {
    // Obtener datos actualizados del usuario desde el provider
    final authProvider =
        Provider.of<AuthProviderSimple>(context, listen: false);
    authProvider.getCurrentUserData().then((userData) {
      if (userData != null && mounted) {
        setState(() {
          userDataFinal = userData;
          // Actualizar la clave de caché para forzar la actualización de la imagen
          _profileImageCacheKey =
              DateTime.now().millisecondsSinceEpoch.toString();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.isDarkMode;

    return Consumer<AuthProviderSimple>(
      builder: (context, authProvider, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          key: ValueKey('payment_$_profileImageCacheKey'),
          future: authProvider.getCurrentUserData(),
          builder: (context, snapshot) {            // Actualizar los datos del usuario si están disponibles
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData &&
                snapshot.data != null) {
              userDataFinal = snapshot.data;
            }

            return Scaffold(
              appBar: AppBar(
                elevation: 0,
                backgroundColor: isDarkMode ? Colors.black : Colors.white,
                iconTheme: IconThemeData(
                  color: isDarkMode ? Colors.white : kDarkBlue,
                ),
                title: Text(
                  "Método de Pago",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : kDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              body: isLoading
                  ? const Center(
                      child: CircularProgressWidget(text: "Procesando pago..."))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMovieCard(isDarkMode),
                          const SizedBox(height: 16.0),
                          if (selectedProducts.isNotEmpty)
                            _buildProductsCard(isDarkMode),
                          if (selectedProducts.isNotEmpty)
                            const SizedBox(height: 16.0),
                          _buildUserCard(isDarkMode),
                          const SizedBox(height: 16.0),
                          _buildPaymentDetailsCard(isDarkMode),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildMovieCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: movie != null
                      ? Image.network(
                          movie!.fullPosterImg,
                          height: 100,
                          width: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'assets/img/no-image.jpg',
                            height: 100,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/img/no-image.jpg',
                          height: 100,
                          width: 70,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie?.title ?? 'Película',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      RichiIconWidget(
                        icon: Icons.calendar_today,
                        text: selectedDay,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(height: 4.0),
                      RichiIconWidget(
                        icon: Icons.access_time,
                        text: selectedTime,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(height: 4.0),
                      RichiIconWidget(
                        icon: Icons.event_seat,
                        text: selectedSeats.map((seat) => 'B$seat').join(', '),
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            RowPriceDetails(
              title: 'Entradas',
              price: 'Bs/ ${totalPrice.toStringAsFixed(2)}',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8.0),
            RichiIconWidget(
              icon: Icons.location_on,
              text: "Cine - $selectedCity",
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comestibles',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16.0),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedProducts.length,
              itemBuilder: (context, index) {
                final product = selectedProducts[index];
                final productName = product['name'] ?? 'Producto';
                final productQuantity = product['quantity'] ?? 1;
                final productPrice = product['price'] ?? 0.0;
                final productTotal = productPrice * productQuantity;

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    productName,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    'Cantidad: $productQuantity  x  Bs/ ${productPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  trailing: Text(
                    'Bs/ ${productTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8.0),
            Divider(
              height: 1,
              thickness: 1,
              color: isDarkMode ? Colors.white30 : Colors.black12,
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total productos:    Bs/ ${productTotalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(bool isDarkMode) {
    if (userDataFinal == null) {
      return Card(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No se pudo cargar la información del usuario',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              backgroundImage: NetworkImage(
                userDataFinal!['profile_image'] ??
                    'https://via.placeholder.com/100',
                headers: {
                  'Cache-Control': 'no-cache',
                  'Pragma': 'no-cache',
                  'Expires': '0',
                },
              ),
              key: ValueKey(
                  'profile_img_$_profileImageCacheKey'), // Clave para forzar actualización
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichiIconWidget(
                    icon: Icons.person,
                    text: userDataFinal!['username'] ?? 'Usuario',
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(height: 4.0),
                  RichiIconWidget(
                    icon: Icons.email,
                    text: userDataFinal!['email'] ?? 'email@test.com',
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(height: 4.0),
                  RichiIconWidget(
                    icon: Icons.phone,
                    text: userDataFinal!['phone'] ?? "+591 70000000",
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de Pago',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16.0),
            RowPriceDetails(
              title: 'Entradas',
              price: 'Bs/ ${totalPrice.toStringAsFixed(2)}',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8.0),
            RowPriceDetails(
              title: 'Productos',
              price: 'Bs/ ${productTotalPrice.toStringAsFixed(2)}',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8.0),
            Divider(
              height: 1,
              thickness: 1,
              color: isDarkMode ? Colors.white30 : Colors.black12,
            ),
            const SizedBox(height: 8.0),
            RowPriceDetails(
              title: 'Total',
              price: 'Bs/ ${totalPriceFinal.toStringAsFixed(2)} ',
              isBold: true,
              isDarkMode: isDarkMode,
            ),            const SizedBox(height: 24.0),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: MaterialButton(
                height: 50,
                color: AppColors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                onPressed: _procesarCompra,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Confirmar compra',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontFamily: "CB",
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _procesarCompra() async {
    if (userDataFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Error: No se pudieron obtener los datos del usuario")));
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Obtener el ID del usuario de manera segura
      final String userId =
          userDataFinal!['uid'] ?? userDataFinal!['id'] ?? 'unknown';

      // Crear el documento de compra
      final compraData = {
        'timestamp': Timestamp.now(),
        'userId': userId,
        'username': userDataFinal!['username'] ?? 'Usuario',
        'email': userDataFinal!['email'] ?? 'email@example.com',
        'imageUser': userDataFinal!['profile_image'] ?? '',
        'movie_id': movie?.id ?? 0,
        'nombrePelicula': movie?.title ?? 'Película',
        'posterPelicula': movie?.fullPosterImg ?? '',
        'fechaCine': selectedDay,
        'horaCine': selectedTime,
        'butacas': selectedSeats,
        'precioEntradas': totalPrice,
        'productos': selectedProducts,
        'precioProductos': productTotalPrice,
        'precioTotal': totalPriceFinal,
        'selectedCity': selectedCity,
        'estado': 'completado'
      };

      // Guardar la compra en Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('compras')
          .add(compraData);

      // Navegar a la pantalla de boleto generado
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compra realizada con éxito")));

      Navigator.pushReplacementNamed(
        context,
        Routes.boletoGenerado,
        arguments: {
          'compraId': docRef.id,
          'userData': userDataFinal,
          'movie': movie,
          'selectedDay': selectedDay,
          'selectedTime': selectedTime,
          'selectedSeats': selectedSeats,
          'selectedCity': selectedCity,
          'totalPrice': totalPrice,
          'selectedProducts': selectedProducts,
          'productTotalPrice': productTotalPrice,
          'totalPriceFinal': totalPriceFinal,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error al guardar la compra: ${e.toString()}")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
