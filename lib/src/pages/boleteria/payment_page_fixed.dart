import 'package:flutter/material.dart';

class PaymentPageFixed extends StatelessWidget {
  const PaymentPageFixed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
      ),
      body: const Center(
        child: Text('Pantalla de pago'),
      ),
    );
  }
}
