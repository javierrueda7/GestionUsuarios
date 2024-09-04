import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

Future<List<Map<String, dynamic>>> getDashboards() async {
  List<Map<String, dynamic>> dashboardList = [];
  final CollectionReference dashboards = db.collection('Dashboards');

  // Query all documents
  QuerySnapshot allDashboards = await dashboards.get();
  for (var document in allDashboards.docs) {
    Map<String, dynamic> dashboard = {
      'id': document.id,
      'data': document.data(),
    };
    dashboardList.add(dashboard);
  }

  // Custom sort function
  dashboardList.sort((a, b) {
    String statusA = a['data']['status'];
    String statusB = b['data']['status'];

    // First sort by status
    int statusComparison = compareStatus(statusA, statusB);
    if (statusComparison != 0) {
      return statusComparison;
    }

    String nameA = a['data']['name'];
    String nameB = b['data']['name'];
    return nameA.compareTo(nameB);
  });

  return dashboardList;
}

int compareStatus(String statusA, String statusB) {
  const statusOrder = ['ACTIVO', 'INACTIVO'];
  int indexA = statusOrder.indexOf(statusA);
  int indexB = statusOrder.indexOf(statusB);

  // Handle cases where status is not in the predefined list
  if (indexA == -1) indexA = statusOrder.length;
  if (indexB == -1) indexB = statusOrder.length;

  return indexA.compareTo(indexB);
}

Future<List> validLogin() async {
  List users = [];
  QuerySnapshot? queryUsers = await db.collection('Usuarios').get();
  for (var doc in queryUsers.docs) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['status'] != 'INACTIVO') {
      final user = {
        "uid": doc.id,
        "name": data['name'],
        "email": data['email'],
        "status": data['status'],
        "role": data['role'],
      };
      users.add(user);
    }
  }
  return users;
}

Future<String> getUserRole() async {
  // Obtener el usuario autenticado
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Obtener el ID del usuario
    String userId = user.uid;

    // Buscar el documento en la colección "Usuarios"
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Usuarios').doc(userId).get();

    if (userDoc.exists) {
      // Retornar el campo 'rol'
      return userDoc['rol'];
    } else {
      throw Exception('Documento de usuario no encontrado');
    }
  } else {
    throw Exception('No hay un usuario autenticado');
  }
}

Future<List<Map<String, dynamic>>> getUsuarios() async {
  List<Map<String, dynamic>> usersList = [];
  final CollectionReference usuarios = db.collection('Usuarios');


  // Query documents from 'Usuarios'
  QuerySnapshot users = await usuarios.get();
  for (var document in users.docs) {
    var data = document.data() as Map<String, dynamic>?;
    if (data != null) {

      Map<String, dynamic> usuario = {
        'id': document.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'role': data['role'] ?? '',
        'status': data['status'] ?? '',
        'phone': data['phone'] ?? '',
        'idType': data['idType'] ?? '',
        'company': data['company'] ?? '',
      };
      usersList.add(usuario);
    }
  }

  // Sort the usersList by 'status' and then by 'name'
  usersList.sort((a, b) {
    // Compare 'status' first
    int statusComparison = a['status'] == 'ACTIVO' && b['status'] != 'ACTIVO'
        ? -1
        : (a['status'] != 'ACTIVO' && b['status'] == 'ACTIVO' ? 1 : 0);

    // If 'status' is the same, compare by 'name'
    if (statusComparison != 0) {
      return statusComparison;
    } else {
      return a['name'].compareTo(b['name']);
    }
  });

  return usersList;
}

Future<String> saveDashboard(String link, String nombre, String estado) async {
  // Get a reference to the collection
  CollectionReference collectionReference = FirebaseFirestore.instance.collection('Dashboards');

  // Generate a unique ID
  String docId = await idGenerator(collectionReference);

  // Add the document with the generated ID
  await collectionReference.doc(docId).set({
    'name': nombre.toUpperCase(), 
    'link': link,
    'status': estado.toUpperCase(),   
  });

  return docId; // Return the new document ID
}

Future<void> submitSelectedUsers(String dashboardId, List<String> usersId) async {
  // Get a reference to the Usuarios subcollection under the specified dashboard
  CollectionReference collectionReference = FirebaseFirestore.instance.collection('Dashboards').doc(dashboardId).collection('Usuarios');

  // Use a batch to perform all operations atomically
  WriteBatch batch = FirebaseFirestore.instance.batch();

  // Iterate over the list of user IDs and add each to the subcollection
  for (String userId in usersId) {
    // Create a reference to a new document with the userId as the document ID
    DocumentReference userDocRef = collectionReference.doc(userId);

    // Add the user to the batch with any necessary data
    batch.set(userDocRef, {
      'userId': userId,
      'addedAt': FieldValue.serverTimestamp(), // Optionally store the timestamp of the addition
      // Add more fields here if necessary
    });
  }

  // Commit the batch operation
  await batch.commit();
}


void saveUser(String id, String idType, String name, String phone, String email, String company, String role, String status) async {
  // Get a reference to the collection
  CollectionReference collectionReference =
      FirebaseFirestore.instance.collection('Usuarios');
      
  collectionReference.doc(id).set({
    'idType': idType,
    'name': name,
    'phone': phone,
    'email': email.toLowerCase(),
    'company': company,
    'role': role,
    'status': status,
  }).then((_) {
    // ignore: avoid_print
    print('Parameter saved successfully');
  }).catchError((error) {
    // ignore: avoid_print
    print('Failed to save parameter: $error');
  });
}

Future<String> idGenerator(CollectionReference ref) async {
  int counter = 0;
  QuerySnapshot snapshot = await ref.get();
  counter = snapshot.size + 1;  
  String idGenerated = 'DB${counter.toString().padLeft(4, '0')}';
  return idGenerated;
}

void updateDashboard(String id, String link, String nombre, String estado) {
  FirebaseFirestore.instance.collection('Dashboards').doc(id).update({
    'name': nombre.toUpperCase(),
    'link': link,
    'status': estado.toUpperCase(),
  }).then((value) {
    // ignore: avoid_print
    print('Parameter saved successfully');
  }).catchError((error) {
    // ignore: avoid_print
    print('Failed to save parameter: $error');
  });
}

Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance.collection('Usuarios').doc(userId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

Future<List<Map<String, dynamic>>> getDashboardsByUserId(String uid) async {
  // Reference to the Dashboards collection
  CollectionReference dashboardsRef = FirebaseFirestore.instance.collection('Dashboards');

  // Initialize a list to hold the dashboards that contain the user ID and have a status of 'ACTIVO'
  List<Map<String, dynamic>> dashboardsWithUser = [];

  // Get all dashboards
  QuerySnapshot dashboardSnapshots = await dashboardsRef.get();

  // Iterate through each dashboard
  for (var dashboardDoc in dashboardSnapshots.docs) {
    // Check if the dashboard status is 'ACTIVO'
    if (dashboardDoc['status'] == 'ACTIVO') {
      // Check if the Usuarios subcollection contains the specified uid
      DocumentSnapshot userDoc = await dashboardsRef
          .doc(dashboardDoc.id)
          .collection('Usuarios')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // If the user exists in the Usuarios subcollection and the status is 'ACTIVO', add the dashboard data to the list
        dashboardsWithUser.add({
          'id': dashboardDoc.id,
          'data': dashboardDoc.data(),
        });
      }
    }
  }

  return dashboardsWithUser;
}




