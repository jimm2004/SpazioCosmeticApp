import 'package:flutter/material.dart';

import '../controllers/auth/auth_controller.dart';
import '../pages/auth/widgets/auth_widgets.dart';

void showForgotPasswordDialog(
  BuildContext context,
  AuthController authController,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ForgotPasswordDialog(
      parentContext: context,
      authController: authController,
    ),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  final BuildContext parentContext;
  final AuthController authController;

  const _ForgotPasswordDialog({
    required this.parentContext,
    required this.authController,
  });

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();

  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Por favor, ingresa tu correo.";
      });
      return;
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = "Ingresa un correo electrónico válido.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSending = true;
    });

    try {
      await widget.authController.forgotPassword(email);

      if (!mounted) return;

      Navigator.of(context).pop();

      showCustomDialog(
        widget.parentContext,
        title: "Correo enviado",
        message: "Revisa tu bandeja de entrada para restablecer tu contraseña.",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      showCustomDialog(
        context,
        title: "Error",
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: Container(
        width: width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 60,
                color: Color(0xFFE91E63),
              ),
              const SizedBox(height: 16),

              const Text(
                "Recuperar contraseña",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                "Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                enabled: !_isSending,
                decoration: buildInputDecoration(
                  'Correo electrónico',
                ).copyWith(
                  errorText: _errorMessage,
                ),
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("ENVIAR CORREO"),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}