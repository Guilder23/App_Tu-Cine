// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/pages/inicio_page.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/utils/export.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:peliculas/src/widgets/richi_icon_widget.dart';
import 'package:peliculas/src/widgets/row_price_details.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ticket_widget/ticket_widget.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool isLoading = false;
  final GlobalKey globalKey = GlobalKey();
  List<String> comprasList = [];

  // Variables para manejar el estado de la compra
  double totalPriceFinal = 0.0;
  List<Map<String, dynamic>> selectedProducts = [];
  double productTotalPrice = 0.0;
  double totalPrice = 0.0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;

      // Obtener los precios separados de forma segura
      final double ticketPrice = (arguments['totalPrice'] as double?) ?? 0.0;
      final double productsPrice =
          (arguments['productTotalPrice'] as double?) ?? 0.0;

      // Calcular el total final
      setState(() {
        totalPriceFinal = ticketPrice + productsPrice;
        selectedProducts =
            (arguments['selectedProducts'] as List<Map<String, dynamic>>?) ??
                [];
        productTotalPrice = productsPrice;
        totalPrice = ticketPrice;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;

    // Obtener argumentos de forma segura con valores por defecto
    final List<Map<String, dynamic>> selectedProducts =
        (arguments['selectedProducts'] as List<Map<String, dynamic>>?) ?? [];
    final double productTotalPrice =
        (arguments['productTotalPrice'] as double?) ?? 0.0;
    final Movie movie = arguments['movie']
        as Movie; // Crear usuario falso si no existe o está incompleto
    dynamic userDataFinal = userData;
    if (userData == null ||
        userData['id'] == null ||
        userData['username'] == null) {
      userDataFinal = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'username': 'Usuario Test',
        'email': 'test@cinetest.com',
        'imageUser': 'https://via.placeholder.com/150/blue/white?text=User',
        'nombre': 'Usuario Test',
        'telefono': '+591 70000000'
      };
    }
    final selectedDay = arguments['selectedDay'] ??
        'Hoy, ${DateTime.now().day} de ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}';
    final selectedTime = arguments['selectedTime'] ?? '18:00';
    final selectedSeats = (arguments['selectedSeats'] as List<int>?) ?? [1, 2];
    final double totalPrice = (arguments['totalPrice'] as double?) ?? 70.0;
    final String selectedCity =
        (arguments['selectedCity'] as String?) ?? 'Ciudad no especificada';
    bool isDarkMode = context.isDarkMode;

    final Set<String> uniqueProductNames = {};
    selectedProducts.forEach((product) {
      uniqueProductNames.add(product['nombre']);
    }); //sumar el precio de las entradas y los productos
    final totalPriceFinal = productTotalPrice + totalPrice;

    void guardarCompra() async {
      setState(() {
        isLoading = true;
      });

      try {
        // Obtener el reservationId de los argumentos
        final String? reservationId = arguments['reservationId'];

        //Aqui se debe guardar la compra en la base de datos
        await Future.delayed(const Duration(seconds: 2));

        //obtener la ref. a la coleccion de compras
        final CollectionReference comprasCollection =
            FirebaseFirestore.instance.collection('compras');
        //obtener el id del documento
        final String idCompra = comprasCollection.doc().id;

        //guardar la compra
        final datosFinales = {
          'id_compra': idCompra,
          'id_usuario': userData['id'],
          'username': userData['username'],
          'email': userData['email'],
          'imageUser': userData['imageUser'],
          'movie_id': movie.id,
          'nombrePelicula': movie.title,
          'posterPelicula': movie.fullPosterImg,
          'fechaCine': selectedDay,
          'horaCine': selectedTime,
          'butacas': selectedSeats,
          'precioEntradas': totalPrice,
          'productos': selectedProducts,
          'precioProductos': productTotalPrice,
          'precioTotal': totalPriceFinal,
          'estado': true,
          'created_at': DateTime.now(),
          'selectedCity': selectedCity,
        };

        // Guardar la compra
        await comprasCollection.doc(idCompra).set(datosFinales);
        // Convertir reserva temporal a permanente si existe
        if (reservationId != null && reservationId.isNotEmpty) {
          // Obtener la fecha formateada del argumento selectedDay
          String formattedDate;
          try {
            // Intentar parsear la fecha del selectedDay (viene en formato español)
            final parts = selectedDay.split(' ');
            if (parts.length >= 3) {
              final day = parts[1].replaceAll(',', '');
              final month = _getMonthNumber(parts[2]);
              final year = parts[3];
              formattedDate =
                  '$year-${month.toString().padLeft(2, '0')}-${day.padLeft(2, '0')}';
            } else {
              // Fallback a fecha actual
              formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
            }
          } catch (e) {
            print('Error parsing date: $e');
            formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
          }

          // Crear reserva permanente
          await FirebaseFirestore.instance.collection('reservations').add({
            'movieId': movie.id.toString(),
            'userId': userData['id'],
            'date': formattedDate,
            'time': selectedTime,
            'seats': selectedSeats,
            'compraId': idCompra,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Eliminar reserva temporal
          await FirebaseFirestore.instance
              .collection('temp_reservations')
              .doc(reservationId)
              .delete();
        }

        showSnackbar(context, "Compra realizada con éxito");

        final ticketWidget = RepaintBoundary(
          key: globalKey,
          child: TicketWidget(
            width: 350,
            height: 500,
            isCornerRounded: true,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //comtenido de la compra
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Cine',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "CB",
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichiIconTextWidget(
                        icon: Icons.movie,
                        isDarkMode: isDarkMode,
                        text: "Pelicula: ${movie.title}"),
                    RowPriceDetails(
                      icon: Icons.calendar_today,
                      text: 'Fecha: ',
                      price: selectedDay,
                      isDarkMode: isDarkMode,
                    ),
                    RowPriceDetails(
                      icon: Icons.access_time,
                      text: 'Hora: ',
                      price: selectedTime,
                      isDarkMode: isDarkMode,
                    ),
                    RichiIconTextWidget(
                      icon: Icons.event_seat,
                      text:
                          'Butacas: ${selectedSeats.map((seat) => 'B$seat').join(', ')} ',
                      isDarkMode: isDarkMode,
                    ),
                    RowPriceDetails(
                      icon: Icons.confirmation_num_rounded,
                      text: 'Entradas: ',
                      price: 'Bs/ ${totalPrice.toStringAsFixed(2)}',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Productos',
                        style: TextStyle(fontSize: 20, fontFamily: "CB"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Mostrar los productos agrupados
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: uniqueProductNames.length,
                      itemBuilder: (BuildContext context, int index) {
                        final productName = uniqueProductNames.toList()[index];
                        final productCount = selectedProducts
                            .where(
                                (product) => product['nombre'] == productName)
                            .length;
                        final product = selectedProducts.firstWhere(
                            (prod) => prod['nombre'] == productName);
                        //final totalPrice = product['precio'] * productCount;

                        return Column(
                          children: [
                            Row(
                              children: [
                                FadeInImage(
                                  height: 30,
                                  placeholder:
                                      const AssetImage('assets/gif/animc.gif'),
                                  image: NetworkImage(product['imagen']),
                                  imageErrorBuilder: (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return Image.asset(
                                      'assets/images/noimage.png',
                                      height: 30,
                                    );
                                  },
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 10),
                                RichiIconTextWidget(
                                  icon: Icons.shopping_cart_outlined,
                                  isDarkMode: isDarkMode,
                                  text: ' $productCount - $productName',
                                ),
                                const SizedBox(width: 10),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    RowPriceDetails(
                      icon: Icons.attach_money_outlined,
                      text: 'Productos: ',
                      price: 'Bs/ ${productTotalPrice.toStringAsFixed(2)}',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: isDarkMode
                          ? AppColors.lightColor
                          : AppColors.darkColor,
                    ),
                    const SizedBox(height: 20),
                    RowPriceDetails(
                      icon: Icons.attach_money_outlined,
                      text: 'Total a pagar: ',
                      price: 'Bs/ ${totalPriceFinal.toStringAsFixed(2)} ',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor:
                  isDarkMode ? AppColors.darkColor : AppColors.lightColor,
              content: ticketWidget,
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MaterialButton(
                      color: AppColors.red,
                      splashColor: AppColors.acentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('Descargar',
                          style: TextStyle(
                              fontFamily: "CB", color: AppColors.lightColor)),
                      onPressed: () async {
                        try {
                          // Guardar la imagen generada en el directorio de documentos de la aplicación
                          RenderRepaintBoundary boundary =
                              globalKey.currentContext!.findRenderObject()
                                  as RenderRepaintBoundary;
                          ui.Image image =
                              await boundary.toImage(pixelRatio: 4.0);
                          final directory =
                              (await getApplicationDocumentsDirectory()).path;
                          ByteData? byteData = await image.toByteData(
                              format: ui.ImageByteFormat.png);
                          Uint8List pngBytes = byteData!.buffer.asUint8List();
                          File imgFile = File(
                              "$directory/compras_${comprasList.length - 3}.png");
                          await imgFile.writeAsBytes(pngBytes);

                          print('Imagen guardada en: ${imgFile.path}');

                          showSnackbar(context, "Ticket descargado con éxito");
                        } catch (e) {
                          print('Error al guardar la imagen: $e');
                        }
                      },
                    ),
                    MaterialButton(
                      color: AppColors.acentColor,
                      splashColor: AppColors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text('Compartir',
                          style: TextStyle(
                              fontFamily: "CB", color: AppColors.lightColor)),
                      onPressed: () async {
                        RenderRepaintBoundary boundary =
                            globalKey.currentContext!.findRenderObject()
                                as RenderRepaintBoundary;
                        ui.Image image =
                            await boundary.toImage(pixelRatio: 4.0);
                        ByteData? byteData = await image.toByteData(
                            format: ui.ImageByteFormat.png);
                        Uint8List pngBytes = byteData!.buffer.asUint8List();

                        final directory = await getTemporaryDirectory();
                        final imagePath =
                            await File('${directory.path}/compras.png')
                                .create();
                        await imagePath.writeAsBytes(pngBytes);

                        final path = imagePath.path;
                        await Share.shareFiles([path],
                            text: 'Compartiendo código Ticket');
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ).then((_) => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => InicioPage(userData: userData)),
              (Route<dynamic> route) => false,
            ));
      } catch (e) {
        showSnackbar(context, "Error al guardar la compra: ${e.toString()}");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    return isLoading
        ? WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
                backgroundColor:
                    isDarkMode ? AppColors.darkColor : AppColors.lightColor,
                body: const Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //icono de tarjeta de credito
                    Icon(
                      Icons.credit_card,
                      size: 100,
                      color: AppColors.red,
                    ),
                    CircularProgressWidget(text: "Procesando pago..."),
                  ],
                ))))
        : Scaffold(
            backgroundColor:
                isDarkMode ? AppColors.darkColor : AppColors.lightColor,
            appBar: AppBar(
              backgroundColor:
                  isDarkMode ? AppColors.darkColor : AppColors.lightColor,
              iconTheme: IconThemeData(
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
              ),
              centerTitle: true,
              title: Text(
                'Procesar pago',
                style: TextStyle(
                  color:
                      isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                  fontFamily: "CB",
                ),
              ),
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                                    placeholder: const AssetImage(
                                        'assets/gif/vertical.gif'),
                                    image: NetworkImage(movie.fullPosterImg),
                                    imageErrorBuilder: (BuildContext context,
                                        Object error, StackTrace? stackTrace) {
                                      return Image.asset(
                                          'assets/images/noimage.png');
                                    },
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        price:
                                            'Bs/ ${totalPrice.toStringAsFixed(2)}',
                                        isDarkMode: isDarkMode,
                                      ),
                                      //cine
                                      RichiIconTextWidget(
                                        icon: Icons.location_on,
                                        isDarkMode: isDarkMode,
                                        text: "Cine - $selectedCity",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                // Mostrar los productos agrupados
                                // Mostrar los productos agrupados
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: uniqueProductNames.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final productName =
                                        uniqueProductNames.toList()[index];
                                    final productCount = selectedProducts
                                        .where((product) =>
                                            product['nombre'] == productName)
                                        .length;
                                    final product = selectedProducts.firstWhere(
                                        (prod) =>
                                            prod['nombre'] == productName);
                                    final totalPrice =
                                        product['precio'] * productCount;

                                    return Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: FadeInImage(
                                            height: 50,
                                            placeholder: const AssetImage(
                                                'assets/gif/animc.gif'),
                                            image:
                                                NetworkImage(product['imagen']),
                                            imageErrorBuilder: (
                                              BuildContext context,
                                              Object error,
                                              StackTrace? stackTrace,
                                            ) {
                                              return Image.asset(
                                                'assets/images/noimage.png',
                                                height: 50,
                                              );
                                            },
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.shopping_cart_outlined,
                                                color: AppColors.red,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  ' $productCount - $productName',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isDarkMode
                                                        ? AppColors.lightColor
                                                        : AppColors.darkColor,
                                                    fontFamily: "CB",
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'S/ ${totalPrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: isDarkMode
                                                      ? AppColors.lightColor
                                                      : AppColors.darkColor,
                                                  fontFamily: "CB",
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    );
                                  },
                                ),
                                Divider(
                                  indent:
                                      MediaQuery.of(context).size.width * 0.6,
                                  color: isDarkMode
                                      ? AppColors.lightColor
                                      : AppColors.darkColor,
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Total productos:    Bs/ ${productTotalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                      fontFamily: "CB",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                    placeholder: const AssetImage(
                                        'assets/gif/animc.gif'),
                                    image: NetworkImage(userData['imageUser']),
                                    imageErrorBuilder: (BuildContext context,
                                        Object error, StackTrace? stackTrace) {
                                      return ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: Image.asset(
                                          'assets/images/avatar3.png',
                                          fit: BoxFit.contain,
                                          height: 100,
                                        ),
                                      );
                                    },
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichiIconTextWidget(
                                        icon: Icons.person,
                                        isDarkMode: isDarkMode,
                                        text: userData['username'],
                                      ),
                                      RichiIconTextWidget(
                                        icon: Icons.email,
                                        isDarkMode: isDarkMode,
                                        text: userData['email'],
                                      ),
                                      RichiIconTextWidget(
                                        icon: Icons.phone,
                                        isDarkMode: isDarkMode,
                                        text: "+591 72569847",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 10,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                RowPriceDetails(
                                  icon: Icons.credit_card,
                                  text: 'Tarjeta de crédito',
                                  price: '**** **** **** 1234',
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 10),
                                //suma el precio de las entrada y los productos
                                RowPriceDetails(
                                  icon: Icons.attach_money_outlined,
                                  text: 'Total a pagar: ',
                                  price:
                                      'Bs/ ${totalPriceFinal.toStringAsFixed(2)} ',
                                  isDarkMode: isDarkMode,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? AppColors.darkColor
                          : AppColors.lightColor,
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? AppColors.lightColor
                              : AppColors.darkColor,
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: MaterialButtomWidget(
                        color: AppColors.red,
                        title: "Pagar",
                        onPressed: () {
                          guardarCompra();
                        },
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
  }

  // Método auxiliar para convertir nombres de meses en español a números
  int _getMonthNumber(String monthName) {
    const months = {
      'ene': 1,
      'enero': 1,
      'feb': 2,
      'febrero': 2,
      'mar': 3,
      'marzo': 3,
      'abr': 4,
      'abril': 4,
      'may': 5,
      'mayo': 5,
      'jun': 6,
      'junio': 6,
      'jul': 7,
      'julio': 7,
      'ago': 8,
      'agosto': 8,
      'sep': 9,
      'septiembre': 9,
      'oct': 10,
      'octubre': 10,
      'nov': 11,
      'noviembre': 11,
      'dic': 12,
      'diciembre': 12,
    };
    return months[monthName.toLowerCase()] ?? DateTime.now().month;
  }
}
