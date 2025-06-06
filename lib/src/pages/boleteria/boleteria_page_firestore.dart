import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class BoleteriaPageFirestore extends StatefulWidget {
  const BoleteriaPageFirestore({Key? key}) : super(key: key);

  @override
  State<BoleteriaPageFirestore> createState() => _BoleteriaPageFirestoreState();
}

class _BoleteriaPageFirestoreState extends State<BoleteriaPageFirestore> {
  int selectedDay = DateTime.now().day;
  String selectedTime = '';
  List<int> selectedSeats = [];
  List<int> reservedSeats = [];
  double ticketPrice = 35;
  double totalPrice = 0.0;
  bool isLoadingSeats = false;

  // Stream para escuchar cambios en tiempo real
  StreamSubscription<QuerySnapshot>? _reservationsStream;

  @override
  void dispose() {
    _reservationsStream?.cancel();
    super.dispose();
  }

  // Función para cargar butacas reservadas desde Firestore en tiempo real
  void _subscribeToReservations(
      String movieId, String selectedDate, String selectedTime) {
    // Cancelar stream anterior si existe
    _reservationsStream?.cancel();

    setState(() {
      isLoadingSeats = true;
    });

    // Crear stream para escuchar cambios en tiempo real
    _reservationsStream = FirebaseFirestore.instance
        .collection('reservations')
        .where('movieId', isEqualTo: movieId)
        .where('date', isEqualTo: selectedDate)
        .where('time', isEqualTo: selectedTime)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      if (mounted) {
        List<int> currentReservedSeats = snapshot.docs
            .expand<int>((doc) => List<int>.from(doc['seats'] ?? []))
            .toList();

        setState(() {
          reservedSeats = currentReservedSeats;
          isLoadingSeats = false;
          // Limpiar asientos seleccionados que ahora están reservados
          selectedSeats.removeWhere((seat) => reservedSeats.contains(seat));
          // Recalcular precio total
          totalPrice = selectedSeats.length * ticketPrice;
        });

        print('✅ Butacas actualizadas en tiempo real: $reservedSeats');
      }
    }, onError: (error) {
      print('❌ Error al escuchar reservas: $error');
      if (mounted) {
        setState(() {
          isLoadingSeats = false;
        });
      }
    });
  }

  // Función para crear una reserva temporal
  Future<bool> _crearReservaTemporal(String movieId, String selectedDate,
      String selectedTime, List<int> seats, String userId) async {
    try {
      // Verificar que las butacas aún estén disponibles
      final QuerySnapshot verificacion = await FirebaseFirestore.instance
          .collection('reservations')
          .where('movieId', isEqualTo: movieId)
          .where('date', isEqualTo: selectedDate)
          .where('time', isEqualTo: selectedTime)
          .get();

      List<int> butacasOcupadas = verificacion.docs
          .expand<int>((doc) => List<int>.from(doc['seats'] ?? []))
          .toList();

      // Verificar si alguna butaca seleccionada ya está ocupada
      for (int seat in seats) {
        if (butacasOcupadas.contains(seat)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('La butaca B$seat ya fue reservada por otro usuario'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      }

      // Crear reserva temporal (válida por 10 minutos)
      await FirebaseFirestore.instance.collection('reservations').add({
        'movieId': movieId,
        'userId': userId,
        'date': selectedDate,
        'time': selectedTime,
        'seats': seats,
        'isTemporary': true,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('❌ Error al crear reserva temporal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reservar butacas: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Función para limpiar reservas temporales expiradas
  Future<void> _limpiarReservasExpiradas() async {
    try {
      final QuerySnapshot reservasExpiradas = await FirebaseFirestore.instance
          .collection('reservations')
          .where('isTemporary', isEqualTo: true)
          .where('expiresAt', isLessThan: DateTime.now())
          .get();

      for (DocumentSnapshot doc in reservasExpiradas.docs) {
        await doc.reference.delete();
      }

      print('🧹 Limpiadas ${reservasExpiradas.docs.length} reservas expiradas');
    } catch (e) {
      print('❌ Error al limpiar reservas expiradas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final Movie movie = arguments['movie'];
    final dynamic userData = arguments['userData'];
    final size = MediaQuery.of(context).size;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final mes = DateFormat('MMMM', 'es_ES').format(now);
    final capitalizedDate = mes[0].toUpperCase() + mes.substring(1);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkColor : AppColors.lightColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkColor : AppColors.lightColor,
        iconTheme: IconThemeData(
          color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
        ),
        centerTitle: true,
        title: Text(
          movie.title,
          style: TextStyle(
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
            fontFamily: "CB",
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostrarInfoButacas,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // Información de la película
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FadeInImage(
                              height: 120,
                              width: 80,
                              fit: BoxFit.cover,
                              placeholder:
                                  const AssetImage('assets/gif/vertical.gif'),
                              image: NetworkImage(movie.fullPosterImg),
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Image.asset('assets/images/noimage.png');
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: "CB",
                                    color: isDarkMode
                                        ? AppColors.lightColor
                                        : AppColors.darkColor,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  movie.overview,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "CM",
                                    color: isDarkMode
                                        ? AppColors.lightColor
                                        : AppColors.darkColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    Text(
                                      ' ${movie.voteAverage}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: "CM",
                                        color: isDarkMode
                                            ? AppColors.lightColor
                                            : AppColors.darkColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selección de fecha
                  Text(
                    '$capitalizedDate ${now.year}',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "CB",
                      color: isDarkMode
                          ? AppColors.lightColor
                          : AppColors.darkColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: daysInMonth,
                      itemBuilder: (context, index) {
                        int day = index + 1;
                        bool isSelected = selectedDay == day;
                        bool isPastDay = day < now.day;

                        return GestureDetector(
                          onTap: isPastDay
                              ? null
                              : () {
                                  setState(() {
                                    selectedDay = day;
                                    selectedSeats.clear();
                                    totalPrice = 0.0;
                                  });

                                  if (selectedTime.isNotEmpty) {
                                    String selectedDate =
                                        DateFormat('yyyy-MM-dd').format(
                                            DateTime(now.year, now.month,
                                                selectedDay));
                                    _subscribeToReservations(
                                        movie.id.toString(),
                                        selectedDate,
                                        selectedTime);
                                  }
                                },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: isPastDay
                                  ? Colors.grey.withOpacity(0.3)
                                  : isSelected
                                      ? AppColors.acentColor
                                      : isDarkMode
                                          ? AppColors.darkColor.withOpacity(0.7)
                                          : AppColors.lightColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.acentColor
                                    : isDarkMode
                                        ? AppColors.lightColor.withOpacity(0.3)
                                        : AppColors.darkColor.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE', 'es_ES')
                                      .format(
                                          DateTime(now.year, now.month, day))
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "CM",
                                    color: isPastDay
                                        ? Colors.grey
                                        : isSelected
                                            ? AppColors.lightColor
                                            : isDarkMode
                                                ? AppColors.lightColor
                                                : AppColors.darkColor,
                                  ),
                                ),
                                Text(
                                  day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "CB",
                                    color: isPastDay
                                        ? Colors.grey
                                        : isSelected
                                            ? AppColors.lightColor
                                            : isDarkMode
                                                ? AppColors.lightColor
                                                : AppColors.darkColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selección de horario
                  Text(
                    'Horarios disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "CB",
                      color: isDarkMode
                          ? AppColors.lightColor
                          : AppColors.darkColor,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ['14:00', '16:30', '19:00', '21:30'].map((time) {
                      bool isSelected = selectedTime == time;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedTime = time;
                            selectedSeats.clear();
                            totalPrice = 0.0;
                          });

                          String selectedDate = DateFormat('yyyy-MM-dd').format(
                              DateTime(now.year, now.month, selectedDay));

                          // Limpiar reservas expiradas antes de cargar
                          _limpiarReservasExpiradas();

                          // Suscribirse a cambios en tiempo real
                          _subscribeToReservations(
                              movie.id.toString(), selectedDate, time);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.acentColor
                                : isDarkMode
                                    ? AppColors.darkColor.withOpacity(0.7)
                                    : AppColors.lightColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.acentColor
                                  : isDarkMode
                                      ? AppColors.lightColor.withOpacity(0.3)
                                      : AppColors.darkColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: "CB",
                              color: isSelected
                                  ? AppColors.lightColor
                                  : isDarkMode
                                      ? AppColors.lightColor
                                      : AppColors.darkColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Pantalla del cine
                  if (selectedTime.isNotEmpty) ...[
                    Container(
                      width: size.width * 0.7,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.acentColor.withOpacity(0.3),
                            AppColors.acentColor
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'PANTALLA',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "CB",
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Indicador de carga
                    if (isLoadingSeats)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: AppColors.acentColor,
                        ),
                      ),

                    // Mapa de butacas
                    if (!isLoadingSeats)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        itemBuilder: (context, i) {
                          int seatsInRow = i < 1
                              ? 5
                              : i < 2
                                  ? 6
                                  : i < 3
                                      ? 7
                                      : 8;
                          int seatsInPreviousRows = i < 1
                              ? 0
                              : i < 2
                                  ? 5
                                  : i < 3
                                      ? 11
                                      : i < 4
                                          ? 18
                                          : 26;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                // Indicador de fila
                                Text(
                                  'Fila ${String.fromCharCode(65 + i)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: "CM",
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Butacas de la fila
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  children: List.generate(seatsInRow, (j) {
                                    int seatNumber =
                                        seatsInPreviousRows + j + 1;
                                    bool isReserved =
                                        reservedSeats.contains(seatNumber);
                                    bool isSelected =
                                        selectedSeats.contains(seatNumber);

                                    return GestureDetector(
                                      onTap: () {
                                        if (!isReserved) {
                                          setState(() {
                                            if (isSelected) {
                                              selectedSeats.remove(seatNumber);
                                              totalPrice -= ticketPrice;
                                            } else {
                                              selectedSeats.add(seatNumber);
                                              totalPrice += ticketPrice;
                                            }
                                            totalPrice = double.parse(
                                                totalPrice.toStringAsFixed(2));
                                          });
                                        }
                                      },
                                      child: Container(
                                        height: size.width * 0.1,
                                        width: size.width * 0.1,
                                        margin: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: isReserved
                                              ? Colors.red
                                              : isSelected
                                                  ? Colors.green
                                                  : Colors.grey,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/icons/butaca.png',
                                              height: size.width * 0.06,
                                              color: Colors.white,
                                            ),
                                            Positioned(
                                              bottom: 2,
                                              child: Text(
                                                seatNumber.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontFamily: "CB",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // Leyenda
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLegendItem(Colors.grey, 'Disponible'),
                        _buildLegendItem(Colors.green, 'Seleccionado'),
                        _buildLegendItem(Colors.red, 'Ocupado'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Información del precio
                    if (selectedSeats.isNotEmpty) ...[
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Butacas seleccionadas:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "CM",
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                    ),
                                  ),
                                  Text(
                                    selectedSeats.map((s) => 'B$s').join(', '),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: "CB",
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: "CB",
                                      color: isDarkMode
                                          ? AppColors.lightColor
                                          : AppColors.darkColor,
                                    ),
                                  ),
                                  Text(
                                    'Bs/ ${totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: "CB",
                                      color: AppColors.acentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ],
              ),
            ),
          ),

          // Botón flotante para continuar
          if (selectedSeats.isNotEmpty && selectedTime.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? AppColors.darkColor : AppColors.lightColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: MaterialButtomWidget(
                  color: AppColors.acentColor,
                  title: "Continuar con la compra",
                  onPressed: () async {
                    String selectedDate = DateFormat('yyyy-MM-dd')
                        .format(DateTime(now.year, now.month, selectedDay));

                    // Crear reserva temporal antes de navegar
                    bool reservaCreada = await _crearReservaTemporal(
                        movie.id.toString(),
                        selectedDate,
                        selectedTime,
                        selectedSeats,
                        userData['uid']);

                    if (reservaCreada) {
                      Navigator.pushNamed(context, '/detalle_compra_mejorado',
                          arguments: {
                            'movie': movie,
                            'userData': userData,
                            'selectedDay': selectedDate,
                            'selectedTime': selectedTime,
                            'selectedSeats': selectedSeats,
                            'totalPrice': totalPrice,
                            'selectedCity': 'La Paz', // Valor por defecto
                          });
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    final isDarkMode = context.isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: "CM",
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
        ),
      ],
    );
  }

  void _mostrarInfoButacas() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Sistema de Reservas',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: "CB", color: AppColors.acentColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔄 Sistema en tiempo real',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                'Las butacas se actualizan automáticamente cuando otros usuarios realizan reservas.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 15),
              const Text(
                '⏰ Reserva temporal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text(
                'Al seleccionar butacas, se crea una reserva temporal de 10 minutos para completar la compra.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 15),
              _buildLegendItem(Colors.grey, 'Disponible'),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.green, 'Seleccionado'),
              const SizedBox(height: 8),
              _buildLegendItem(Colors.red, 'Ocupado por otros'),
            ],
          ),
          actions: [
            MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: AppColors.acentColor,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Entendido',
                style: TextStyle(color: Colors.white, fontFamily: "CB"),
              ),
            ),
          ],
        );
      },
    );
  }
}
