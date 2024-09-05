// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, duplicate_ignore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:powerbicu/utils/firebase_services.dart';
import 'package:powerbicu/utils/forms_widgets.dart';

class ListDashboardsScreen extends StatefulWidget {
  const ListDashboardsScreen({super.key});

  @override
  _ListDashboardsScreenState createState() => _ListDashboardsScreenState();
}

class _ListDashboardsScreenState extends State<ListDashboardsScreen> {
  void _reloadList() {
    setState(() {}); // Empty setState just to trigger rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('ADMINISTRACIÓN DE MODELOS')),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(350, 50, 350, 50),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder(
                future: getDashboards(),
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data?[index];
                        return ListTile(
                          leading: Text(item?['id']),
                          title: Text(item?['data']['name']),
                          subtitle: Text(
                            item?['data']['status'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Open edit dialog or perform edit action here
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddEditParam(
                                        link: item?['data']['link'],
                                        reloadList: _reloadList,
                                        id: item?['id'], // Accessing the document ID
                                        name: item?['data']['name'],
                                        status: item?['data']['status'],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit_document, color: Colors.green),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Open the user selection dialog
                                  _showUserSelectionDialog(context, item?['id'], item?['data']['name']);
                                },
                                icon: const Icon(Icons.checklist_outlined),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddEditParam(reloadList: _reloadList);
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUserSelectionDialog(BuildContext context, String? dashboardId, String? dashboardName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UserSelectionDialog(dashboardId: dashboardId, dashboardName: dashboardName);
      },
    );
  }
}

class UserSelectionDialog extends StatefulWidget {
  final String? dashboardId;
  final String? dashboardName;

  const UserSelectionDialog({super.key, this.dashboardId, this.dashboardName});

  @override
  _UserSelectionDialogState createState() => _UserSelectionDialogState();
}

class _UserSelectionDialogState extends State<UserSelectionDialog> {
  final Map<String, bool> _selectedUsers = {};

  @override
  void initState() {
    super.initState();
    _loadSelectedUsers();
  }

