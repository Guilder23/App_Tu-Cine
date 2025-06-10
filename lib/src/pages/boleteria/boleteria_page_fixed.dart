import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class BoleteriaPageFixed extends StatefulWidget {
  const BoleteriaPageFixed({Key? key}) : super(key: key);

  @override
  State<BoleteriaPageFixed> createState() => _BoleteriaPageFixedState();
}
    
class _BoleteriaPageFixedState extends State<BoleteriaPageFixed> {
  int selectedDay = DateTime.now().day;
  String selectedTime = '';
  List<int> selectedSeats = [];
  List<int> reservedSeats = [];
  double ticketPrice = 35;
  double totalPrice = 0.0;
  bool isLoadingSeats = false;
  // Stream para escuchar cambios en tiempo real
  StreamSubscription<QuerySnapshot>? _reservationsStream;

  // Timer para actualizar horarios en tiempo real
  Timer? _timeUpdateTimer;
  @override
  void dispose() {
    _reservationsStream?.cancel();
    _timeUpdateTimer?.cancel();
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

        print('Butacas reservadas en Firestore: $reservedSeats');
      }
    }, onError: (error) {
      print('Error al escuchar reservas: $error');
      if (mounted) {
        setState(() {
          isLoadingSeats = false;
        });
      }
    });
  }

  // Función para verificar si una butaca está ocupada
  bool isSeatOccupied(int seatNumber) {
    return reservedSeats.contains(seatNumber);
  }

  // Función para mostrar información sobre el estado de las butacas
  void _mostrarInfoButacas() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Estado de las Butacas',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "CB", color: AppColors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusRow(Colors.grey, 'Disponible'),
              const SizedBox(height: 8),
              _buildStatusRow(Colors.green, 'Seleccionado'),
              const SizedBox(height: 8),
              _buildStatusRow(Colors.red, 'Ocupado (Reservado)')
              // No más referencias a butacas ocupadas localmente
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
                'Aceptar',
                style: TextStyle(color: AppColors.text),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(Color color, String status) {
    return Row(
      children: [
        Container(
          height: 20,
          width: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Text(status, style: const TextStyle(fontFamily: "CM")),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Los asientos reservados se cargarán cuando se seleccione día y hora

    // Inicializar timer para actualizar horarios cada minuto
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // Verificar si el horario seleccionado ya pasó
        if (selectedTime.isNotEmpty &&
            selectedDay == DateTime.now().day &&
            _isTimePassed(selectedTime)) {
          selectedTime = '';
          selectedSeats.clear();
          totalPrice = 0.0;
          _reservationsStream?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final Movie movie = arguments['movie'];
    final dynamic userData = arguments['userData'];

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
          style: const TextStyle(
            fontSize: 19,
            fontFamily: "CB",
          ),
        ),
        actions: [
          IconButton(
            onPressed: _mostrarInfoButacas,
            icon: Icon(
              Icons.info,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenido superior fijo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      capitalizedDate,
                      style: const TextStyle(fontSize: 28, fontFamily: "CB"),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Cine',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: "CB", color: AppColors.red)),
                              content: const Text(
                                  "El horario de apertura es a la 1:00 PM y el de cierre y venta de boletos a las 11:00 PM\n\n",
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(fontFamily: "CM")),
                              actions: [
                                MaterialButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  color: AppColors.acentColor,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Aceptar',
                                    style: TextStyle(color: AppColors.text),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: Icon(
                        Icons.info,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  "Día:",
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                    fontFamily: "CB",
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: daysInMonth -
                        now.day +
                        1, // Solo días desde hoy en adelante
                    itemBuilder: (context, index) {
                      final day =
                          now.day + index; // Comenzar desde el día actual
                      final isToday = day == now.day;
                      final isSelected = day == selectedDay;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = day;
                            selectedSeats.clear();
                            totalPrice = 0.0;

                            // Si el horario seleccionado ya pasó para el día de hoy, resetear
                            if (isToday &&
                                selectedTime.isNotEmpty &&
                                _isTimePassed(selectedTime)) {
                              selectedTime = '';
                            }

                            // Recargar butacas ocupadas cuando cambie el día
                            if (selectedTime.isNotEmpty) {
                              _subscribeToReservations(
                                movie.id.toString(),
                                '$selectedDay/${now.month}/${now.year}',
                                selectedTime,
                              );
                            }
                          });
                        },
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.red
                                : isToday
                                    ? AppColors.acentColor
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDarkMode
                                  ? AppColors.lightColor
                                  : AppColors.darkColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: "CB",
                                color: isSelected || isToday
                                    ? Colors.white
                                    : isDarkMode
                                        ? AppColors.lightColor
                                        : AppColors.darkColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Hora:",
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                    fontFamily: "CB",
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['14:00', '17:00', '20:00', '22:30'].map((time) {
                    final isSelected = time == selectedTime;
                    final canSelect = _canSelectTime(time);

                    return GestureDetector(
                      onTap: canSelect
                          ? () {
                              setState(() {
                                selectedTime = time;
                                selectedSeats.clear();
                                totalPrice = 0.0;
                                // Cargar butacas ocupadas para la nueva hora seleccionada
                                _subscribeToReservations(
                                  movie.id.toString(),
                                  '$selectedDay/${now.month}/${now.year}',
                                  selectedTime,
                                );
                              });
                            }
                          : null, // Deshabilitar tap si no se puede seleccionar
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !canSelect
                              ? Colors.grey.withOpacity(0.3) // Horario pasado
                              : isSelected
                                  ? AppColors.red
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !canSelect
                                ? Colors.grey.withOpacity(0.3)
                                : isDarkMode
                                    ? AppColors.lightColor.withOpacity(0.5)
                                    : AppColors.darkColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "CB",
                            color: !canSelect
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : isDarkMode
                                        ? AppColors.lightColor
                                        : AppColors.darkColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

          // Contenido con scroll (butacas)
          if (selectedTime.isNotEmpty) ...[
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Asientos:",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? AppColors.lightColor
                                : AppColors.darkColor,
                            fontFamily: "CB",
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Pantalla del cine
                        Container(
                          height: 15,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.acentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'PANTALLA',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "CB",
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),

                  // Área de butacas con scroll
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: List.generate(5, (i) {
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
                                  children: List.generate(
                                    seatsInRow,
                                    (j) {
                                      int seatNumber =
                                          seatsInPreviousRows + j + 1;
                                      bool isReserved =
                                          reservedSeats.contains(seatNumber);
                                      bool isSelected =
                                          selectedSeats.contains(seatNumber);
                                      bool isAnyOccupied = isReserved;

                                      return GestureDetector(
                                        onTap: () {
                                          if (!isAnyOccupied) {
                                            setState(() {
                                              if (isSelected) {
                                                selectedSeats
                                                    .remove(seatNumber);
                                                totalPrice -= ticketPrice;
                                              } else {
                                                selectedSeats.add(seatNumber);
                                                totalPrice += ticketPrice;
                                              }
                                              totalPrice = double.parse(
                                                  totalPrice
                                                      .toStringAsFixed(2));
                                            });
                                          }
                                        },
                                        child: Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.1,
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
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.07,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.07,
                                                color: Colors.white,
                                              ),
                                              Center(
                                                child: Text(
                                                  'B$seatNumber',
                                                  style: TextStyle(
                                                    color: AppColors.darkColor,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.025,
                                                    fontFamily: "CS",
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Información y leyenda compacta
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Bs/ $ticketPrice por butaca",
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: "CB",
                                color: isDarkMode
                                    ? AppColors.lightColor
                                    : AppColors.darkColor,
                              ),
                            ),
                            if (selectedSeats.isNotEmpty)
                              Text(
                                "Total: Bs/ ${totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: "CB",
                                  color: AppColors.red,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: [
                            _buildLegendItem(Colors.grey, 'Disponible'),
                            _buildLegendItem(Colors.green, 'Seleccionado'),
                            _buildLegendItem(Colors.red, 'Ocupado'),
                            _buildLegendItem(Colors.orange, 'Local'),
                          ],
                        ),
                        if (selectedSeats.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Asientos: ${selectedSeats.map((seat) => 'B$seat').join(', ')}",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: "CM",
                              color: isDarkMode
                                  ? AppColors.lightColor
                                  : AppColors.darkColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Botón inferior fijo
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: MaterialButtomWidget(
              title: selectedSeats.isEmpty
                  ? "Selecciona asientos"
                  : "Continuar (${selectedSeats.length} asientos)",
              color: selectedSeats.isEmpty ? Colors.grey : AppColors.red,
              onPressed: selectedSeats.isEmpty || selectedTime.isEmpty
                  ? () {} // Función vacía en lugar de null
                  : () {
                      _crearReservaYNavegar(movie, userData, now);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 15,
            width: 15,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontFamily: "CM", fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Método para crear reserva temporal y navegar
  void _crearReservaYNavegar(
      Movie movie, dynamic userData, DateTime now) async {
    try {
      // Crear reserva temporal antes de navegar
      final tempReservationRef =
          FirebaseFirestore.instance.collection('temp_reservations').doc();

      await tempReservationRef.set({
        'movieId': movie.id.toString(),
        'seats': selectedSeats,
        'date': '$selectedDay/${now.month}/${now.year}',
        'time': selectedTime,
        'userId': userData['uid'] ?? 'anonymous',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': FieldValue.serverTimestamp(),
      });

      // Navegar a la página de detalle de compra
      Navigator.pushNamed(
        context,
        '/detalleCompra',
        arguments: {
          'movie': movie,
          'userData': userData,
          'selectedDay': '$selectedDay/${now.month}/${now.year}',
          'selectedTime': selectedTime,
          'selectedSeats': selectedSeats,
          'totalPrice': totalPrice,
          'reservationId': tempReservationRef.id,
        },
      );
    } catch (e) {
      print('Error creating temporary reservation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la reserva temporal'),
          ),
        );
      }
    }
  }

  // Función para verificar si un horario ya pasó en el día actual
  bool _isTimePassed(String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final timeToday = DateTime(now.year, now.month, now.day, hour, minute);
    return now.isAfter(timeToday);
  }

  // Función para verificar si se puede seleccionar un horario
  bool _canSelectTime(String time) {
    final now = DateTime.now();

    // Si el día seleccionado es el día de hoy, verificar si el horario ya pasó
    if (selectedDay == now.day) {
      return !_isTimePassed(time);
    }

    // Si es un día futuro, todos los horarios están disponibles
    return true;
  }
}
