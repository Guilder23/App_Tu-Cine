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

class DetalleCompra extends StatefulWidget {
  const DetalleCompra({Key? key}) : super(key: key);

  @override
  State<DetalleCompra> createState() => _DetalleCompraState();
}

class _DetalleCompraState extends State<DetalleCompra> {
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

  // Método para leer posts desde Firestore
  Future<List<dynamic>> leerProductos() async {
    try {
      setState(() {
        productos = []; // Inicializar la lista vacía antes de cargar
      });

      // Referencia a la colección de productos
      final productosRef = FirebaseFirestore.instance.collection('productos');

      // Realizar la consulta con manejo de errores mejorado
      final QuerySnapshot<Map<String, dynamic>> productSnapshot =
          await productosRef
              .orderBy('created_at', descending: true)
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw TimeoutException(
                    'Error de tiempo de espera al cargar productos'),
              );

      if (productSnapshot.docs.isEmpty) {
        print('No se encontraron productos');
        // Si no hay productos, crear productos de prueba
        await _crearProductosDePrueba();
        return await leerProductos(); // Volver a intentar cargar productos
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
          print('Productos cargados: ${productos.length}');
        });
      }

      return products;
    } catch (e) {
      print('Error al cargar productos: $e');
      if (mounted) {
        setState(() {
          productos = []; // En caso de error, inicializar como lista vacía
        });
      }
      return [];
    }
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

  // Método para agregar un producto seleccionado
  void agregarProducto(int index, String productId) {
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
      }

      // Recalcular el precio total de productos
      productTotalPrice = selectedProducts.fold(0.0, (total, product) {
        int cantidad = productCounts[product['id']] ?? 0;
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
        }

        // Recalcular el precio total de productos
        productTotalPrice = selectedProducts.fold(0.0, (total, product) {
          int cantidad = productCounts[product['id']] ?? 0;
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
                            icon: Icons.confirmation_num_rounded,
                            text: 'Entradas: ',
                            price: 'Bs/ ${totalPrice.toStringAsFixed(2)}',
                            isDarkMode: isDarkMode,
                          ),
                          RowPriceDetails(
                            icon: Icons.shopping_cart,
                            text: 'Productos: ',
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
            productos.isEmpty
                ? const Expanded(
                    child:
                        CircularProgressWidget(text: "Cargando Productos..."))
                : Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        const SizedBox(height: 20),
                        //Drowbuttom para elegir Cochabamba o Piura
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? AppColors.darkColor.withOpacity(0.5)
                                      : AppColors.lightColor,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                    borderSide: BorderSide(
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20.0),
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
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: FadeInImage(
                                      height: 120,
                                      placeholder: const AssetImage(
                                          'assets/gif/animc.gif'),
                                      image: NetworkImage(
                                          productos[index]['imagen']),
                                      imageErrorBuilder: (BuildContext context,
                                          Object error,
                                          StackTrace? stackTrace) {
                                        return Image.asset(
                                            'assets/images/noimage.png');
                                      },
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    productos[index]['nombre'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                      fontFamily: "CB",
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Bs/ ${productos[index]['precio']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                      fontFamily: "CB",
                                    ),
                                  ),
                                  Divider(
                                    color: isDarkMode
                                        ? AppColors.lightColor
                                        : AppColors.darkColor,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        iconSize: 30,
                                        onPressed: () {
                                          // //solo se muestra cuando hay un valor mayor a 0
                                          if (productCounts
                                                  .containsKey(productId) &&
                                              productCounts[productId]! > 0)
                                            //se resta el valor de la cantidad y el precio del producto
                                            eliminarProducto(index, productId);
                                        },
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: //solo se muestra cuando hay un valor mayor a 0
                                              productCounts.containsKey(
                                                          productId) &&
                                                      productCounts[
                                                              productId]! >
                                                          0
                                                  ? AppColors.red
                                                  : AppColors.darkAcentsColor
                                                      .withOpacity(0.5),
                                        ),
                                      ),
                                      Text(
                                        productCounts.containsKey(productId)
                                            ? productCounts[productId]
                                                .toString()
                                            : '0',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontFamily: "CB",
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 30,
                                        onPressed: () {
                                          //se suma el valor de la cantidad y el precio del producto
                                          agregarProducto(index, productId);
                                        },
                                        icon: const Icon(
                                          Icons.add_circle,
                                          color: AppColors.greenColor2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
                  }

                  // Verificar si la reserva sigue siendo válida
                  if (!isReservationValid) {
                    _showReservationExpiredDialog();
                    return;
                  }

                  // Obtener argumentos y navegar a la página de pago
                  final Map arguments =
                      ModalRoute.of(context)!.settings.arguments as Map;

                  Navigator.pushNamed(context, '/payment', arguments: {
                    'movie': arguments['movie'],
                    'userData': arguments['userData'],
                    'selectedDay': arguments['selectedDay'],
                    'selectedTime': arguments['selectedTime'],
                    'selectedSeats': arguments['selectedSeats'],
                    'totalPrice': arguments['totalPrice'],
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
