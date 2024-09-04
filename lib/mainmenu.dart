// ignore_for_file: avoid_web_libraries_in_flutter, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:powerbicu/listdashboards.dart';
import 'dart:html' as html;
import 'package:powerbicu/listusers.dart';
import 'package:powerbicu/utils/firebase_services.dart';
import 'package:powerbicu/utils/forms_widgets.dart';

class MainMenu extends StatefulWidget {
  final String? role;
  final String? uid;
  const MainMenu({super.key, required this.role, required this.uid});
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  String role = 'ANON';
  String uid = '';
  String userName = '';

  @override
  void initState() {
    super.initState();
    role = widget.role ?? role;
    uid = widget.uid ?? uid;

    fetchUserName(uid);
    }

  void fetchUserName(String uid) async {
    try {
      // Assuming your Firestore collection structure is 'Usuarios'
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String? name = userDoc['name'];
        setState(() {
          // Update your state with the fetched name
          // Replace 'userName' with your state variable
          userName = name!;
        });
      } else {
        // Handle case where the document does not exist
      }
    } catch (e) {
      // Handle any errors that occur during the fetch
    }
  }

  void _reloadList() {
    setState(() {}); // Empty setState just to trigger rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BIENVENID@ $userName'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [            
            const ContactInfoCard(),      
            const SizedBox(height: 40),
            Visibility(
              visible: role != 'USUARIO',
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ListUsersScreen()),
                      ).then((_){_reloadList();});
                    },
                    child: const Text('ADMINISTRAR USUARIOS'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ListDashboardsScreen()),
                      ).then((_){_reloadList();});
                    },
                    child: const Text('ADMINISTRAR DASHBOARDS'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            SizedBox(
              width: 500,
              height: 500,
              child: UserDashboardsScreen(uid: uid)
            ),
          ],
        ),
      ),
    );
  }
}

class UserDashboardsScreen extends StatelessWidget {
  final String uid;

  const UserDashboardsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getDashboardsByUserId(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No dashboards found for this user.'));
        }

        final dashboards = snapshot.data!;

        return ListView.builder(
          itemCount: dashboards.length,
          itemBuilder: (context, index) {
            final dashboard = dashboards[index];
            return ListTile(
              leading: Text(dashboard['id'] ?? 'No Id'),
              title: Text(dashboard['data']['name'] ?? 'No Name'),
              trailing: const Icon(Icons.remove_red_eye_outlined),
              onTap: () {
                html.window.open(
                  dashboard['data']['link'],
                  '_blank',
                );
              },
            );
          },
        );
      },
    );    
  }
}