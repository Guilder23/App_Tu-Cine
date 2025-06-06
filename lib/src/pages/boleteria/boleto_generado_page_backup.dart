import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:peliculas/src/models/movie_models.dart';
import 'package:peliculas/src/utils/colors.dart';
import 'package:peliculas/src/utils/dark_mode_extension.dart';
import 'package:peliculas/src/pages/inicio_page.dart';
import 'package:peliculas/src/widgets/materialbuttom_widget.dart';
import 'package:ticket_widget/ticket_widget.dart';

class BoletoGeneradoPage extends StatefulWidget {
  const BoletoGeneradoPage({Key? key}) : super(key: key);

  @override
  State<BoletoGeneradoPage> createState() => _BoletoGeneradoPageState();
}

class _BoletoGeneradoPageState extends State<BoletoGeneradoPage> {
  bool isGeneratingPDF = false;

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
    final double totalPriceFinal = arguments['totalPriceFinal'];    // Debug: Imprimir datos procesados
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
    }    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkColor : AppColors.lightColor,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkColor : AppColors.lightColor,
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
      ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mensaje de éxito
            Container(
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
                      '¡Pago procesado exitosamente!\\nTus boletas están listas',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.lightColor
                            : AppColors.darkColor,
                        fontFamily: "CB",
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Información de la compra
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                        color: isDarkMode
                            ? AppColors.lightColor
                            : AppColors.darkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.confirmation_number, 'ID Compra',
                        compraId, isDarkMode),
                    _buildInfoRow(
                        Icons.movie, 'Película', movie.title, isDarkMode),
                    _buildInfoRow(
                        Icons.calendar_today, 'Fecha', selectedDay, isDarkMode),
                    _buildInfoRow(
                        Icons.access_time, 'Hora', selectedTime, isDarkMode),
                    _buildInfoRow(
                        Icons.event_seat,
                        'Butacas',
                        selectedSeats.map((seat) => 'B$seat').join(', '),
                        isDarkMode),
                    _buildInfoRow(
                        Icons.attach_money,
                        'Total Pagado',
                        'Bs/ ${totalPriceFinal.toStringAsFixed(2)}',
                        isDarkMode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Boletas individuales por butaca
            Text(
              'Boletas Individuales (${selectedSeats.length})',
              style: TextStyle(
                fontSize: 18,
                fontFamily: "CB",
                color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
              ),
            ),
            const SizedBox(height: 12),

            // Debug: Mostrar información básica antes de las boletas
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.yellow.withOpacity(0.3),
              child: Text(
                'DEBUG: selectedSeats.length = ${selectedSeats.length}, seats = $selectedSeats',
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
            const SizedBox(height: 8),

            // Test: Mostrar boletas con contenedores simples primero
            ...selectedSeats.asMap().entries.map((entry) {
              int index = entry.key;
              int seat = entry.value;

              print(
                  'DEBUG - Generando boleta para butaca $seat (índice $index)');

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.acentColor, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOLETA #${index + 1} - BUTACA B$seat',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "CB",
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Película: ${movie.title}'),
                    Text('Fecha: $selectedDay'),
                    Text('Hora: $selectedTime'),
                    Text('Butaca: B$seat'),
                    Text(
                        'Precio: Bs/ ${(totalPrice / selectedSeats.length).toStringAsFixed(2)}'),
                    Text('ID Compra: $compraId'),
                  ],
                ),
              );
            }).toList(),

            // Boleta de productos (si hay)
            if (selectedProducts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Boleta de Productos',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "CB",
                  color:
                      isDarkMode ? AppColors.lightColor : AppColors.darkColor,
                ),
              ),
              const SizedBox(height: 12),
              TicketWidget(
                width: double.infinity,
                height: 320,
                isCornerRounded: true,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'CINE - PRODUCTOS',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "CB",
                          color: AppColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTicketRow('Película:', movie.title),
                    _buildTicketRow('Fecha:', selectedDay),
                    _buildTicketRow('Hora:', selectedTime),
                    _buildTicketRow('ID Compra:', compraId),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Productos:',
                      style: TextStyle(fontSize: 14, fontFamily: "CB"),
                    ),
                    const SizedBox(height: 4),
                    ...selectedProducts
                        .map((product) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      product['nombre'] ?? 'Producto',
                                      style: TextStyle(
                                          fontSize: 12, fontFamily: "CM"),
                                    ),
                                  ),
                                  Text(
                                    'Bs/ ${(product['precio'] ?? 0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 12, fontFamily: "CM"),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    const SizedBox(height: 8),
                    const Divider(),
                    _buildTicketRow('Total Productos:',
                        'Bs/ ${productTotalPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Presenta esta boleta en el cine',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: "CM",
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: MaterialButtomWidget(
                    title: isGeneratingPDF ? "Generando..." : "Generar PDF",
                    color: isGeneratingPDF ? Colors.grey : AppColors.acentColor,
                    onPressed: isGeneratingPDF
                        ? () {}
                        : () => _generatePDF(context, arguments),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MaterialButtomWidget(
                    title: "Ir al Inicio",
                    color: AppColors.red,
                    onPressed: () => _navigateToHome(context, userData),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontFamily: "CB",
              color: isDarkMode ? AppColors.lightColor : AppColors.darkColor,
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, fontFamily: "CB"),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontFamily: "CM"),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDF(BuildContext context, Map arguments) async {
    setState(() {
      isGeneratingPDF = true;
    });

    try {
      final Movie movie = arguments['movie'];
      final String selectedDay = arguments['selectedDay'];
      final String selectedTime = arguments['selectedTime'];
      final List<int> selectedSeats =
          List<int>.from(arguments['selectedSeats']);
      final double totalPrice = arguments['totalPrice'];
      final List<Map<String, dynamic>> selectedProducts =
          List<Map<String, dynamic>>.from(arguments['selectedProducts'] ?? []);
      final double productTotalPrice = arguments['productTotalPrice'] ?? 0.0;
      final String compraId = arguments['compraId'];
      final double totalPriceFinal = arguments['totalPriceFinal'];

      final pdf = pw.Document();

      // Página con todas las boletas
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            List<pw.Widget> content = [];

            // Título principal
            content.add(
              pw.Header(
                level: 0,
                child: pw.Text(
                  'BOLETAS DE CINE',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
            );

            content.add(pw.SizedBox(height: 20));

            // Información general
            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('INFORMACIÓN DE LA COMPRA',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('ID Compra: $compraId'),
                    pw.Text('Película: ${movie.title}'),
                    pw.Text('Fecha: $selectedDay'),
                    pw.Text('Hora: $selectedTime'),
                    pw.Text(
                        'Butacas: ${selectedSeats.map((seat) => 'B$seat').join(', ')}'),
                    pw.Text(
                        'Total Pagado: Bs/ ${totalPriceFinal.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            );

            content.add(pw.SizedBox(height: 30));

            // Boletas individuales
            content.add(
              pw.Text(
                'BOLETAS INDIVIDUALES',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            );

            content.add(pw.SizedBox(height: 16));

            for (int seat in selectedSeats) {
              content.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text(
                          'CINE - ENTRADA',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text('Película: ${movie.title}'),
                      pw.Text('Fecha: $selectedDay'),
                      pw.Text('Hora: $selectedTime'),
                      pw.Text('Butaca: B$seat'),
                      pw.Text(
                          'Precio: Bs/ ${(totalPrice / selectedSeats.length).toStringAsFixed(2)}'),
                      pw.Text('ID Compra: $compraId'),
                      pw.SizedBox(height: 8),
                      pw.Divider(),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: pw.Text(
                          'Presenta esta boleta en el cine',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Boleta de productos si hay
            if (selectedProducts.isNotEmpty) {
              content.add(pw.SizedBox(height: 30));
              content.add(
                pw.Text(
                  'BOLETA DE PRODUCTOS',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              );
              content.add(pw.SizedBox(height: 16));

              content.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text(
                          'CINE - PRODUCTOS',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text('Película: ${movie.title}'),
                      pw.Text('Fecha: $selectedDay'),
                      pw.Text('Hora: $selectedTime'),
                      pw.Text('ID Compra: $compraId'),
                      pw.SizedBox(height: 8),
                      pw.Divider(),
                      pw.SizedBox(height: 8),
                      pw.Text('Productos:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ...selectedProducts
                          .map((product) => pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(product['nombre'] ?? 'Producto'),
                                  pw.Text(
                                      'Bs/ ${(product['precio'] ?? 0).toStringAsFixed(2)}'),
                                ],
                              ))
                          .toList(),
                      pw.SizedBox(height: 8),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Productos:',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Bs/ ${productTotalPrice.toStringAsFixed(2)}',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Center(
                        child: pw.Text(
                          'Presenta esta boleta en el cine',
                          style: pw.TextStyle(
                              fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return content;
          },
        ),
      );

      // Guardar y compartir PDF
      final Uint8List bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'boletas_cine_$compraId.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
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
  void _navigateToHome(BuildContext context, dynamic userData) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => InicioPage(userData: userData),
      ),
      (Route<dynamic> route) => false,
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
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.darkColor : AppColors.lightColor,
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
      ),
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
                  const Text('No se encontraron datos de butacas para esta compra'),
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
          Container(
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
                      color: isDarkMode
                          ? AppColors.lightColor
                          : AppColors.darkColor,
                      fontFamily: "CB",
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Información de la compra
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
                      color: isDarkMode
                          ? AppColors.lightColor
                          : AppColors.darkColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.confirmation_number, 'ID Compra',
                      compraId, isDarkMode),
                  _buildInfoRow(
                      Icons.movie, 'Película', movie.title, isDarkMode),
                  _buildInfoRow(
                      Icons.calendar_today, 'Fecha', selectedDay, isDarkMode),
                  _buildInfoRow(
                      Icons.access_time, 'Hora', selectedTime, isDarkMode),
                  _buildInfoRow(
                      Icons.event_seat,
                      'Butacas',
                      selectedSeats.map((seat) => 'B$seat').join(', '),
                      isDarkMode),
                  _buildInfoRow(
                      Icons.attach_money,
                      'Total Pagado',
                      'Bs/ ${totalPriceFinal.toStringAsFixed(2)}',
                      isDarkMode),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Boletas individuales por butaca
          ...selectedSeats.map((seatNumber) => _buildTicketCard(
                context,
                isDarkMode,
                movie,
                selectedDay,
                selectedTime,
                seatNumber,
                totalPrice / selectedSeats.length,
                compraId,
              )),

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
          Row(
            children: [
              Expanded(
                child: MaterialButtonWidget(
                  onPressed: () => _generatePDF(
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
                  text: isGeneratingPDF ? 'Generando...' : 'Generar PDF',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MaterialButtonWidget(
                  onPressed: () => _navigateToHome(context, userData),
                  text: 'Generar Boletas', // Cambiado de "Inicio"
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
