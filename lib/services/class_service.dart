// lib/services/class_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Teacher Functions ---
  Future<void> addClassLog({
    required String subject,
    required int studentCount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final logData = {
      'teacherId': user.uid,
      'subject': subject,
      'studentCount': studentCount,
      'date': Timestamp.now(),
    };

    // Write to both collections in a batch for atomicity
    final batch = _firestore.batch();
    batch.set(_firestore.collection('classLogs').doc(), logData);
    batch.set(_firestore.collection('classActivities').doc(), logData);
    await batch.commit();
  }

  Stream<QuerySnapshot> getClassLogs() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('classLogs')
        .where('teacherId', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots();
  }

  // --- Student Functions ---
  Future<void> addRoutine({
    required String day,
    required String subject,
    required String time,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('routines')
        .add({'day': day, 'subject': subject, 'time': time});
  }

  Future<void> deleteRoutine(String routineId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('routines')
        .doc(routineId)
        .delete();
  }

  Stream<QuerySnapshot> getRoutines() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('routines')
        .orderBy('time')
        .snapshots();
  }

  // --- Admin Functions ---
  Stream<QuerySnapshot> getClassActivities() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return _firestore
        .collection('classActivities')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots();
  }

  Future<String> getTeacherName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? (doc.data()!['fullName'] ?? 'Unknown Teacher') : 'Unknown Teacher';
    } catch (e) {
      return 'Unknown Teacher';
    }
  }
}