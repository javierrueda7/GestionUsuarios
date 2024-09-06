// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:powerbicu/newuser.dart';
import 'package:powerbicu/utils/firebase_services.dart';

class ListUsersScreen extends StatefulWidget {

  const ListUsersScreen({super.key});

  @override
  _ListUsersScreenState createState() => _ListUsersScreenState();
}

class _ListUsersScreenState extends State<ListUsersScreen> {
  

  void _reloadList() {
    setState(() {}); // Empty setState just to trigger rebuild
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('ADMINISTRACIÓN DE USUARIOS')),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(300, 50, 300, 50),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: Text(
                        'ROL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Text(
                    'USUARIOS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ESTADO',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ), // Add spacing between header and FutureBuilder
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder(
                future: getUsuarios(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data?[index];
                        return ListTile(
                          leading: SizedBox(width: 110,child: Center(child: Text(item?['role'] ?? '', style: const TextStyle(fontSize: 12),textAlign: TextAlign.center,),)),
                          title: Text(item?['name'] ?? ''),
                          subtitle: Text(item?['status'] + ' - ' + item?['company'],
                            style: const TextStyle(fontSize: 14),),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  // Open edit dialog or perform edit action here
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AddEditUser(
                                        reloadList: _reloadList,
                                        id: item?['id'],
                                        status: item?['status'],
                                        typeId: item?['idType'],
                                        role: item?['role'],
                                        admin: true,
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit_document, color: Colors.green),
                              ),
                              IconButton(
                                onPressed: () {
                                  // Open the user selection dialog
                                  _showDashboardSelectionDialog(context, item?['id'], item?['name']);
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
                },
              )

            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddEditUser(reloadList: _reloadList, admin: true,);
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDashboardSelectionDialog(BuildContext context, String? userId, String? userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DashboardSelectionDialog(userId: userId, userName: userName);
      },
    );
  }
}

class DashboardSelectionDialog extends StatefulWidget {
  final String? userId;
  final String? userName;

  const DashboardSelectionDialog({super.key, this.userId, this.userName});

  @override
  _DashboardSelectionDialogState createState() =>
      _DashboardSelectionDialogState();
}

class _DashboardSelectionDialogState extends State<DashboardSelectionDialog> {
  final Map<String, bool> _selectedDashboards = {};
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _loadSelectedDashboards();
  }

  Future<void> _loadSelectedDashboards() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    if (widget.userId != null) {
      // Get all dashboards
      QuerySnapshot dashboardsSnapshot =
          await FirebaseFirestore.instance.collection('Dashboards').get();

      // Loop through dashboards to find if the user is in their Usuarios subcollection
      for (var dashboardDoc in dashboardsSnapshot.docs) {
        String dashboardId = dashboardDoc.id;

        CollectionReference userCollection = FirebaseFirestore.instance
            .collection('Dashboards')
            .doc(dashboardId)
            .collection('Usuarios');

        DocumentSnapshot userDoc = await userCollection.doc(widget.userId).get();

        setState(() {
          _selectedDashboards[dashboardId] = userDoc.exists;
        });
      }
    }
    setState(() {
      _isLoading = false; // End loading
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('SELECCIONAR DASHBOARDS PARA ${widget.userName}'),
      content: SizedBox(
        width: 600,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // Show loading
            : FutureBuilder(
                future: getDashboards(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final dashboards = snapshot.data!;
                    return ListView.builder(
                      itemCount: dashboards.length,
                      itemBuilder: (context, index) {
                        final dashboard = dashboards[index];
                        final dashboardId = dashboard['id'];
                        final dashboardName = dashboard['name'];

                        return CheckboxListTile(
                          title: Text(dashboardName),
                          value: _selectedDashboards[dashboardId] ?? false,
                          onChanged: (bool? selected) {
                            setState(() {
                              _selectedDashboards[dashboardId] =
                                  selected ?? false;
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
          onPressed: _submitSelectedDashboards,
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }

  void _submitSelectedDashboards() async {
    final selectedDashboardIds = _selectedDashboards.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final unselectedDashboardIds = _selectedDashboards.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (widget.userId != null) {
      final WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add selected dashboards for the user
      for (String dashboardId in selectedDashboardIds) {
        DocumentReference userDocRef = FirebaseFirestore.instance
            .collection('Dashboards')
            .doc(dashboardId)
            .collection('Usuarios')
            .doc(widget.userId);
        batch.set(userDocRef, {
          'userId': widget.userId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      // Remove unselected dashboards for the user
      for (String dashboardId in unselectedDashboardIds) {
        DocumentReference userDocRef = FirebaseFirestore.instance
            .collection('Dashboards')
            .doc(dashboardId)
            .collection('Usuarios')
            .doc(widget.userId);
        batch.delete(userDocRef);
      }

      // Commit the batch operation
      await batch.commit();

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboards actualizados satisfactoriamente.')),
      );
    }

    Navigator.of(context).pop();
  }

  Future<List<Map<String, dynamic>>> getDashboards() async {
    // Fetch the list of available dashboards
    QuerySnapshot dashboardsSnapshot =
        await FirebaseFirestore.instance.collection('Dashboards').get();
    return dashboardsSnapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name']})
        .toList();
  }
}