  Future<void> _loadSelectedUsers() async {
    if (widget.dashboardId != null) {
      // Get a reference to the Usuarios subcollection under the specified dashboard
      CollectionReference collectionReference = FirebaseFirestore.instance
          .collection('Dashboards')
          .doc(widget.dashboardId)
          .collection('Usuarios');

      // Fetch the currently selected users
      QuerySnapshot snapshot = await collectionReference.get();

      setState(() {
        for (var doc in snapshot.docs) {
          _selectedUsers[doc.id] = true; // Mark these users as selected
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('SELECCIONAR USUARIOS HABILITADOS PARA EL MODELO ${widget.dashboardName}'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: FutureBuilder(
          future: getUsuarios(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final users = snapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final userId = user['id'];
                  final userName = user['name'];
                  final userCompany = user['company'];
                  final userStatus = user['status'];
                  final userEmail = user['email'];
                  final userPhone = user['phone'];

                  return CheckboxListTile(
                    title: Text(userName + ' | ' +  userCompany),
                    subtitle: Text(
                        '$userStatus\nCorreo electrónico: $userEmail | Teléfono: $userPhone'),
                    value: _selectedUsers[userId] ?? false,
                    onChanged: (bool? selected) {
                      setState(() {
                        _selectedUsers[userId] = selected ?? false;
                      });
                    },
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: _submitSelectedUsers,
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }

  void _submitSelectedUsers() async {
    final selectedUserIds = _selectedUsers.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final unselectedUserIds = _selectedUsers.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (widget.dashboardId != null) {
      final CollectionReference collectionReference = FirebaseFirestore.instance
          .collection('Dashboards')
          .doc(widget.dashboardId)
          .collection('Usuarios');

      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add selected users that are not already in the collection
      for (String userId in selectedUserIds) {
        DocumentReference userDocRef = collectionReference.doc(userId);
        batch.set(userDocRef, {
          'userId': userId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      // Delete unselected users that were previously selected
      for (String userId in unselectedUserIds) {
        DocumentReference userDocRef = collectionReference.doc(userId);
        batch.delete(userDocRef);
      }

      // Commit the batch operation
      await batch.commit();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuarios actualizados satisfactoriamente.')),
      );
    }

    Navigator.of(context).pop();
  }

}



// ignore: must_be_immutable
class AddEditParam extends StatefulWidget {
  final String? link;
  final String? name; // Nullable to differentiate between adding and editing
  final String? status; // Nullable to differentiate between adding and editing
  final String? id;
  final VoidCallback reloadList;

  const AddEditParam({super.key, this.link, this.id, this.name, this.status, required this.reloadList});

  @override
  // ignore: library_private_types_in_public_api
  _AddEditParamState createState() => _AddEditParamState();
}

class _AddEditParamState extends State<AddEditParam> {
  late String id;
  late TextEditingController nameController;
  late TextEditingController linkController;
  late String selectedEstado;
  late bool isEditing; // Indicates whether it's an edit operation
  bool isLoading = false; // Loading state

  @override
  void initState() {
    super.initState();
    id = widget.id ?? '';
    nameController = TextEditingController(text: widget.name ?? '');
    linkController = TextEditingController(text: widget.link ?? '');
    if(widget.status == 'PENDIENTE'){
      selectedEstado = 'ACTIVO';
    } else {
      selectedEstado = widget.status ?? 'ACTIVO';
    }
    isEditing = widget.id != null; // If name and status are not null, it's an edit operation
  }

  @override
  Widget build(BuildContext context) {
    final List<String> estados = ['ACTIVO', 'INACTIVO'];

    return AlertDialog(
      title: Center(child: Text(isEditing ? 'EDITAR MODELO' : 'AGREGAR MODELO')),
      content: SizedBox(
        height: 260,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(300, 30, 300, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildTextField('NOMBRE', nameController, false),
              const SizedBox(height: 20),
              buildOpenField('LINK', linkController, false),
              const SizedBox(height: 20),
              buildDropdownField('ESTADO', estados, (value) {
                setState(() {
                  selectedEstado = value ?? 'ACTIVO';
                });
              }, initialValue: selectedEstado, allowChange: true),
            ],
          ),
        ),
      ),
      actions: [
        isLoading
            ? const Center(child: CircularProgressIndicator()) // Show loading indicator
            : TextButton(
                onPressed: () {
                  if (isLoading) return; // Prevent further actions if loading
                  setState(() {
                    isLoading = true; // Set loading state to true
                  });
                  if (isEditing) {
                    _updateParameter(context);
                  } else {
                    _saveParameter(context);
                  }
                },
                child: Text(isEditing ? 'GUARDAR' : 'AGREGAR'),
              ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }

  void _saveParameter(BuildContext context) async {
    String nombre = nameController.text;
    String link = linkController.text;
    String estado = selectedEstado;
    try {
      await saveDashboard(link, nombre, estado);
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modelo guardado exitosamente.'),
          duration: Duration(seconds: 4),
        ),
      );
      // Clear the name field after saving
      nameController.clear();
      // Trigger a refresh of the list by calling setState
      widget.reloadList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el modelo: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      Navigator.of(context).pop();
      setState(() {
        isLoading = false; // Reset loading state
      });
    }
  }

  void _updateParameter(BuildContext context) async {
    String id = widget.id ?? '';
    String nombre = nameController.text;
    String link = linkController.text;
    String estado = selectedEstado;

    try {
      updateDashboard(id, link, nombre, estado);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modelo actualizado exitosamente.'),
          duration: Duration(seconds: 4),
        ),
      );

      // Clear the name field after saving
      nameController.clear();

      // Trigger a refresh of the list by calling setState
      widget.reloadList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el modelo: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      Navigator.of(context).pop();
      setState(() {
        isLoading = false; // Reset loading state
      });
    }
  }
}



