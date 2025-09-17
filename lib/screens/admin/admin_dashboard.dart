// lib/screens/admin/admin_dashboard.dart (CORRECTED)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/models/user_model.dart';
import 'package:smart_class_sync/utils/app_styles.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await authService.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      // Use a StreamBuilder to get the current user data
      body: StreamBuilder<UserModel?>(
        stream: authService.user,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found.'));
          }
          final user = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('Welcome, ${user.fullName}!', style: AppTextStyles.headline1),
                ),
                const Text('Pending Verifications', style: AppTextStyles.headline2),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('isVerified', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // ... (This inner StreamBuilder remains unchanged)
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No pending verifications.', style: AppTextStyles.bodyText),
                        );
                      }
                      final verifications = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: verifications.length,
                        itemBuilder: (context, index) {
                          final verification = verifications[index].data() as Map<String, dynamic>;
                          final docId = verifications[index].id;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  (verification['role'] ?? 'U').substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(verification['fullName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(verification['email'] ?? 'No Email'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.error),
                                    onPressed: () => _showRejectConfirmation(context, docId),
                                    tooltip: 'Reject',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check_rounded, color: AppColors.secondary),
                                    onPressed: () => _approveVerification(context, docId),
                                    tooltip: 'Approve',
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
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (Helper functions _approveVerification, _rejectVerification, etc., remain unchanged)
  void _approveVerification(BuildContext context, String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({'isVerified': true}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved.'), backgroundColor: AppColors.secondary),
      );
    });
  }

  void _rejectVerification(BuildContext context, String uid) {
    FirebaseFirestore.instance.collection('users').doc(uid).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User rejected and removed.'), backgroundColor: AppColors.error),
      );
    });
  }

  void _showRejectConfirmation(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text('Are you sure you want to reject and remove this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(context).pop();
              _rejectVerification(context, uid);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}