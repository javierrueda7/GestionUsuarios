// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:powerbicu/utils/forms_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          elevation: 0,
          title: const Text(
            "RECUPERAR CONTRASEÑA",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
          Color.fromARGB(255, 244, 246, 252),
          Color.fromARGB(255, 222, 224, 227),
          Color.fromARGB(255, 222, 224, 227)
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(children: <Widget>[
              const SizedBox(
                height: 20,
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: buildEmailField('EMAIL', _emailTextController, false),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: firebaseButton(context, "RECUPERAR CONTRASEÑA", () async {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailTextController.text);
                    // Use mounted to ensure the context is still valid
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Se ha enviado un correo para restablecer la contraseña.',
                          style: TextStyle(color: Colors.white),
                        ),
                        duration: Duration(seconds: 4),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Hubo un error al enviar el correo de restablecimiento.',
                          style: TextStyle(color: Colors.white),
                        ),
                        duration: Duration(seconds: 4),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                })
              )
            ]),
          ),
        ),
      )
    );
  }
}
