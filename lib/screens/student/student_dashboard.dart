import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../models/user_model.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final ClassService _classService = ClassService();
  String? _feedbackComment;
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green[900]!, Colors.green[300]!],
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
                    return SpinKitFadingCircle(color: Colors.green[700], size: 50.0);
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                  }
                  final user = snapshot.data;
                  if (user == null) {
                    return const Text('User not found', style: TextStyle(color: Colors.white));
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
                          const Icon(Icons.school, size: 80, color: Colors.green),
                          const SizedBox(height: 20),
                          Text(
                            'Welcome, ${user.fullName}!',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your Routine (Semester: ${user.semester ?? 'N/A'})',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _classService.getStudentSchedule(user.uid),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SpinKitFadingCircle(color: Colors.green[700], size: 30.0);
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                }
                                final routines = snapshot.data?.docs ?? [];
                                if (routines.isEmpty) {
                                  return const Text('No routines yet', style: TextStyle(color: Colors.grey));
                                }
                                return ListView.builder(
                                  itemCount: routines.length,
                                  itemBuilder: (context, index) {
                                    final routine = routines[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: ListTile(
                                        leading: const Icon(Icons.schedule, color: Colors.green),
                                        title: Text(routine['subject'] ?? 'No Subject'),
                                        subtitle: Text('${routine['day'] ?? 'No Day'} at ${routine['time'] ?? 'No Time'}'),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Today’s & Upcoming Classes',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _classService.getUpcomingClasses(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SpinKitFadingCircle(color: Colors.green[700], size: 30.0);
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                }
                                final logs = snapshot.data?.docs ?? [];
                                if (logs.isEmpty) {
                                  return const Text('No upcoming classes', style: TextStyle(color: Colors.grey));
                                }
                                return ListView.builder(
                                  itemCount: logs.length,
                                  itemBuilder: (context, index) {
                                    final log = logs[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: ListTile(
                                        leading: const Icon(Icons.event, color: Colors.green),
                                        title: Text(log['subject'] ?? 'No Subject'),
                                        subtitle: Text('Status: ${log['status'] ?? 'Confirmed'}'),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Resources',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _classService.getResources(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SpinKitFadingCircle(color: Colors.green[700], size: 30.0);
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                }
                                final resources = snapshot.data?.docs ?? [];
                                if (resources.isEmpty) {
                                  return const Text('No resources yet', style: TextStyle(color: Colors.grey));
                                }
                                return ListView.builder(
                                  itemCount: resources.length,
                                  itemBuilder: (context, index) {
                                    final resource = resources[index];
                                    final url = resource['notesUrl'] as String?;
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: ListTile(
                                        leading: const Icon(Icons.download, color: Colors.green),
                                        title: Text(resource['subject'] ?? 'No Title'),
                                        onTap: url != null
                                            ? () async {
                                          try {
                                            await _classService.openResource(url);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Opening resource...')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error opening resource: $e')),
                                            );
                                          }
                                        }
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Feedback',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                          const SizedBox(height: 10),
                          _buildFeedbackForm(user.uid),
                          const SizedBox(height: 20),
                          Text(
                            'Profile',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[900]),
                          ),
                          const SizedBox(height: 10),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.green),
                              title: Text('Name: ${user.fullName}'),
                              subtitle: Text('Semester: ${user.semester ?? 'N/A'}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _showProfileEdit(context, user),
                              ),
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

  Widget _buildFeedbackForm(String studentId) {
    final _formKey = GlobalKey<FormState>();
    return Column(
      children: [
        Slider(
          value: _rating,
          min: 0,
          max: 5,
          divisions: 5,
          label: _rating.toString(),
          activeColor: Colors.green[700],
          onChanged: (value) => setState(() => _rating = value),
        ),
        TextFormField(
          onChanged: (value) => _feedbackComment = value,
          decoration: InputDecoration(
            labelText: 'Comments (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.comment, color: Colors.green),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _rating > 0
              ? () async {
            try {
              await FirebaseFirestore.instance.collection('feedback').add({
                'studentId': studentId,
                'rating': _rating,
                'comment': _feedbackComment ?? '',
                'timestamp': Timestamp.now(),
              });
              setState(() {
                _rating = 0;
                _feedbackComment = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feedback submitted successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error submitting feedback: $e')),
              );
            }
          }
              : null,
          child: const Text('Submit Feedback', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _showProfileEdit(BuildContext context, UserModel user) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: user.fullName);
    final _semesterController = TextEditingController(text: user.semester ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _semesterController,
                decoration: InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: const Icon(Icons.school, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.green)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                    'fullName': _nameController.text,
                    'semester': _semesterController.text.isEmpty ? null : _semesterController.text,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating profile: $e')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}