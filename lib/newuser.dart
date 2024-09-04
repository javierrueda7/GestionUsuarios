// ignore: must_be_immutable
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:powerbicu/utils/firebase_services.dart';
import 'package:powerbicu/utils/forms_widgets.dart';
import 'package:random_string/random_string.dart';

class AddEditUser extends StatefulWidget {
  final String? id; // Nullable to differentiate between adding and editing
  final String? role;
  final String? status;
  final String? typeId;
  final bool? admin;
  
  final VoidCallback reloadList;

  const AddEditUser({super.key, this.id, this.typeId, this.role, this.status, required this.reloadList, required this.admin});

  @override
  // ignore: library_private_types_in_public_api
  _AddEditUserState createState() => _AddEditUserState();
}

class _AddEditUserState extends State<AddEditUser> {
  bool _isLoading = false;
  late TextEditingController idController;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController companyController;
  TextEditingController passwordController = TextEditingController();

  late String selectedIdType;
  late String selectedRole;
  late String selectedStatus;
  late String userId;
  late bool admin;

  final List<dynamic> idTypes = ['CÉDULA DE CIUDADANÍA', 'CÉDULA DE EXTRANJERÍA', 'PASAPORTE', 'NIT', 'OTRO'];
  final List<dynamic> roles = ['USUARIO', 'ADMINISTRADOR'];
  final List<dynamic> statuses = ['ACTIVO', 'INACTIVO'];

  @override
  void initState() {
    super.initState();
    
    // Initialize state variables with defaults or widget parameters
    userId = widget.id ?? '';
    selectedIdType = widget.typeId ?? 'CÉDULA DE CIUDADANÍA';
    selectedStatus = widget.status ?? 'ACTIVO';
    selectedRole = widget.role ?? 'USUARIO';
    admin = widget.admin ?? false;

    // Initialize controllers
    idController = TextEditingController();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    companyController = TextEditingController();

    // Fetch user data if widget.id is not null
    if (widget.id != null) {
      fetchAndPopulateUserData(widget.id!);
    }
  }

