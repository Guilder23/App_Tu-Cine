// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/utils/export.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:peliculas/src/widgets/richi_icon_widget.dart';
import 'package:peliculas/src/widgets/row_price_details.dart';
import 'package:flutter/material.dart';

class DetalleCompraMejorado extends StatefulWidget {
  const DetalleCompraMejorado({Key? key}) : super(key: key);

  @override
  State<DetalleCompraMejorado> createState() => _DetalleCompraMejoradoState();
}

class _DetalleCompraMejoradoState extends State<DetalleCompraMejorado> {
  List<dynamic> productos = [];
  List<Map<String, dynamic>> selectedProducts = [];
  Map<String, int> productCounts = {};
  double productTotalPrice = 0.0;
  String? selectedCity;
  String? reservationId;
  bool isReservationValid = true;
  Timer? _reservationTimer;
  bool isLoadingProducts = true;

  final List<Map<String, String>> cities = [
    {"value": "Cochabamba", "label": "Cochabamba"}
  ];

  @override
  void initState() {
    super.initState();
    selectedCity = cities[0]["value"];
    _initData();
  }

  @override
  void dispose() {
    _reservationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initData() async {
    try {
      await leerProductos();
      // Iniciar temporizador para verificar la validez de la reserva
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
        reservationId = arguments['reservationId'];
        if (reservationId != null) {
          _startReservationTimer();
        }
      });
    } catch (e) {
      print('Error al inicializar datos: $e');
    }
  }

  // Ya no guardamos datos localmente, todo se maneja en Firestore

  void _startReservationTimer() {
    // Verificar la reserva cada 30 segundos
    _reservationTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('temp_reservations')
            .doc(reservationId)
            .get();

        if (!doc.exists || doc.data()?['status'] != 'pending') {
          setState(() {
            isReservationValid = false;
          });
          timer.cancel();
          _showReservationExpiredDialog();
        }
      } catch (e) {
        print('Error checking reservation: $e');
      }
    });
  }

  void _showReservationExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reserva expirada',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: "CB", color: AppColors.red)),
        content: const Text(
          "Tu tiempo de reserva ha expirado. Por favor, realiza una nueva selección de asientos.",
          textAlign: TextAlign.justify,
          style: TextStyle(fontFamily: "CM"),
        ),
        actions: [
          MaterialButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: AppColors.acentColor,
            onPressed: () {
              Navigator.of(context)
                ..pop() // Cerrar el diálogo
                ..pop(); // Volver a la página anterior
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  // Función para crear productos de prueba
  Future<void> _crearProductosDePrueba() async {
    try {
      print('Creando productos de prueba...');
      final productosRef = FirebaseFirestore.instance.collection('productos');

      final productosPrueba = [
        {
          'nombre': 'Palomitas Grandes',
          'precio': 25.0,
          'imagen':
              'https://images.unsplash.com/photo-1578849278619-e73505e9610f?w=400',
          'created_at': DateTime.now(),
          'id_usuario': 'test_user_123',
        },
        {
          'nombre': 'Refresco Cola',
          'precio': 15.0,
          'imagen':
              'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=400',
          'created_at': DateTime.now(),
          'id_usuario': 'test_user_123',
        },
        {
          'nombre': 'Combo Familiar',
          'precio': 45.0,
          'imagen':
              'https://images.unsplash.com/photo-1505686994434-e3cc5abf1330?w=400',
          'created_at': DateTime.now(),
          'id_usuario': 'test_user_123',
        },
        {
          'nombre': 'Nachos con Queso',
          'precio': 20.0,
          'imagen':
              'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400',
          'created_at': DateTime.now(),
          'id_usuario': 'test_user_123',
        },
      ];

      for (var producto in productosPrueba) {
        final docRef = productosRef.doc();
        producto['id'] = docRef.id;
        await docRef.set(producto);
        print('Producto creado: ${producto['nombre']}');
      }

      print('Productos de prueba creados exitosamente');
    } catch (e) {
      print('Error al crear productos de prueba: $e');
    }
  }

  // Método mejorado para leer productos desde Firestore
  Future<List<dynamic>> leerProductos() async {
    try {
      if (mounted) {
        setState(() {
          productos = [];
          isLoadingProducts = true;
        });
      }

      // Referencia a la colección de productos
      final productosRef = FirebaseFirestore.instance.collection('productos');

      print('Intentando cargar productos desde Firestore...');

      // Realizar la consulta con manejo de errores mejorado
      final QuerySnapshot<Map<String, dynamic>> productSnapshot =
          await productosRef
              .orderBy('created_at', descending: true)
              .get()
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw TimeoutException(
                    'Error de tiempo de espera al cargar productos'),
              );

      print(
          'Consulta a Firestore completada. Documentos encontrados: ${productSnapshot.docs.length}');

      if (productSnapshot.docs.isEmpty) {
        print('No se encontraron productos, creando productos de prueba...');
        await _crearProductosDePrueba();

        // Esperar un momento antes de recargar
        await Future.delayed(const Duration(seconds: 2));

        // Intentar cargar los productos nuevamente
        final QuerySnapshot<Map<String, dynamic>> newProductSnapshot =
            await productosRef
                .orderBy('created_at', descending: true)
                .get()
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () => throw TimeoutException(
                      'Error de tiempo de espera al cargar productos después de crearlos'),
                );

        if (newProductSnapshot.docs.isEmpty) {
          print('No se pudieron crear productos de prueba');
          if (mounted) {
            setState(() {
              isLoadingProducts = false;
            });
          }
          return [];
        }

        // Mapear los nuevos productos
        final List<dynamic> newProducts = newProductSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        if (mounted) {
          setState(() {
            productos = newProducts;
            isLoadingProducts = false;
            print('Productos de prueba cargados: ${productos.length}');
          });
        }

        return newProducts;
      }

      // Mapear los documentos a una lista de productos
      final List<dynamic> products = productSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Asegurarse de que el ID esté incluido
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          productos = products;
          isLoadingProducts = false;
          print('Productos cargados exitosamente: ${productos.length}');
        });
      }

      return products;
    } catch (e) {
      print('Error al cargar productos: $e');

      // Intentar crear productos de prueba en caso de error
      try {
        print('Intentando crear productos de prueba debido al error...');
        await _crearProductosDePrueba();

        // Esperar antes de recargar
        await Future.delayed(const Duration(seconds: 2));

        // Recargar productos después de crearlos
        final productosRef = FirebaseFirestore.instance.collection('productos');
        final QuerySnapshot<Map<String, dynamic>> productSnapshot =
            await productosRef.orderBy('created_at', descending: true).get();

        final List<dynamic> products = productSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        if (mounted) {
          setState(() {
            productos = products;
            isLoadingProducts = false;
            print('Productos de emergencia cargados: ${productos.length}');
          });
        }

        return products;
      } catch (emergencyError) {
        print(
            'Error también al crear productos de emergencia: $emergencyError');
        if (mounted) {
          setState(() {
            productos = [];
            isLoadingProducts = false;
          });
        }
        return [];
      }
    }
  }

  // Método para agregar un producto seleccionado
  void agregarProducto(int index, String productId) {
    // Obtener argumentos para calcular límites
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final selectedSeats = arguments['selectedSeats'] as List<int>;
    final int numButacas = selectedSeats.length;

    // Límite máximo de productos por butaca (2-3 productos de cada tipo)
    const int productosMaxPorButaca = 3;
    final int limiteMaximo = numButacas * productosMaxPorButaca;

    // Verificar si ya se alcanzó el límite para este tipo de producto
    final String productName = productos[index]['nombre'];
    final int cantidadActual = productCounts[productId] ?? 0;

    if (cantidadActual >= limiteMaximo) {
      // Mostrar mensaje de límite alcanzado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Has alcanzado el límite máximo de $limiteMaximo $productName para $numButacas butaca${numButacas > 1 ? 's' : ''}",
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return; // No agregar más productos
    }

    setState(() {
      // Incrementar la cantidad del producto
      productCounts[productId] = (productCounts[productId] ?? 0) + 1;

      // Buscar si el producto ya existe en selectedProducts
      var productoExistente = selectedProducts.firstWhere(
        (product) => product['id'] == productId,
        orElse: () => <String, dynamic>{},
      );

      if (productoExistente.isEmpty) {
        // Si no existe, agregar el producto con cantidad 1
        Map<String, dynamic> nuevoProducto =
            Map<String, dynamic>.from(productos[index]);
        nuevoProducto['cantidad'] = 1;
        selectedProducts.add(nuevoProducto);
      } else {
        // Si ya existe, actualizar la cantidad en el objeto
        productoExistente['cantidad'] = productCounts[productId];
      }

      // Recalcular el precio total de productos
      productTotalPrice = selectedProducts.fold(0.0, (total, product) {
        int cantidad = product['cantidad'] ??
            0; // Usar la cantidad del producto directamente
        return total + (product['precio'] * cantidad);
      });

      // Redondear el precio total a dos decimales
      productTotalPrice = double.parse(productTotalPrice.toStringAsFixed(2));
    });
  }

  // Método para eliminar un producto seleccionado
  void eliminarProducto(int index, String productId) {
    setState(() {
      if (productCounts.containsKey(productId) &&
          productCounts[productId]! > 0) {
        // Decrementar la cantidad
        productCounts[productId] = productCounts[productId]! - 1;

        // Si la cantidad llega a 0, eliminar el producto
        if (productCounts[productId] == 0) {
          selectedProducts.removeWhere((product) => product['id'] == productId);
          productCounts.remove(productId);
        } else {
          // Si aún hay cantidad, actualizar la cantidad en el objeto del producto
          var productoExistente = selectedProducts.firstWhere(
            (product) => product['id'] == productId,
            orElse: () => <String, dynamic>{},
          );
          if (productoExistente.isNotEmpty) {
            productoExistente['cantidad'] = productCounts[productId];
          }
        }

        // Recalcular el precio total de productos
        productTotalPrice = selectedProducts.fold(0.0, (total, product) {
          int cantidad = product['cantidad'] ??
              0; // Usar la cantidad del producto directamente
          return total + (product['precio'] * cantidad);
        });

        // Redondear el precio total a dos decimales
        productTotalPrice = double.parse(productTotalPrice.toStringAsFixed(2));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    final Map arguments = ModalRoute.of(context)!.settings.arguments
        as Map; // Extraer los argumentos pasados a la página
    final Movie movie = arguments['movie'];
    final userData = arguments['userData']; // Extraer userData

    final selectedDay = arguments['selectedDay'];
    final selectedTime = arguments['selectedTime'];
    final selectedSeats = arguments['selectedSeats'];
    final double totalPrice = arguments['totalPrice'];

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkColor : AppColors.lightColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkColor : AppColors.lightColor,
        iconTheme: IconThemeData(
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor),
        centerTitle: true,
        title: Text(
          "Detalle de tu compra",
          style: TextStyle(
            fontSize: 20,
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
            fontFamily: "CB",
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: FadeInImage(
                        height: 100,
                        placeholder:
                            const AssetImage('assets/gif/vertical.gif'),
                        image: NetworkImage(movie.fullPosterImg),
                        imageErrorBuilder: (BuildContext context, Object error,
                            StackTrace? stackTrace) {
                          return Image.asset('assets/images/noimage.png');
                        },
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            movie.title,
                            style: TextStyle(
                              fontSize: 17,
                              color: isDarkMode
                                  ? AppColors.lightColor
                                  : AppColors.darkColor,
                              fontFamily: "CB",
                            ),
                          ),
                          const SizedBox(height: 5),
                          RichiIconTextWidget(
                            icon: Icons.calendar_month_outlined,
                            isDarkMode: isDarkMode,
                            text: selectedDay,
                          ),
                          RichiIconTextWidget(
                            icon: Icons.access_time,
                            isDarkMode: isDarkMode,
                            text: selectedTime,
                          ),
                          RichiIconTextWidget(
                            icon: Icons.event_seat,
                            isDarkMode: isDarkMode,
                            text: selectedSeats
                                .map((seat) => 'B$seat')
                                .join(', '),
                          ),
                          RowPriceDetails(
                            title: 'Entradas',
                            price: 'Bs/ ${totalPrice.toStringAsFixed(2)}',
                            isDarkMode: isDarkMode,
                          ),
                          RowPriceDetails(
                            title: 'Productos',
                            price:
                                'Bs/ ${productTotalPrice.toStringAsFixed(2)}',
                            isDarkMode: isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Cine  solo esta disponible en\nCochabamba - Bolivia",
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                  fontFamily: "CM",
                ),
                textAlign: TextAlign.center,
              ),
            ),
            isLoadingProducts
                ? const Expanded(
                    child:
                        CircularProgressWidget(text: "Cargando Productos..."))
                : productos.isEmpty
                    ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: isDarkMode
                                    ? AppColors.lightColor.withOpacity(0.5)
                                    : AppColors.darkColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No hay productos disponibles",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: isDarkMode
                                      ? AppColors.lightColor.withOpacity(0.7)
                                      : AppColors.darkColor.withOpacity(0.7),
                                  fontFamily: "CB",
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => leerProductos(),
                                child:
                                    const Text("Reintentar cargar productos"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            const SizedBox(height: 20),
                            //Dropdown para elegir Cochabamba
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Selecciona la ciudad",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                      fontFamily: "CB",
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? AppColors.darkColor.withOpacity(0.5)
                                          : AppColors.lightColor,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        borderSide: BorderSide(
                                          color: isDarkMode
                                              ? AppColors.lightColor
                                              : AppColors.darkColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        borderSide: BorderSide(
                                          color: AppColors.red,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    dropdownColor: isDarkMode
                                        ? AppColors.darkColor
                                        : AppColors.lightColor,
                                    value: selectedCity,
                                    items: cities.map((city) {
                                      return DropdownMenuItem<String>(
                                        value: city["value"],
                                        child: Text(
                                          city["label"]!,
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? AppColors.lightColor
                                                : AppColors.darkColor,
                                            fontFamily: "CB",
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedCity = value;
                                          print('Ciudad seleccionada: $value');
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Agregar Productos:",
                              style: TextStyle(
                                fontSize: 20,
                                color: isDarkMode
                                    ? AppColors.lightColor
                                    : AppColors.darkColor,
                                fontFamily: "CB",
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Información sobre límites de productos
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.acentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.acentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: AppColors.acentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Límite: máximo 3 productos de cada tipo por butaca (${selectedSeats.length} butaca${selectedSeats.length > 1 ? 's' : ''} seleccionada${selectedSeats.length > 1 ? 's' : ''})",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode
                                            ? AppColors.lightColor
                                                .withOpacity(0.8)
                                            : AppColors.darkColor
                                                .withOpacity(0.8),
                                        fontFamily: "CM",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2 / 3,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: productos.length,
                              itemBuilder: (BuildContext context, int index) {
                                String productId = productos[index]['id'];
                                return Card(
                                  color: isDarkMode
                                      ? AppColors.darkColor
                                      : AppColors.text,
                                  elevation: 10,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: FadeInImage(
                                            height: 100,
                                            placeholder: const AssetImage(
                                                'assets/gif/animc.gif'),
                                            image: NetworkImage(
                                                productos[index]['imagen']),
                                            imageErrorBuilder:
                                                (BuildContext context,
                                                    Object error,
                                                    StackTrace? stackTrace) {
                                              return Image.asset(
                                                  'assets/images/noimage.png');
                                            },
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Flexible(
                                          child: Text(
                                            productos[index]['nombre'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDarkMode
                                                  ? AppColors.lightColor
                                                  : AppColors.darkColor,
                                              fontFamily: "CB",
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Bs/ ${productos[index]['precio']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? AppColors.lightColor
                                                : AppColors.darkColor,
                                            fontFamily: "CB",
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                iconSize: 20,
                                                onPressed: () {
                                                  if (productCounts.containsKey(
                                                          productId) &&
                                                      productCounts[
                                                              productId]! >
                                                          0)
                                                    eliminarProducto(
                                                        index, productId);
                                                },
                                                icon: Icon(
                                                  Icons.remove_circle,
                                                  color: productCounts
                                                              .containsKey(
                                                                  productId) &&
                                                          productCounts[
                                                                  productId]! >
                                                              0
                                                      ? AppColors.red
                                                      : AppColors
                                                          .darkAcentsColor
                                                          .withOpacity(0.5),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              productCounts
                                                      .containsKey(productId)
                                                  ? productCounts[productId]
                                                      .toString()
                                                  : '0',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontFamily: "CB",
                                              ),
                                            ),
                                            SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                iconSize: 20,
                                                onPressed: () {
                                                  agregarProducto(
                                                      index, productId);
                                                },
                                                icon: const Icon(
                                                  Icons.add_circle,
                                                  color: AppColors.greenColor2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MaterialButtomWidget(
                title: "Pagar",
                color: AppColors.red,
                onPressed: () {
                  //verifica que se haya seleccionado una ciudad
                  if (selectedCity == null) {
                    showSnackbar(context, "Selecciona una ciudad");
                    return;
                  } // Verificar si la reserva sigue siendo válida
                  if (!isReservationValid) {
                    _showReservationExpiredDialog();
                    return;
                  } // Navegar a la página de pago usando las variables ya extraídas
                  Navigator.pushNamed(context, '/payment', arguments: {
                    'movie': movie,
                    'userData': userData,
                    'selectedDay': selectedDay,
                    'selectedTime': selectedTime,
                    'selectedSeats': selectedSeats,
                    'totalPrice': totalPrice,
                    'selectedProducts': selectedProducts,
                    'productTotalPrice': productTotalPrice,
                    'reservationId': reservationId,
                    'selectedCity': selectedCity,
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
