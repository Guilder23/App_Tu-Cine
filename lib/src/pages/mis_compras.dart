import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/circularprogress_widget.dart';
import 'package:peliculas/src/widgets/richi_icon_widget.dart';
import 'package:peliculas/src/widgets/row_price_details.dart';
import 'package:flutter/material.dart';

class MisComprasPage extends StatefulWidget {
  final dynamic userData;
  const MisComprasPage({Key? key, this.userData}) : super(key: key);

  @override
  State<MisComprasPage> createState() => _MisComprasPageState();
}

class _MisComprasPageState extends State<MisComprasPage> {
  Future<List<Map<String, dynamic>>> leerCompras() async {
    try {
      // DEBUG: Verificar datos del usuario en mis_compras
      print('DEBUG MIS_COMPRAS - UserData completo: ${widget.userData}');
      print('DEBUG MIS_COMPRAS - UID: ${widget.userData['uid']}');
      print('DEBUG MIS_COMPRAS - ID: ${widget.userData['id']}');

      // Verificar que tenemos datos del usuario
      if (widget.userData == null ||
          (widget.userData['uid'] == null && widget.userData['id'] == null)) {
        print('Error: No hay datos de usuario o UID/ID es null');
        return [];
      }

      // Usar el campo correcto para el ID de usuario (verificar ambos)
      final String? userId = widget.userData['uid'] ?? widget.userData['id'];
      if (userId == null) {
        print('Error: No se pudo obtener ID de usuario');
        return [];
      }
      print('DEBUG MIS_COMPRAS - ID de usuario final: $userId');

      // Obtener la referencia a la colección "compras"
      CollectionReference comprasCollection =
          FirebaseFirestore.instance.collection('compras');
      QuerySnapshot querySnapshot;
      try {
        // Intentar la consulta con orderBy (requiere índice)
        print('DEBUG MIS_COMPRAS - Consultando con id_usuario: $userId');
        querySnapshot = await comprasCollection
            .where('id_usuario', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .get();
      } catch (e) {
        // Si falla por falta de índice, hacer consulta sin orderBy
        print('Índice aún no disponible, usando consulta simple: $e');
        querySnapshot = await comprasCollection
            .where('id_usuario', isEqualTo: userId)
            .get();
      }

      print(
          'DEBUG MIS_COMPRAS - Documentos encontrados: ${querySnapshot.docs.length}'); // Crear una lista vacía para almacenar las compras
      List<Map<String, dynamic>> compras = [];

      // Iterar sobre los documentos y agregar los datos a la lista
      querySnapshot.docs.forEach((doc) {
        // Convertir los datos a un Map<String, dynamic>
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        // DEBUG: Mostrar datos de cada compra encontrada
        if (data != null) {
          print(
              'DEBUG MIS_COMPRAS - Compra encontrada: ID=${data['id_compra']}, Usuario=${data['id_usuario']}, Película=${data['nombrePelicula']}');
        }

        // Verificar si los datos no son nulos antes de agregarlos
        if (data != null) {
          compras.add(data);
        }
      }); // Si no se pudo ordenar en la consulta, ordenar localmente
      if (compras.isNotEmpty) {
        compras.sort((a, b) {
          final dateA = a['created_at'];
          final dateB = b['created_at'];

          if (dateA == null || dateB == null) return 0;

          // Convertir ambos a DateTime para comparar consistentemente
          DateTime? parsedDateA = _parseDate(dateA);
          DateTime? parsedDateB = _parseDate(dateB);

          if (parsedDateA == null || parsedDateB == null) return 0;

          return parsedDateB.compareTo(
              parsedDateA); // Orden descendente (más reciente primero)
        });
      }
      print(
          'DEBUG MIS_COMPRAS - Compras encontradas para usuario $userId: ${compras.length}');

      // DEBUG: Mostrar detalles de las compras encontradas DESPUÉS del ordenamiento
      print('DEBUG MIS_COMPRAS - === COMPRAS DESPUÉS DEL ORDENAMIENTO ===');
      for (int i = 0; i < compras.length; i++) {
        final compra = compras[i];
        final fechaRaw = compra['created_at'];
        final fechaParsed = _parseDate(fechaRaw);
        print(
            'DEBUG MIS_COMPRAS - Posición $i: ${compra['nombrePelicula']} - Raw: $fechaRaw - Parsed: $fechaParsed');
      }
      print(
          'DEBUG MIS_COMPRAS - === FIN DEL LISTADO ==='); // Retornar la lista de compras del usuario
      return compras;
    } catch (e) {
      print('Error al leer las compras: $e');
      return []; // Retornar una lista vacía en caso de error
    }
  }

  // Método para convertir diferentes tipos de timestamp a DateTime
  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;

    try {
      // Si ya es DateTime
      if (date is DateTime) {
        return date;
      }

      // Si es Timestamp de Firestore
      if (date.runtimeType.toString().contains('Timestamp')) {
        return (date as Timestamp).toDate();
      }

      // Si es número (epoch time en segundos)
      if (date is int) {
        return DateTime.fromMillisecondsSinceEpoch(date * 1000);
      }

      // Si es double (epoch time en segundos con decimales)
      if (date is double) {
        return DateTime.fromMillisecondsSinceEpoch((date * 1000).round());
      }

      // Si es String, intentar parsearlo
      if (date is String) {
        // Intentar parsear como ISO 8601
        try {
          return DateTime.parse(date);
        } catch (e) {
          // Intentar parsear como timestamp en segundos
          final timestamp = int.tryParse(date);
          if (timestamp != null) {
            return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          }
        }
      }

      print(
          'DEBUG - Tipo de fecha no reconocido: ${date.runtimeType} - Valor: $date');
      return null;
    } catch (e) {
      print('DEBUG - Error al parsear fecha: $e - Valor: $date');
      return null;
    }
  }

