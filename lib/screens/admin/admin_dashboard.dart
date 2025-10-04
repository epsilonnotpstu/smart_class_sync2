import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[900]!, Colors.purple[300]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: StreamBuilder<UserModel?>(
                stream: authService.user,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SpinKitFadingCircle(color: Colors.purple[700], size: 50.0);
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                  }
                  final user = snapshot.data;
                  if (user == null) {
                    return const Text('User not found', style: TextStyle(color: Colors.white));
                  }
                  if (!user.isVerified) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Pending Verification', style: TextStyle(fontSize: 20)),
                      ),
                    );
                  }
                  return Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.admin_panel_settings, size: 80, color: Colors.purple),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome, ${user.fullName}!',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Pending Verifications',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 300,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('pendingVerifications').snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SpinKitFadingCircle(color: Colors.purple[700], size: 30.0);
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                }
                                final verifications = snapshot.data?.docs ?? [];
                                if (verifications.isEmpty) {
                                  return const Text('No pending verifications', style: TextStyle(color: Colors.grey));
                                }
                                return ListView.builder(
                                  itemCount: verifications.length,
                                  itemBuilder: (context, index) {
                                    final verification = verifications[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: ListTile(
                                        leading: const Icon(Icons.person, color: Colors.purple),
                                        title: Text(verification['fullName'] ?? 'No Name'),
                                        subtitle: Text('${verification['email'] ?? 'No Email'} (${verification['role'] ?? 'No Role'})'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: () => _approveVerification(verification.id),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => _rejectVerification(verification.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async => await authService.signOut(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _approveVerification(String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({'isVerified': true});
    FirebaseFirestore.instance.collection('pendingVerifications').doc(uid).delete();
  }

  void _rejectVerification(String uid) {
    FirebaseFirestore.instance.collection('pendingVerifications').doc(uid).delete();
  }
}