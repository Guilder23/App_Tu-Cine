import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BoleteriaPage extends StatefulWidget {
  const BoleteriaPage({Key? key}) : super(key: key);

  @override
  State<BoleteriaPage> createState() => _BoleteriaPageState();
}

class _BoleteriaPageState extends State<BoleteriaPage> {
  int selectedDay = DateTime.now().day;
  String selectedTime = '';
  List<int> selectedSeats = [];
  List<int> reservedSeats = []; // Lista de butacas reservadas
  double ticketPrice = 35; // Precio de la entrada
  double totalPrice = 0.0; // Precio total inicial

  @override
  void initState() {
    super.initState();
    // Simular butacas reservadas (en una aplicación real, esto vendría de una base de datos)
    reservedSeats = [3, 8, 15, 22, 29];
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
    //primera letra en mayuscula
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
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //mostrar el mes actual
            Row(
              children: [
                Text(
                  capitalizedDate,
                  style: const TextStyle(fontSize: 28, fontFamily: "CB"),
                ),
                const Spacer(),
                //icono de informacion
                _dialogoInfoCine(isDarkMode: isDarkMode),
              ],
            ),
            const Text(
              'Selecciona el día y horario.',
              style: TextStyle(fontSize: 16, fontFamily: "CM"),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: daysInMonth - DateTime.now().day + 1,
                itemBuilder: (context, index) {
                  final date = DateTime(DateTime.now().year,
                      DateTime.now().month, DateTime.now().day + index);
                  final weekDay = DateFormat('EEE', 'es_ES').format(date);
                  final capitalizedWeekDay =
                      weekDay[0].toUpperCase() + weekDay.substring(1);
                  final isToday = DateTime.now().day + index == selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDay = DateTime.now().day + index;
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
                            Text('${DateTime.now().day + index}',
                                style: TextStyle(
                                    fontFamily: "CB",
                                    color: isDarkMode || isToday
                                        ? AppColors.lightColor
                                        : AppColors.darkColor)),
                            Text(capitalizedWeekDay,
                                style: TextStyle(
                                    fontFamily: "CM",
                                    color: isDarkMode || isToday
                                        ? AppColors.lightColor
                                        : AppColors.darkColor)),
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
                  final time = DateFormat('h:mm a').format(DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      13 + index));
                  final isSelected = time == selectedTime;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = time;
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
            const VisionScreen(),
            const SizedBox(height: 10),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                        spacing:
                            size.width * 0.02, // 2% del ancho de la pantalla
                        children: List.generate(
                          seatsInRow,
                          (j) {
                            int seatNumber = seatsInPreviousRows + j + 1;
                            return _Seat(
                              seatNumber: seatNumber,
                              isReserved: reservedSeats.contains(seatNumber),
                              onSelected: (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    selectedSeats.add(seatNumber);
                                    totalPrice += ticketPrice;
                                  } else {
                                    selectedSeats.remove(seatNumber);
                                    totalPrice -= ticketPrice;
                                  }
                                  totalPrice = double.parse(
                                      totalPrice.toStringAsFixed(2));
                                });
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
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
                Row(
                  children: [
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Disponible',
                      style: TextStyle(fontFamily: "CM"),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Seleccionado',
                      style: TextStyle(fontFamily: "CM"),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Reservado',
                      style: TextStyle(fontFamily: "CM"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            MaterialButtomWidget(
              color: AppColors.red,
              title: 'Continuar',
              onPressed: () {
                if (selectedSeats.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Cine',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: "CB", color: AppColors.red)),
                        content: const Text(
                            "Por favor selecciona al menos un asiento para continuar",
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
                  return;
                }

                final day = DateFormat('E d, MMM yyyy', 'es_ES').format(
                    DateTime(DateTime.now().year, DateTime.now().month,
                        selectedDay));
                final newDay = day[0].toUpperCase() + day.substring(1);

                if (selectedTime.isNotEmpty) {
                  Navigator.pushNamed(context, '/detalleCompra', arguments: {
                    'movie': movie,
                    'userData': userData,
                    'selectedDay': newDay,
                    'selectedTime': selectedTime,
                    'selectedSeats': selectedSeats,
                    'totalPrice': totalPrice,
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Cine',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: "CB", color: AppColors.red)),
                        content: const Text(
                            "Por favor selecciona un horario para continuar",
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
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _dialogoInfoCine extends StatelessWidget {
  const _dialogoInfoCine({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Cine',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: "CB", color: AppColors.red)),
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
    );
  }
}

class _Seat extends StatefulWidget {
  final int seatNumber;
  final ValueChanged<bool> onSelected;
  final bool isReserved;

  const _Seat({
    Key? key,
    required this.seatNumber,
    required this.onSelected,
    this.isReserved = false,
  }) : super(key: key);

  @override
  _SeatState createState() => _SeatState();
}

class _SeatState extends State<_Seat> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final seatSize = size.width * 0.08;

    return GestureDetector(
      onTap: () {
        if (!widget.isReserved) {
          setState(() {
            isSelected = !isSelected;
          });
          widget.onSelected(isSelected);
        }
      },
      child: Container(
        height: seatSize,
        width: seatSize,
        decoration: BoxDecoration(
          color: widget.isReserved
              ? Colors.red
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
              height: seatSize * 0.8,
              width: seatSize * 0.8,
              color: Colors.white,
            ),
            Center(
              child: Text(
                'B${widget.seatNumber}',
                style: TextStyle(
                  color: AppColors.darkColor,
                  fontSize: seatSize * 0.3,
                  fontFamily: "CS",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VisionScreen extends StatelessWidget {
  const VisionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      height: 50,
      child: ClipPath(
        clipper: _VisionClipper(),
        child: CustomPaint(
          painter: _VisionPainter(),
        ),
      ),
    );
  }
}

class _VisionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, size.height);

    canvas.drawPath(path, paint);

    final screenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.white.withOpacity(0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      screenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _VisionClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