  //actualizar la pagina
  Future<void> onRefresh() async {
    //espera de 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    //actualiza la pagina
    setState(() {
      leerCompras();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: leerCompras(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text("Error"),
              );
            } else if (snapshot.hasData) {
              List<Map<String, dynamic>> compras = snapshot.data!;
              return Column(
                children: [
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          'Mis Compras',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: "CB",
                            color: isDarkMode
                                ? AppColors.text
                                : AppColors.darkColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.shopping_cart,
                        color: isDarkMode
                            ? AppColors.lightColor
                            : AppColors.darkColor,
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: compras.length,
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        final comp = compras[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 15,
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
                                      image: NetworkImage(
                                        comp['posterPelicula'],
                                      ),
                                      imageErrorBuilder: (BuildContext context,
                                          Object error,
                                          StackTrace? stackTrace) {
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
                                          "Película: ${compras[index]['nombrePelicula']}",
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
                                          text: compras[index]['fechaCine'],
                                        ),
                                        RichiIconTextWidget(
                                          icon: Icons.access_time,
                                          isDarkMode: isDarkMode,
                                          text: compras[index]['horaCine'],
                                        ),
                                        RichiIconTextWidget(
                                          icon: Icons.event_seat,
                                          isDarkMode: isDarkMode,
                                          text: compras[index]['butacas']
                                              .map((seat) => 'B$seat')
                                              .join(', '),
                                        ),
                                        RowPriceDetails(
                                          title: 'Entradas',
                                          price:
                                              'Bs/ ${compras[index]['precioEntradas'].toStringAsFixed(2)}',
                                          isDarkMode: isDarkMode,
                                        ),
                                        RowPriceDetails(
                                          title: 'Productos',
                                          price:
                                              'Bs/ ${compras[index]['precioProductos'].toStringAsFixed(2)}',
                                          isDarkMode: isDarkMode,
                                        ),
                                        RowPriceDetails(
                                          title: 'Total',
                                          price:
                                              'Bs/ ${compras[index]['precioTotal'].toStringAsFixed(2)}',
                                          isDarkMode: isDarkMode,
                                          isBold: true,
                                        ),
                                        //cine
                                        RichiIconTextWidget(
                                          icon: Icons.location_on,
                                          isDarkMode: isDarkMode,
                                          text:
                                              "Cine - ${compras[index]['selectedCity']}",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return const Center(
              child: CircularProgressWidget(
                text: "Cargando...",
              ),
            );
          },
        ),
      ),
    );
  }
}
