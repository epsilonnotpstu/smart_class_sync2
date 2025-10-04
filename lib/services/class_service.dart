import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  // Fetch personalized schedule for a student
  Stream<QuerySnapshot> getStudentSchedule(String userId) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('routines')
          .orderBy('time')
          .limit(10)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch student schedule: $e');
    }
  }

  // Fetch assigned classes for a teacher
  Stream<QuerySnapshot> getTeacherClasses(String teacherId) {
    try {
      return _firestore
          .collection('classLogs')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('date', descending: true)
          .limit(5)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch teacher classes: $e');
    }
  }

  // Fetch upcoming classes (for students)
  Stream<QuerySnapshot> getUpcomingClasses() {
    try {
      return _firestore
          .collection('classLogs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .orderBy('date')
          .limit(5)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch upcoming classes: $e');
    }
  }

  // Fetch all resources
  Stream<QuerySnapshot> getResources() {
    try {
      return _firestore.collection('classResources').orderBy('subject').limit(10).snapshots();
    } catch (e) {
      throw Exception('Failed to fetch resources: $e');
    }
  }

  // Update class status
  Future<void> updateClassStatus(String classId, String status) async {
    if (!['Confirmed', 'Cancelled', 'Running Late', 'Extra'].contains(status)) {
      throw Exception('Invalid status');
    }
    try {
      await _firestore.collection('classLogs').doc(classId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update class status: $e');
    }
  }

  // Add extra class
  Future<void> addExtraClass({
    required String teacherId,
    required String subject,
    required DateTime date,
    required String time,
    required String room,
  }) async {
    if (subject.isEmpty || time.isEmpty || room.isEmpty) {
      throw Exception('All fields are required');
    }
    try {
      await _firestore.collection('classLogs').add({
        'teacherId': teacherId,
        'subject': subject,
        'date': Timestamp.fromDate(date),
        'time': time,
        'room': room,
        'status': 'Extra',
      });
    } catch (e) {
      throw Exception('Failed to add extra class: $e');
    }
  }

  // Upload resource (lecture notes)
  Future<String?> uploadResource(String subject, String uploadedBy) async {
    if (subject.isEmpty) {
      throw Exception('Subject is required');
    }
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result == null) return null;
      final file = result.files.first;
      if (file.bytes == null) throw Exception('No file data');
      final storageRef = _storage.ref().child('notes/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await storageRef.putData(file.bytes!);
      final url = await storageRef.getDownloadURL();
      await _firestore.collection('classResources').add({
        'notesUrl': url,
        'subject': subject,
        'uploadedBy': uploadedBy,
        'timestamp': Timestamp.now(),
      });
      return url;
    } catch (e) {
      throw Exception('Failed to upload resource: $e');
    }
  }

  // Open resource URL
  Future<void> openResource(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch URL: $url');
    }
  }
}