import 'package:flutter/material.dart';

class HistorialDespachoPage extends StatelessWidget {
  const HistorialDespachoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de despacho'),
      ),
      body: const Center(
        child: Text(
          'Página de historial de despacho',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}