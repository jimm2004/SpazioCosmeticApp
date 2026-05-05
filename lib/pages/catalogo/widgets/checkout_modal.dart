import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutModal extends StatefulWidget {
  final String phone;

  const CheckoutModal({super.key, required this.phone});

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();

  Future<void> _confirmarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    final msg = "Pedido de ${nombreCtrl.text} - ${telefonoCtrl.text}";

    final url = Uri.parse(
      'https://wa.me/${widget.phone}?text=${Uri.encodeComponent(msg)}',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Finalizar pedido",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(hintText: "Nombre"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: telefonoCtrl,
                decoration: const InputDecoration(hintText: "Teléfono"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _confirmarPedido,
                child: const Text("Confirmar"),
              )
            ],
          ),
        ),
      ),
    );
  }
}