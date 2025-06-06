import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/butacas_storage.dart';

class BoleteriaPageMejorada extends StatefulWidget {
  const BoleteriaPageMejorada({Key? key}) : super(key: key);

  @override
  State<BoleteriaPageMejorada> createState() => _BoleteriaPageMejoradaState();
}

class _BoleteriaPageMejoradaState extends State<BoleteriaPageMejorada> {
  int selectedDay = DateTime.now().day;
  String selectedTime = '';
  List<int> selectedSeats = [];
  List<int> reservedSeats = [];
  List<int> localOccupiedSeats = []; // Butacas ocupadas localmente
  double ticketPrice = 35;
  double totalPrice = 0.0;

  // Función para cargar butacas reservadas desde Firestore y localmente
  void loadReservedSeats(
      String movieId, String selectedDate, String selectedTime) async {
    try {
      // Cargar reservas desde Firestore
      final QuerySnapshot reservations = await FirebaseFirestore.instance
          .collection('reservations')
          .where('movieId', isEqualTo: movieId)
          .where('date', isEqualTo: selectedDate)
          .where('time', isEqualTo: selectedTime)
          .get();

      List<int> firestoreReservedSeats = reservations.docs
          .expand<int>((doc) => List<int>.from(doc['seats']))
          .toList(); // Cargar butacas ocupadas localmente
      List<int> localOccupied = await ButacasStorage.obtenerButacasOcupadas(
          movieId, selectedDate, selectedTime);

      if (mounted) {
        setState(() {
          reservedSeats = firestoreReservedSeats;
          localOccupiedSeats = localOccupied;
          print('Butacas reservadas en Firestore: $reservedSeats');
          print('Butacas ocupadas localmente: $localOccupiedSeats');
        });
      }
    } catch (e) {
      print('Error loading reserved seats: $e');
    }
  }

  // Función para verificar si una butaca está ocupada (Firestore o local)
  bool isSeatOccupied(int seatNumber) {
    return reservedSeats.contains(seatNumber) ||
        localOccupiedSeats.contains(seatNumber);
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
              _buildStatusRow(Colors.red, 'Ocupado (Firestore)'),
              const SizedBox(height: 8),
              _buildStatusRow(Colors.orange, 'Ocupado (Local)'),
              if (localOccupiedSeats.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Butacas ocupadas localmente: ${localOccupiedSeats.map((s) => 'B$s').join(', ')}',
                  style: const TextStyle(fontSize: 12, fontFamily: "CM"),
                ),
              ]
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
      body: Padding(
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
            const SizedBox(height: 10),
            Text(
              "Selecciona el día",
              style: TextStyle(
                fontSize: 20,
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                fontFamily: "CB",
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final isToday = day == now.day;
                  final isSelected = day == selectedDay;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = day;
                        selectedSeats.clear();
                        totalPrice = 0.0;
                        // Recargar butacas ocupadas cuando cambie el día
                        if (selectedTime.isNotEmpty) {
                          loadReservedSeats(
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
            const SizedBox(height: 20),
            Text(
              "Selecciona la hora",
              style: TextStyle(
                fontSize: 20,
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                fontFamily: "CB",
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: ['14:00', '17:00', '20:00', '22:30'].map((time) {
                final isSelected = time == selectedTime;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTime = time;
                      selectedSeats.clear();
                      totalPrice = 0.0;
                      // Cargar butacas ocupadas para la nueva hora seleccionada
                      loadReservedSeats(
                        movie.id.toString(),
                        '$selectedDay/${now.month}/${now.year}',
                        selectedTime,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.red : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.lightColor
                            : AppColors.darkColor,
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "CB",
                        color: isSelected
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
            const SizedBox(height: 20),
            if (selectedTime.isNotEmpty) ...[
              Text(
                "Selecciona tus asientos",
                style: TextStyle(
                  fontSize: 20,
                  color:
                      isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                  fontFamily: "CB",
                ),
              ),
              const SizedBox(height: 10),
              // Pantalla del cine
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.acentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'PANTALLA',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "CB",
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Asientos del cine
              Expanded(
                child: SingleChildScrollView(
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 5,
                          children: List.generate(
                            seatsInRow,
                            (j) {
                              int seatNumber = seatsInPreviousRows + j + 1;
                              bool isFirestoreReserved =
                                  reservedSeats.contains(seatNumber);
                              bool isLocalOccupied =
                                  localOccupiedSeats.contains(seatNumber);
                              bool isSelected =
                                  selectedSeats.contains(seatNumber);
                              bool isAnyOccupied =
                                  isFirestoreReserved || isLocalOccupied;

                              return GestureDetector(
                                onTap: () {
                                  if (!isAnyOccupied) {
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
                                  height:
                                      MediaQuery.of(context).size.width * 0.08,
                                  width:
                                      MediaQuery.of(context).size.width * 0.08,
                                  decoration: BoxDecoration(
                                    color: isFirestoreReserved
                                        ? Colors.red
                                        : isLocalOccupied
                                            ? Colors.orange
                                            : isSelected
                                                ? Colors.green
                                                : Colors.grey,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/icons/butaca.png',
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.064,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.064,
                                        color: Colors.white,
                                      ),
                                      Center(
                                        child: Text(
                                          'B$seatNumber',
                                          style: TextStyle(
                                            color: AppColors.darkColor,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.024,
                                            fontFamily: "CS",
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
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: Text(
                  "Precio por butaca: Bs/ $ticketPrice",
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: "CB",
                    color:
                        isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  _buildLegendItem(Colors.grey, 'Disponible'),
                  _buildLegendItem(Colors.green, 'Seleccionado'),
                  _buildLegendItem(Colors.red, 'Ocupado'),
                  _buildLegendItem(Colors.orange, 'Local'),
                ],
              ),
              const SizedBox(height: 10),
              if (selectedSeats.isNotEmpty) ...[
                Text(
                  "Asientos seleccionados: ${selectedSeats.map((seat) => 'B$seat').join(', ')}",
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: "CB",
                    color:
                        isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Total: Bs/ ${totalPrice.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: "CB",
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
            Padding(
              padding: const EdgeInsets.all(8.0),
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
}
