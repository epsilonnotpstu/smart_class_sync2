import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../services/auth_service.dart';
import '../../services/class_service.dart';
import '../../models/user_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ClassService _classService = ClassService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                            'Manage Routine',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Add Routine'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _showAddRoutine(context, user.uid),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore.collection('routines').orderBy('time').limit(5).snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SpinKitFadingCircle(color: Colors.purple[700], size: 30.0);
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
                                        leading: const Icon(Icons.schedule, color: Colors.purple),
                                        title: Text(routine['subject'] ?? 'No Subject'),
                                        subtitle: Text('Semester: ${routine['semester'] ?? 'N/A'}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: Colors.purple),
                                              onPressed: () => _editRoutine(context, routine),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _deleteRoutine(routine.id),
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
                          Text(
                            'User Management',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore.collection('pendingVerifications').snapshots(),
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
                          Text(
                            'Feedback Reports',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: StreamBuilder<QuerySnapshot>(
                              stream: _firestore.collection('feedback').orderBy('timestamp', descending: true).limit(5).snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return SpinKitFadingCircle(color: Colors.purple[700], size: 30.0);
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                }
                                final feedbacks = snapshot.data?.docs ?? [];
                                if (feedbacks.isEmpty) {
                                  return const Text('No feedback yet', style: TextStyle(color: Colors.grey));
                                }
                                return ListView.builder(
                                  itemCount: feedbacks.length,
                                  itemBuilder: (context, index) {
                                    final feedback = feedbacks[index];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: ListTile(
                                        leading: const Icon(Icons.feedback, color: Colors.purple),
                                        title: Text('Rating: ${feedback['rating']}'),
                                        subtitle: Text(feedback['comment'] ?? 'No comment'),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Profile',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                          ),
                          const SizedBox(height: 10),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.purple),
                              title: Text('Name: ${user.fullName}'),
                              subtitle: Text('Email: ${user.email}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.purple),
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

  void _showAddRoutine(BuildContext context, String adminId) {
    final _formKey = GlobalKey<FormState>();
    final _dayController = TextEditingController();
    final _timeController = TextEditingController();
    final _subjectController = TextEditingController();
    final _semesterController = TextEditingController();
    final _roomController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Routine'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _dayController,
                  decoration: InputDecoration(
                    labelText: 'Day',
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter day' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Time (HH:MM)',
                    prefixIcon: const Icon(Icons.access_time, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter time' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.book, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter subject' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _semesterController,
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: const Icon(Icons.school, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter semester' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    labelText: 'Room',
                    prefixIcon: const Icon(Icons.room, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter room' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.purple)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await _firestore.collection('routines').add({
                    'day': _dayController.text,
                    'time': _timeController.text,
                    'subject': _subjectController.text,
                    'semester': _semesterController.text,
                    'room': _roomController.text,
                    'createdBy': adminId,
                    'timestamp': Timestamp.now(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Routine added successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding routine: $e')),
                  );
                }
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editRoutine(BuildContext context, DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    final _dayController = TextEditingController(text: doc['day']);
    final _timeController = TextEditingController(text: doc['time']);
    final _subjectController = TextEditingController(text: doc['subject']);
    final _semesterController = TextEditingController(text: doc['semester']);
    final _roomController = TextEditingController(text: doc['room']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Routine'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _dayController,
                  decoration: InputDecoration(
                    labelText: 'Day',
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter day' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Time (HH:MM)',
                    prefixIcon: const Icon(Icons.access_time, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter time' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: const Icon(Icons.book, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter subject' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _semesterController,
                  decoration: InputDecoration(
                    labelText: 'Semester',
                    prefixIcon: const Icon(Icons.school, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter semester' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    labelText: 'Room',
                    prefixIcon: const Icon(Icons.room, color: Colors.purple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Enter room' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.purple)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await doc.reference.update({
                    'day': _dayController.text,
                    'time': _timeController.text,
                    'subject': _subjectController.text,
                    'semester': _semesterController.text,
                    'room': _roomController.text,
                    'timestamp': Timestamp.now(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Routine updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating routine: $e')),
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

  void _deleteRoutine(String docId) async {
    try {
      await _firestore.collection('routines').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting routine: $e')),
      );
    }
  }

  void _approveVerification(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isVerified': true});
      await _firestore.collection('pendingVerifications').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User verified successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying user: $e')),
      );
    }
  }

  void _rejectVerification(String uid) async {
    try {
      await _firestore.collection('pendingVerifications').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting verification: $e')),
      );
    }
  }

  void _showProfileEdit(BuildContext context, UserModel user) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: user.fullName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: const Icon(Icons.person, color: Colors.purple),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.purple)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await _firestore.collection('users').doc(user.uid).update({
                    'fullName': _nameController.text,
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