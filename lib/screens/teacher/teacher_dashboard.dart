import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
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
                ElevatedButton(
                  onPressed: () {
                    _showAttendanceForm(context);
                  },
                  child: const Text('Log Attendance'),
                ),
                const SizedBox(height: 20),
                const Text('Class Log', style: TextStyle(fontSize: 20)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('classLogs')
                        .where('teacherId', isEqualTo: user.uid)
                        .orderBy('date', descending: true)
                        .limit(10)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final logs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return ListTile(
                            title: Text(log['subject'] ?? 'No Subject'),
                            subtitle: Text(log['date']?.toDate().toString() ?? 'No Date'),
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

  void _showAttendanceForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _subjectController = TextEditingController();
    String? _date;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Attendance'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter subject';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Date'),
                value: _date,
                items: ['Today', 'Yesterday', 'Custom']
                    .map((date) => DropdownMenuItem(value: date, child: Text(date)))
                    .toList(),
                onChanged: (value) {
                  _date = value;
                },
                validator: (value) {
                  if (value == null) return 'Select a date';
                  return null;
                },
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
              if (_formKey.currentState!.validate()) {
                FirebaseFirestore.instance.collection('classLogs').add({
                  'teacherId': Provider.of<AuthService>(context, listen: false).user.first.uid,
                  'subject': _subjectController.text,
                  'date': DateTime.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}