import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactInfoCard extends StatelessWidget {
  const ContactInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 4,
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'DATA ANALYTICS SOLUTIONS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8), // Adds some space between texts
            Text(
              'Edilberto Rueda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            Text(
              'jerueda@yahoo.com',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              '3156285506',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Container firebaseButton(BuildContext context, String title, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(90)),
    child: ElevatedButton(
        onPressed: () {
          onTap();
        },
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.amber;
              }
              return Colors.amber;
            }),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)))),
        child: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        )),
  );
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final RegExp regExp = RegExp(r'^\+?[0-9]*$');
    if (regExp.hasMatch(newValue.text)) {
      return newValue;
    } else {
      return oldValue;
    }
  }
}

Widget buildDateField(String label, TextEditingController controller, BuildContext context) {
  return TextFormField(
    controller: controller,
    onTap: () async {
      final DateTime? picked = await showDatePicker(
        locale: const Locale("es", "CO"),
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2050),
      );
      if (picked != null && picked != DateTime.now()) {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      }
    },
    readOnly: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    ),
  );
}

Widget buildDropdownField(
    String label,
    List<dynamic> items,
    void Function(String?)? onChanged, {
    required String initialValue,
    required bool allowChange,
}) {
  return IgnorePointer(
    ignoring: !allowChange,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        constraints: const BoxConstraints(maxWidth: 800),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        enabled: allowChange, // This will change the visual appearance
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          value: items.contains(initialValue) ? initialValue : items.first,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: allowChange ? onChanged : null,
          disabledHint: Text(items.contains(initialValue) ? initialValue : items.first),
        ),
      ),
    ),
  );
}


Widget buildTextField(String label, TextEditingController controller, bool read) {
  controller.addListener(() {
    final text = controller.text.toUpperCase();
    if (controller.text != text) {
      final cursorPosition = controller.selection.baseOffset;
      controller.value = controller.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(
          offset: cursorPosition > text.length ? text.length : cursorPosition,
        ),
      );
    }
  });
  return SizedBox(
    width: 600,
    child: TextFormField(
      controller: controller,
      readOnly: read,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    ),
  );
}

Widget buildOpenField(String label, TextEditingController controller, bool read) {  
  return SizedBox(
    width: 600,
    child: TextFormField(
      controller: controller,
      readOnly: read,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    ),
  );
}

Widget buildEmailField(String label, TextEditingController controller, bool read) {
  controller.addListener(() {
    final text = controller.text.toLowerCase();
    if (controller.text != text) {
      controller.value = controller.value.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  });
  return SizedBox(
    width: 600,
    child: TextFormField(
      controller: controller,
      readOnly: read,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    ),
  );
}

Widget buildNumberField(String label, TextEditingController controller, bool read) {
  return SizedBox(
    width: 600,
    child: TextFormField(
      controller: controller,
      readOnly: read,
      keyboardType: TextInputType.number, // Set keyboard type to number
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly // Allow only digits
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
    ),
  );
}

Widget buildButton(String label, Color color, void Function()? onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white),),
  );
}

class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const PasswordField({super.key, required this.label, required this.controller});

  @override
  // ignore: library_private_types_in_public_api
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        enableSuggestions: false,
        autocorrect: false,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: _toggleVisibility,
          ),
        ),
      ),
    );
  }
}