import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: authService.user,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Loading...'));
          }
          final user = snapshot.data!;
          if (!user.isVerified) {
            return const Center(child: Text('Pending Verification'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Welcome, ${user.fullName}!', style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                const Text('Pending Verifications', style: TextStyle(fontSize: 20)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('pendingVerifications')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final verifications = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: verifications.length,
                        itemBuilder: (context, index) {
                          final verification = verifications[index];
                          return ListTile(
                            title: Text(verification['fullName'] ?? 'No Name'),
                            subtitle: Text(verification['email'] ?? 'No Email'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () {
                                    _approveVerification(context, verification.id);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    _rejectVerification(context, verification.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _approveVerification(BuildContext context, String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({'isVerified': true});
    FirebaseFirestore.instance.collection('pendingVerifications').doc(uid).delete();
  }

  void _rejectVerification(BuildContext context, String uid) {
    FirebaseFirestore.instance.collection('pendingVerifications').doc(uid).delete();
  }
}