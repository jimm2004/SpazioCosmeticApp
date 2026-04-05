import 'package:flutter/material.dart';

class DespachoPage extends StatelessWidget {
  const DespachoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Despacho'),
      ),
      body: const Center(
        child: Text(
          'Página de despacho',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}