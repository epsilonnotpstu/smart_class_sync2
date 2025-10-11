import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class ManageTeachersScreen extends StatelessWidget {
  const ManageTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Teachers'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getPendingTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No pending teacher verifications.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          final pendingTeachers = snapshot.data!;
          return ListView.builder(
            itemCount: pendingTeachers.length,
            itemBuilder: (context, index) {
              final teacher = pendingTeachers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(teacher.fullName),
                  subtitle: Text(teacher.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => firestoreService.verifyTeacher(teacher.uid, true),
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => firestoreService.verifyTeacher(teacher.uid, false),
                        tooltip: 'Deny',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}