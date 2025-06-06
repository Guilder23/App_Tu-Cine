import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/pages/inicio_page.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:ticket_widget/ticket_widget.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BoletoGeneradoPage extends StatefulWidget {
  const BoletoGeneradoPage({Key? key}) : super(key: key);

  @override
  State<BoletoGeneradoPage> createState() => _BoletoGeneradoPageState();
}

class _BoletoGeneradoPageState extends State<BoletoGeneradoPage> {
  bool isGeneratingPDF = false;
  bool pdfGenerated =
      false; // Variable para controlar si el PDF ya fue generado
  bool isSharing = false; // Variable para controlar el estado de compartir
  Uint8List? pdfBytes; // Almacenar los bytes del PDF generado

  // Función para recuperar datos de la compra desde Firestore
  Future<List<int>> _getSelectedSeatsFromFirestore(String compraId) async {
    try {
      print('DEBUG - Recuperando butacas desde Firestore con ID: $compraId');

      DocumentSnapshot compraDoc = await FirebaseFirestore.instance
          .collection('compras')
          .doc(compraId)
          .get();

      if (compraDoc.exists) {
        Map<String, dynamic> data = compraDoc.data() as Map<String, dynamic>;
        List<dynamic> butacas = data['butacas'] ?? [];
        List<int> selectedSeats = List<int>.from(butacas);

        print('DEBUG - Butacas recuperadas de Firestore: $selectedSeats');
        return selectedSeats;
      } else {
        print('DEBUG - Documento de compra no encontrado');
        return [];
      }
    } catch (e) {
      print('DEBUG - Error al recuperar butacas: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = context.isDarkMode;
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;

    // Debug: Imprimir argumentos recibidos
    print('DEBUG - Argumentos recibidos:');
    print('Arguments: $arguments');
    print('SelectedSeats raw: ${arguments['selectedSeats']}');
    print('SelectedSeats type: ${arguments['selectedSeats'].runtimeType}');

    // Obtener datos de la compra
    final Movie movie = arguments['movie'];
    final dynamic userData = arguments['userData'];
    final String selectedDay = arguments['selectedDay'];
    final String selectedTime = arguments['selectedTime'];
    List<int> selectedSeats = List<int>.from(arguments['selectedSeats']);
    final double totalPrice = arguments['totalPrice'];
    final List<Map<String, dynamic>> selectedProducts =
        List<Map<String, dynamic>>.from(arguments['selectedProducts'] ?? []);
    final double productTotalPrice = arguments['productTotalPrice'] ?? 0.0;
    final String compraId = arguments['compraId'];
    final double totalPriceFinal = arguments['totalPriceFinal'];

    // Debug: Imprimir datos procesados
    print('DEBUG - Datos procesados:');
    print('SelectedSeats processed: $selectedSeats');
    print('SelectedSeats length: ${selectedSeats.length}');
    print('Movie: ${movie.title}');
    print('CompraId: $compraId');

    // Si selectedSeats está vacío, usar FutureBuilder para recuperar desde Firestore
    if (selectedSeats.isEmpty && compraId.isNotEmpty) {
      return _buildWithFirestoreData(
        context,
        isDarkMode,
        movie,
        userData,
        selectedDay,
        selectedTime,
        totalPrice,
        selectedProducts,
        productTotalPrice,
        compraId,
        totalPriceFinal,
      );
    }

    // Si tenemos datos, construir la página normal
    return _buildScaffoldWithContent(
      context,
      isDarkMode,
      movie,
      userData,
      selectedDay,
      selectedTime,
      selectedSeats,
      totalPrice,
      selectedProducts,
      productTotalPrice,
      compraId,
      totalPriceFinal,
    );
  }

  // Método para construir la página con datos de Firestore cuando selectedSeats está vacío
  Widget _buildWithFirestoreData(
    BuildContext context,
    bool isDarkMode,
    Movie movie,
    dynamic userData,
    String selectedDay,
    String selectedTime,
    double totalPrice,
    List<Map<String, dynamic>> selectedProducts,
    double productTotalPrice,
    String compraId,
    double totalPriceFinal,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkColor : AppColors.lightColor,
      appBar: _buildAppBar(isDarkMode),
      body: FutureBuilder<List<int>>(
        future: _getSelectedSeatsFromFirestore(compraId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos de la compra...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error al cargar los datos: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          List<int> retrievedSeats = snapshot.data ?? [];

          if (retrievedSeats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                      'No se encontraron datos de butacas para esta compra'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToHome(context, userData),
                    child: const Text('Volver al Inicio'),
                  ),
                ],
              ),
            );
          }

          // Usar los datos recuperados para construir la página normal
          return _buildTicketContent(
            context,
            isDarkMode,
            movie,
            userData,
            selectedDay,
            selectedTime,
            retrievedSeats,
            totalPrice,
            selectedProducts,
            productTotalPrice,
            compraId,
            totalPriceFinal,
          );
        },
      ),
    );
  }

  // Método para construir Scaffold con contenido cuando tenemos datos
  Widget _buildScaffoldWithContent(
    BuildContext context,
    bool isDarkMode,
    Movie movie,
    dynamic userData,
    String selectedDay,
    String selectedTime,
    List<int> selectedSeats,
    double totalPrice,
    List<Map<String, dynamic>> selectedProducts,
    double productTotalPrice,
    String compraId,
    double totalPriceFinal,
  ) {
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkColor : AppColors.lightColor,
      appBar: _buildAppBar(isDarkMode),
      body: _buildTicketContent(
        context,
        isDarkMode,
        movie,
        userData,
        selectedDay,
        selectedTime,
        selectedSeats,
        totalPrice,
        selectedProducts,
        productTotalPrice,
        compraId,
        totalPriceFinal,
      ),
    );
  }

  // AppBar común
  AppBar _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: isDarkMode ? AppColors.darkColor : AppColors.lightColor,
      iconTheme: IconThemeData(
        color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
      ),
      centerTitle: true,
      title: Text(
        'Boletas Generadas',
        style: TextStyle(
          color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          fontFamily: "CB",
        ),
      ),
      automaticallyImplyLeading: false,
    );
  }

  // Método para construir el contenido de las boletas
  Widget _buildTicketContent(
    BuildContext context,
    bool isDarkMode,
    Movie movie,
    dynamic userData,
    String selectedDay,
    String selectedTime,
    List<int> selectedSeats,
    double totalPrice,
    List<Map<String, dynamic>> selectedProducts,
    double productTotalPrice,
    String compraId,
    double totalPriceFinal,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mensaje de éxito
          _buildSuccessMessage(isDarkMode),
          const SizedBox(height: 20),

          // Información de la compra
          _buildPurchaseInfo(
            isDarkMode,
            movie,
            selectedDay,
            selectedTime,
            selectedSeats,
            compraId,
            totalPriceFinal,
          ),
          const SizedBox(height: 20),

          // Boletas individuales por butaca
          _buildIndividualTickets(
            context,
            isDarkMode,
            movie,
            selectedDay,
            selectedTime,
            selectedSeats,
            totalPrice,
            compraId,
          ),
          const SizedBox(height: 20),

          // Boleta de productos (si hay productos)
          if (selectedProducts.isNotEmpty) ...[
            _buildProductTicket(
              context,
              isDarkMode,
              selectedProducts,
              productTotalPrice,
              compraId,
            ),
            const SizedBox(height: 20),
          ],

          // Botones de acción
          _buildActionButtons(
            context,
            isDarkMode,
            userData,
            movie,
            selectedDay,
            selectedTime,
            selectedSeats,
            totalPrice,
            selectedProducts,
            productTotalPrice,
            compraId,
            totalPriceFinal,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Mensaje de éxito
  Widget _buildSuccessMessage(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '¡Pago procesado exitosamente!\nTus boletas están listas',
              style: TextStyle(
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                fontFamily: "CB",
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Información de la compra
  Widget _buildPurchaseInfo(
    bool isDarkMode,
    Movie movie,
    String selectedDay,
    String selectedTime,
    List<int> selectedSeats,
    String compraId,
    double totalPriceFinal,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Compra',
              style: TextStyle(
                fontSize: 18,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.confirmation_number, 'ID Compra', compraId, isDarkMode),
            _buildInfoRow(Icons.movie, 'Película', movie.title, isDarkMode),
            _buildInfoRow(
                Icons.calendar_today, 'Fecha', selectedDay, isDarkMode),
            _buildInfoRow(Icons.access_time, 'Hora', selectedTime, isDarkMode),
            _buildInfoRow(
              Icons.event_seat,
              'Butacas',
              selectedSeats.map((seat) => 'B$seat').join(', '),
              isDarkMode,
            ),
            _buildInfoRow(
              Icons.attach_money,
              'Total Pagado',
              'Bs/ ${totalPriceFinal.toStringAsFixed(2)}',
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  // Fila de información
  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Alineación vertical al inicio
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80, // Ancho fijo para las etiquetas
            child: Text(
              '$label: ',
              style: TextStyle(
                fontSize: 14,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontFamily: "CM",
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
              ),
              softWrap: true, // Permite saltos de línea
              overflow: TextOverflow.ellipsis,
              maxLines: 2, // Permite hasta 2 líneas
            ),
          ),
        ],
      ),
    );
  }

  // Boletas individuales
  Widget _buildIndividualTickets(
    BuildContext context,
    bool isDarkMode,
    Movie movie,
    String selectedDay,
    String selectedTime,
    List<int> selectedSeats,
    double totalPrice,
    String compraId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boletas Individuales (${selectedSeats.length})',
          style: TextStyle(
            fontSize: 18,
            fontFamily: "CB",
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 12),
        ...selectedSeats.map((seatNumber) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTicketCard(
                context,
                isDarkMode,
                movie,
                selectedDay,
                selectedTime,
                seatNumber,
                totalPrice / selectedSeats.length,
                compraId,
              ),
            )),
      ],
    );
  }

  // Tarjeta de boleta individual
  Widget _buildTicketCard(
    BuildContext context,
    bool isDarkMode,
    Movie movie,
    String selectedDay,
    String selectedTime,
    int seatNumber,
    double seatPrice,
    String compraId,
  ) {
    return TicketWidget(
      width: MediaQuery.of(context).size.width - 32,
      height: 185, // Aumentado ligeramente para mejor espacio
      isCornerRounded: true,
      padding:
          const EdgeInsets.all(16), // Restaurado para evitar efecto perforado
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Añadido para optimizar espacio
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                // Añadido Flexible
                child: Text(
                  'BOLETA DE CINE',
                  style: TextStyle(
                    fontSize: 14, // Reducido de 16 a 14
                    fontFamily: "CB",
                    color:
                        isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                  ),
                ),
              ),
              Text(
                'B$seatNumber',
                style: TextStyle(
                  fontSize: 18, // Reducido de 20 a 18
                  fontFamily: "CB",
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reducido de 12 a 8
          _buildTicketRow('Película:', movie.title),
          _buildTicketRow('Fecha:', selectedDay),
          _buildTicketRow('Hora:', selectedTime),
          _buildTicketRow('Butaca:', 'B$seatNumber'),
          _buildTicketRow('Precio:', 'Bs/ ${seatPrice.toStringAsFixed(2)}'),
          _buildTicketRow('ID Compra:', compraId),
        ],
      ),
    );
  }

  // Fila de ticket - Optimizada para evitar desbordamiento y efecto perforado
  Widget _buildTicketRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 8.0, vertical: 1.0), // Margen para evitar perforado
      padding: const EdgeInsets.symmetric(vertical: 1.0), // Padding interno
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11, // Ligeramente más grande para mejor legibilidad
                fontFamily: "CB",
                height: 1.2, // Altura de línea mejorada
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8), // Espacio más generoso entre columnas
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11, // Tamaño consistente
                fontFamily: "CM",
                height: 1.2, // Altura de línea mejorada
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Boleta de productos
  Widget _buildProductTicket(
    BuildContext context,
    bool isDarkMode,
    List<Map<String, dynamic>> selectedProducts,
    double productTotalPrice,
    String compraId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Boleta de Productos',
          style: TextStyle(
            fontSize: 18,
            fontFamily: "CB",
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
        ),
        const SizedBox(height: 12),
        TicketWidget(
          width: MediaQuery.of(context).size.width - 32,
          height: 150 + (selectedProducts.length * 25.0),
          isCornerRounded: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BOLETA DE PRODUCTOS',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: "CB",
                  color:
                      isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                ),
              ),
              const SizedBox(height: 12),
              ...selectedProducts.map((product) => _buildTicketRow(
                    '${product['nombre'] ?? 'Producto'} x${product['cantidad'] ?? 1}:',
                    'Bs/ ${((product['precio'] ?? 0.0) * (product['cantidad'] ?? 1)).toStringAsFixed(2)}',
                  )),
              const Divider(),
              _buildTicketRow(
                  'Total:', 'Bs/ ${productTotalPrice.toStringAsFixed(2)}'),
              _buildTicketRow('ID Compra:', compraId),
            ],
          ),
        ),
      ],
    );
  }

  // Botones de acción
  Widget _buildActionButtons(
    BuildContext context,
    bool isDarkMode,
    dynamic userData,
    Movie movie,
    String selectedDay,
    String selectedTime,
    List<int> selectedSeats,
    double totalPrice,
    List<Map<String, dynamic>> selectedProducts,
    double productTotalPrice,
    String compraId,
    double totalPriceFinal,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MaterialButtomWidget(
                onPressed: () => _downloadPDF(
                  context,
                  movie,
                  selectedDay,
                  selectedTime,
                  selectedSeats,
                  totalPrice,
                  selectedProducts,
                  productTotalPrice,
                  compraId,
                  totalPriceFinal,
                ),
                title: isGeneratingPDF ? 'Descargando...' : 'Descargar PDF',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MaterialButtomWidget(
                onPressed: (pdfGenerated && pdfBytes != null)
                    ? () => _sharePDF(context, compraId)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Primero debes descargar el PDF'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                title: isSharing ? 'Compartiendo...' : 'Compartir PDF',
                color: pdfGenerated && pdfBytes != null
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MaterialButtomWidget(
          onPressed: () {
            if (pdfGenerated) {
              _navigateToHome(context, userData);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Primero debes descargar las boletas en PDF'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          title: 'Volver al Inicio',
          color: pdfGenerated ? Colors.red : Colors.grey,
        ),
      ],
    );
  }

  // Método para descargar PDF
  Future<void> _downloadPDF(
    BuildContext context,
    Movie movie,
    String selectedDay,
    String selectedTime,
    List<int> selectedSeats,
    double totalPrice,
    List<Map<String, dynamic>> selectedProducts,
    double productTotalPrice,
    String compraId,
    double totalPriceFinal,
  ) async {
    setState(() {
      isGeneratingPDF = true;
    });

    try {
      final pdf = pw.Document();

      // Página de boletas individuales
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BOLETAS DE CINE',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                ...selectedSeats.map((seatNumber) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 20),
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('BOLETA DE CINE',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text('Butaca B$seatNumber',
                                  style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text('Película: ${movie.title}'),
                          pw.Text('Fecha: $selectedDay'),
                          pw.Text('Hora: $selectedTime'),
                          pw.Text('Butaca: B$seatNumber'),
                          pw.Text(
                              'Precio: Bs/ ${(totalPrice / selectedSeats.length).toStringAsFixed(2)}'),
                          pw.Text('ID Compra: $compraId'),
                        ],
                      ),
                    )),
              ],
            );
          },
        ),
      );

      // Página de productos si hay
      if (selectedProducts.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'BOLETA DE PRODUCTOS',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        ...selectedProducts.map((product) => pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                    '${product['nombre'] ?? 'Producto'} x${product['cantidad'] ?? 1}'),
                                pw.Text(
                                    'Bs/ ${((product['precio'] ?? 0.0) * (product['cantidad'] ?? 1)).toStringAsFixed(2)}'),
                              ],
                            )),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total:',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                'Bs/ ${productTotalPrice.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text('ID Compra: $compraId',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      // Guardar los bytes del PDF
      final bytes = await pdf.save();
      setState(() {
        pdfBytes = bytes;
      });

      // Descargar PDF directamente sin vista previa
      final result = await Printing.sharePdf(
        bytes: bytes,
        filename: 'boletas_cine_$compraId.pdf',
      );

      if (mounted) {
        setState(() {
          pdfGenerated = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result
                ? 'PDF descargado exitosamente'
                : 'PDF generado correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingPDF = false;
        });
      }
    }
  }

  // Método para compartir PDF
  Future<void> _sharePDF(BuildContext context, String compraId) async {
    if (pdfBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes descargar el PDF'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isSharing = true;
    });

    try {
      // Crear archivo temporal para compartir
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/boletas_cine_$compraId.pdf');
      await file.writeAsBytes(pdfBytes!);

      // Compartir usando share_plus
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mis boletas de cine - ID: $compraId',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF compartido exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSharing = false;
        });
      }
    }
  }

  // Navegar al inicio
  void _navigateToHome(BuildContext context, dynamic userData) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => InicioPage(userData: userData),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
