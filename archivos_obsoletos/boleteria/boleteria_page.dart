import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoleteriaPage extends StatefulWidget {
  const BoleteriaPage({Key? key}) : super(key: key);

  @override
  State<BoleteriaPage> createState() => _BoleteriaPageState();
}

class _BoleteriaPageState extends State<BoleteriaPage> {
  int selectedDay = DateTime.now().day;
  String selectedTime = '';
  List<int> selectedSeats = [];
  List<int> reservedSeats = [];
  double ticketPrice = 35;
  double totalPrice = 0.0;

  void loadReservedSeats(
      String movieId, String selectedDate, String selectedTime) async {
    try {
      final QuerySnapshot reservations = await FirebaseFirestore.instance
          .collection('reservations')
          .where('movieId', isEqualTo: movieId)
          .where('date', isEqualTo: selectedDate)
          .where('time', isEqualTo: selectedTime)
          .get();

      if (mounted) {
        setState(() {
          reservedSeats = reservations.docs
              .expand<int>((doc) => List<int>.from(doc['seats']))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading reserved seats: $e');
    }
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
            const Text(
              'Selecciona el día y horario.',
              style: TextStyle(fontSize: 16, fontFamily: "CM"),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 45,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: daysInMonth - DateTime.now().day + 1,
                itemBuilder: (context, index) {
                  final date = DateTime(now.year, now.month, now.day + index);
                  final weekDay = DateFormat('EEE', 'es_ES').format(date);
                  final capitalizedWeekDay =
                      weekDay[0].toUpperCase() + weekDay.substring(1);
                  final isToday = now.day + index == selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = now.day + index;
                        if (selectedTime.isNotEmpty) {
                          final formattedDate = DateFormat('yyyy-MM-dd').format(
                            DateTime(now.year, now.month, selectedDay),
                          );
                          loadReservedSeats(
                              movie.id.toString(), formattedDate, selectedTime);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday
                              ? AppColors.darkAcentsColor
                              : AppColors.red.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              '${now.day + index}',
                              style: TextStyle(
                                fontFamily: "CB",
                                color: isDarkMode || isToday
                                    ? AppColors.lightColor
                                    : AppColors.darkColor,
                              ),
                            ),
                            Text(
                              capitalizedWeekDay,
                              style: TextStyle(
                                fontFamily: "CM",
                                color: isDarkMode || isToday
                                    ? AppColors.lightColor
                                    : AppColors.darkColor,
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
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: 11,
                itemBuilder: (context, index) {
                  final time = DateFormat('h:mm a').format(
                    DateTime(now.year, now.month, now.day, 13 + index),
                  );
                  final isSelected = time == selectedTime;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = time;
                        final formattedDate = DateFormat('yyyy-MM-dd').format(
                          DateTime(now.year, now.month, selectedDay),
                        );
                        loadReservedSeats(
                            movie.id.toString(), formattedDate, selectedTime);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.red : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.darkAcentsColor
                              : AppColors.red.withOpacity(0.5),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontFamily: "CS",
                            color: isDarkMode || isSelected
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
            const SizedBox(height: 30),
            Row(
              children: [
                const Text(
                  'Selecciona tus butacas',
                  style: TextStyle(fontSize: 17, fontFamily: "CB"),
                ),
                const Spacer(),
                Text(
                  'Bs/ ${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    color:
                        isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                    fontFamily: "CB",
                  ),
                ),
              ],
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
                ),
              ),
              child: CustomPaint(
                painter: _ScreenPainter(),
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Text(
                "Pantalla del cine",
                style: TextStyle(fontSize: 17, fontFamily: "CS"),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
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
                              ? 11                              : i < 4
                                  ? 18
                                  : 26;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                        const SizedBox(height: 4),                        // Butacas de la fila
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: List.generate(
                            seatsInRow,
                            (j) {
                              int seatNumber = seatsInPreviousRows + j + 1;
                              bool isReserved = reservedSeats.contains(seatNumber);
                              bool isSelected = selectedSeats.contains(seatNumber);
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
                              height: MediaQuery.of(context).size.width * 0.1,
                              width: MediaQuery.of(context).size.width * 0.1,                              decoration: BoxDecoration(
                                color: isReserved
                                    ? Colors.red
                                    : isSelected
                                        ? Colors.green
                                        : Colors.grey,
                                borderRadius: BorderRadius.circular(5),
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
                                    height: MediaQuery.of(context).size.width *
                                        0.08,
                                    width: MediaQuery.of(context).size.width *
                                        0.08,
                                    color: Colors.white,
                                  ),
                                  Center(
                                    child: Text(
                                      'B$seatNumber',
                                      style: TextStyle(
                                        color: AppColors.darkColor,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
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
                },
              ),
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend(Colors.grey, 'Disponible'),
                _buildLegend(Colors.green, 'Seleccionado'),
                _buildLegend(Colors.red, 'Reservado'),
              ],
            ),
            const SizedBox(height: 20),
            MaterialButtomWidget(
              color: AppColors.red,
              title: 'Continuar',
              onPressed: () async {
                if (selectedSeats.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cine',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: "CB", color: AppColors.red)),
                      content: const Text(
                        "Por favor selecciona al menos un asiento para continuar",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontFamily: "CM"),
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
                    ),
                  );
                  return;
                }

                if (selectedTime.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cine',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: "CB", color: AppColors.red)),
                      content: const Text(
                        "Por favor selecciona un horario para continuar",
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontFamily: "CM"),
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
                    ),
                  );
                  return;
                }

                final day = DateFormat('E d, MMM yyyy', 'es_ES').format(
                  DateTime(now.year, now.month, selectedDay),
                );
                final newDay = day[0].toUpperCase() + day.substring(1);
                final formattedDate = DateFormat('yyyy-MM-dd').format(
                  DateTime(now.year, now.month, selectedDay),
                );

                try {
                  // Verificar si hay conflictos con asientos ya reservados
                  final reservationsCheck = await FirebaseFirestore.instance
                      .collection('reservations')
                      .where('movieId', isEqualTo: movie.id.toString())
                      .where('date', isEqualTo: formattedDate)
                      .where('time', isEqualTo: selectedTime)
                      .get();

                  final existingReservedSeats = reservationsCheck.docs
                      .expand<int>((doc) => List<int>.from(doc['seats']))
                      .toList();

                  if (selectedSeats
                      .any((seat) => existingReservedSeats.contains(seat))) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Asientos no disponibles',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: "CB", color: AppColors.red)),
                        content: const Text(
                          "Algunos de los asientos seleccionados ya han sido reservados. Por favor selecciona otros asientos.",
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
                              Navigator.pop(context);
                              // Recargar los asientos reservados
                              loadReservedSeats(movie.id.toString(),
                                  formattedDate, selectedTime);
                            },
                            child: const Text(
                              'Aceptar',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // Crear reserva temporal
                  final docRef = await FirebaseFirestore.instance
                      .collection('temp_reservations')
                      .add({
                    'movieId': movie.id.toString(),
                    'userId': userData['uid'],
                    'date': formattedDate,
                    'time': selectedTime,
                    'seats': selectedSeats,
                    'totalPrice': totalPrice,
                    'createdAt': FieldValue.serverTimestamp(),
                    'status': 'pending',
                    'expiresAt': DateTime.now()
                        .add(const Duration(minutes: 15))
                        .millisecondsSinceEpoch,
                  });

                  // Navegar a la página de detalle de compra
                  Navigator.pushNamed(
                    context,
                    '/detalleCompra',
                    arguments: {
                      'movie': movie,
                      'userData': userData,
                      'selectedDay': newDay,
                      'selectedTime': selectedTime,
                      'selectedSeats': selectedSeats,
                      'totalPrice': totalPrice,
                      'reservationId': docRef.id,
                    },
                  );
                } catch (e) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: "CB", color: AppColors.red)),
                      content: Text(
                        "Error al procesar la reserva: ${e.toString()}",
                        textAlign: TextAlign.justify,
                        style: const TextStyle(fontFamily: "CM"),
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
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
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
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontFamily: "CM"),
        ),
      ],
    );
  }
}

class _ScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
