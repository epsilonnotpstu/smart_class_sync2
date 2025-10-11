import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:smart_class_sync/models/course_model.dart';
import 'package:smart_class_sync/models/feedback_model.dart';
import 'package:smart_class_sync/models/user_model.dart';
import '../models/routine_model.dart';
import '../models/class_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- General Methods ---
  Future<Map<String, String>> getCourseIdToNameMap() async {
    final snapshot = await _db.collection('courses').get();
    return {for (var doc in snapshot.docs) doc.id: doc.data()['courseName'] as String};
  }

  // --- Student Methods ---
  Stream<List<ClassLogModel>> getTodaysClassesForStudent(String semester) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _db
        .collection('classLog')
        .where('semester', isEqualTo: semester)
        .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledDate', isLessThanOrEqualTo: endOfDay)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ClassLogModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Stream<List<RoutineModel>> getWeeklyRoutineForStudent(String semester) {
    return _db
        .collection('routine')
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => RoutineModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // --- Teacher Methods ---
  Stream<List<RoutineModel>> getTeacherWeeklyRoutine(String teacherId) {
    return _db.collection('courses').where('teacherId', isEqualTo: teacherId).snapshots().asyncMap((courseSnapshot) async {
      final courseIds = courseSnapshot.docs.map((doc) => doc.id).toList();
      if (courseIds.isEmpty) return [];

      final routineSnapshot = await _db.collection('routine').where('courseId', whereIn: courseIds).get();
      return routineSnapshot.docs.map((doc) => RoutineModel.fromFirestore(doc.data(), doc.id)).toList();
    });
  }

  Future<void> createClassLog({
    required String courseId,
    required String teacherId,
    required String semester,
    required String status,
    required DateTime scheduledDate,
  }) async {
    // Check if a log for this exact class already exists to prevent duplicates
    final existingLog = await _db.collection('classLog')
        .where('courseId', isEqualTo: courseId)
        .where('teacherId', isEqualTo: teacherId)
        .where('scheduledDate', isEqualTo: Timestamp.fromDate(scheduledDate))
        .limit(1)
        .get();

    if (existingLog.docs.isEmpty) {
      await _db.collection('classLog').add({
        'courseId': courseId,
        'teacherId': teacherId,
        'semester': semester,
        'status': status,
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'notesUrl': null,
        'notificationSent': false,
      });
    } else {
      // Optionally, update the existing log's status if it already exists
      await existingLog.docs.first.reference.update({'status': status});
    }
  }

  // --- Resource Sharing Methods (NEW) ---
  Future<void> uploadAndUpdateClassNotes(String classLogId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'pptx'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;

      if (fileBytes != null) {
        // Upload to Firebase Storage
        final ref = _storage.ref('class_notes/$classLogId/$fileName');
        UploadTask uploadTask = ref.putData(fileBytes);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update the classLog document with the URL
        await _db.collection('classLog').doc(classLogId).update({
          'notesUrl': downloadUrl,
        });
      }
    }
  }

  // --- Feedback Methods (NEW) ---
  Future<void> submitFeedback({
    required String classLogId,
    required String studentId,
    required int rating,
    String? comment,
  }) async {
    await _db.collection('feedback').add({
      'classLogId': classLogId,
      'studentId': studentId, // For privacy, don't link this to user info in reports
      'rating': rating,
      'comment': comment,
      'submittedAt': Timestamp.now(),
    });
  }

  Stream<List<FeedbackModel>> getFeedbackForCourse(String courseId) {
    return _db
        .collection('feedback')
        .where('courseId', isEqualTo: courseId) // Assumes courseId is denormalized in feedback
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FeedbackModel.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Stream<List<FeedbackModel>> getAllFeedback() {
    return _db.collection('feedback').orderBy('submittedAt', descending: true).snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => FeedbackModel.fromFirestore(doc.data(), doc.id)).toList());
  }


  // --- Admin Methods ---
  Stream<List<UserModel>> getPendingTeachers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> verifyTeacher(String uid, bool approve) async {
    if (approve) {
      await _db.collection('users').doc(uid).update({'isVerified': true});
    } else {
      await _db.collection('users').doc(uid).delete();
    }
  }

  Stream<List<CourseModel>> getCourses() {
    return _db.collection('courses').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CourseModel.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addCourse(Map<String, dynamic> courseData) {
    return _db.collection('courses').add(courseData);
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> courseData) {
    return _db.collection('courses').doc(courseId).update(courseData);
  }

  Future<void> deleteCourse(String courseId) {
    return _db.collection('courses').doc(courseId).delete();
  }

  Stream<List<UserModel>> getUsersByRole(String role) {
    return _db
        .collection('users')
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> saveUserFcmToken(String uid, String? token) async {
    if (token == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }
}