import 'package:flutter/material.dart';
import 'package:powerbicu/newuser.dart';
import 'package:powerbicu/utils/firebase_services.dart';

class ListUsersScreen extends StatefulWidget {

  const ListUsersScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
                          subtitle: Text('${item?['company'] ?? ''}'),
                          trailing: Text(item?['status'] ?? '', style: const TextStyle(fontSize: 12),),
                          onTap: () {
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
}

