// lib/screens/teacher/teacher_dashboard.dart (CORRECTED)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/models/user_model.dart';
import 'package:smart_class_sync/utils/app_styles.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
            // This can happen briefly during logout, handle gracefully
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_calendar_rounded),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.secondary,
                    ),
                    onPressed: () => _showAttendanceForm(context, user.uid),
                    label: const Text('Log Class Attendance'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Recent Class Logs', style: AppTextStyles.headline2),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classLogs')
                        .where('teacherId', isEqualTo: user.uid)
                        .orderBy('date', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No class logs found.', style: AppTextStyles.bodyText),
                        );
                      }
                      final logs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index].data() as Map<String, dynamic>;
                          final logDate = (log['date'] as Timestamp).toDate();

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.history_edu, color: AppColors.primary, size: 30),
                              title: Text(log['subject'] ?? 'No Subject', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat.yMMMd().add_jm().format(logDate)),
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

  void _showAttendanceForm(BuildContext context, String teacherId) {
    // ... (This function remains unchanged)
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Log Attendance'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject / Topic'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a subject' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                FirebaseFirestore.instance.collection('classLogs').add({
                  'teacherId': teacherId,
                  'subject': subjectController.text,
                  'date': Timestamp.now(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attendance Logged Successfully!'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}