  // Method to fetch user data and populate controllers
  void fetchAndPopulateUserData(String userId) async {
    try {
      final userData = await fetchUserData(userId);
      if (userData != null) {

        // Update state with fetched data
        setState(() {
          idController.text = userData['id'] ?? '';
          nameController.text = userData['name'] ?? '';
          phoneController.text = userData['phone'] ?? '';
          emailController.text = userData['email'].toLowerCase() ?? '';
          companyController.text = userData['company'] ?? '';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text(widget.id != null ? 'EDITAR USUARIO' : 'CREAR USUARIO')),
      content: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: buildDropdownField('TIPO DE DOCUMENTO', idTypes, (value) {
                        setState(() {
                          selectedIdType = value ?? 'TIPO DE DOCUMENTO'; // Ensure a default value if null
                        });
                      }, initialValue: selectedIdType, allowChange: true),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: buildTextField('NÚMERO DE IDENTIFICACIÓN', idController, false)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: buildTextField('EMPRESA', companyController, false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: buildTextField('NOMBRE', nameController, false)
                    ),
                    Visibility(
                      visible: !admin,
                      child: const SizedBox(width: 10),
                    ),
                    Visibility(
                      visible: !admin,
                      child: Expanded(
                        child: PasswordField(
                          label: 'CONTRASEÑA',
                          controller: passwordController,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: buildNumberField('CELULAR', phoneController, false)),
                    const SizedBox(width: 10),
                    Expanded(child: buildEmailField('EMAIL (TEN PRESENTE QUE SERÁ USADO PARA EL INICIO DE SESIÓN)', emailController, widget.id != null ? true : false)),
                  ],
                ),
                const SizedBox(height: 10),
                Visibility(
                  visible: admin,
                  child: Row(
                    children: [
                      Expanded(
                        child: buildDropdownField(
                          'ROL', roles, (value) {
                            setState(() {
                              selectedRole = value ?? 'ROL';
                            });
                          }, initialValue: selectedRole, allowChange: true
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: buildDropdownField(
                          'ESTADO', statuses, (value) {
                            setState(() {
                              selectedStatus = value!;
                            });
                          }, initialValue: selectedStatus, allowChange: true
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildButton('GUARDAR', Colors.green, () {
                      if (widget.id != null) {
                        _updateUser(userId);
                      } else {
                        _saveUser();
                      }
                    }, _isLoading),
                    buildButton('CANCELAR', Colors.red, () => Navigator.pop(context), _isLoading),
                  ],
                ),
              ],
            ),
          ),
          // Show loading indicator when _isLoading is true
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }  

  void _saveUser() async {
    // Validate fields
    if (_validateFields()) {
      try {
        // Set loading to true
        setState(() {
          _isLoading = true;
        });

        // Step 1: Check if email is already in use
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Usuarios')
            .where('email', isEqualTo: emailController.text.toLowerCase())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Email already in use
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El correo electrónico ya está en uso.'),
              duration: Duration(seconds: 4),
            ),
          );
          return; // Exit the function if email is in use
        }

        // Step 2: Create user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: widget.admin == true ? randomAlphaNumeric(10) : passwordController.text,
        );

        // Step 3: Save user data to Firestore
        await FirebaseFirestore.instance.collection('Usuarios').doc(userCredential.user!.uid).set({
          'idType': selectedIdType.toUpperCase(),
          'id': idController.text.toUpperCase(),
          'name': nameController.text.toUpperCase(),
          'phone': phoneController.text.toUpperCase(),
          'email': emailController.text.toLowerCase(),
          'company': companyController.text.toUpperCase(),
          'role': selectedRole.toUpperCase(),
          'status': selectedStatus.toUpperCase(),
        });

        if (widget.admin == true) {
          // Send password reset email
          await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.toLowerCase());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha enviado un correo para restablecer la contraseña.'),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // Send email verification
          await userCredential.user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha enviado un correo de confirmación.'),
              duration: Duration(seconds: 4),
            ),
          );
        }

        widget.reloadList();
        // User saved successfully, set loading to false
        setState(() {
          _isLoading = false;
        });

        Navigator.pop(context, 'save');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El usuario ha sido creado con éxito.'),
            duration: Duration(seconds: 4),
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear el usuario: ${e.message}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _updateUser(String userId) async {
    // Validate fields
    if (_validateFields()) {
      try {
        // Set loading to true
        setState(() {
          _isLoading = true;
        });

        await FirebaseFirestore.instance.collection('Usuarios').doc(widget.id).update({
          'idType': selectedIdType.toUpperCase(),
          'id': idController.text.toUpperCase(),
          'name': nameController.text.toUpperCase(),
          'phone': phoneController.text.toUpperCase(),
          'email': emailController.text.toLowerCase(),
          'company': companyController.text.toUpperCase(),
          'role': selectedRole.toUpperCase(),
          'status': selectedStatus.toUpperCase(),
        });

        // User updated successfully, set loading to false
        setState(() {
          _isLoading = false;
        });
        
        widget.reloadList();

        Navigator.pop(context, 'save');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El usuario ha sido actualizado con éxito.'),
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el usuario: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget buildButton(String text, Color color, VoidCallback onPressed, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: color,
      ),
      child: Text(text),
    );
  }

  bool _validateFields() {

    // Perform other validations
    if (idController.text.isEmpty ||
        nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        !idTypes.contains(selectedIdType) ||
        !statuses.contains(selectedStatus) ||
        !roles.contains(selectedRole)) {
      return false;
    }

    // Validate password only when admin is false
    if (widget.admin != true) {
      if (passwordController.text.isEmpty || passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, ingrese una contraseña con al menos 6 caracteres.'),
            duration: Duration(seconds: 4),
          ),
        );
        return false;
      }
    }

    // All validations passed
    return true;
  }  
}