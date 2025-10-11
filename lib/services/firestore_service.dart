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
  Stream<List<ClassLogModel>> getUpcomingClassesForStudent(String semester) {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);
    DateTime endPeriod = startOfToday.add(const Duration(days: 7));

    // TODO: The original query required a composite index in Firestore.
    // This query is modified to filter by semester on the client-side to avoid the immediate error.
    // For better performance and lower read costs, you should create the composite index in your Firebase console.
    // The error message from Firestore provides a direct link to create it.
    // The index should be on: `semester` (Ascending) and `scheduledDate` (Ascending) for the `classLog` collection.
    // Once the index is created, you can revert to the more efficient query:
    /*
    return _db
        .collection('classLog')
        .where('semester', isEqualTo: semester)
        .where('scheduledDate', isGreaterThanOrEqualTo: startOfToday)
        .where('scheduledDate', isLessThan: endPeriod)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassLogModel.fromFirestore(doc.data(), doc.id))
            .toList());
    */
    return _db
        .collection('classLog')
        .where('scheduledDate', isGreaterThanOrEqualTo: startOfToday)
        .where('scheduledDate', isLessThan: endPeriod)
        .orderBy('scheduledDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassLogModel.fromFirestore(doc.data(), doc.id))
          .where((log) => log.semester == semester) // Client-side filter
          .toList();
    });
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
      await existingLog.docs.first.reference.update({'status': status});
    }
  }

  // --- Resource Sharing Methods ---
  Future<void> uploadAndUpdateClassNotes(String classLogId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'pptx'],
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;

      if (fileBytes != null) {
        final ref = _storage.ref('class_notes/$classLogId/$fileName');
        UploadTask uploadTask = ref.putData(fileBytes);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        await _db.collection('classLog').doc(classLogId).update({'notesUrl': downloadUrl});
      }
    }
  }

  // --- Feedback Methods ---
  Future<void> submitFeedback({
    required String classLogId,
    required String studentId,
    required int rating,
    String? comment,
  }) async {
    await _db.collection('feedback').add({
      'classLogId': classLogId,
      'studentId': studentId,
      'rating': rating,
      'comment': comment,
      'submittedAt': Timestamp.now(),
    });
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

  Stream<List<RoutineModel>> getFullRoutine() {
    return _db.collection('routine').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => RoutineModel.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addRoutineEntry(Map<String, dynamic> routineData) {
    return _db.collection('routine').add(routineData);
  }

  Future<void> updateRoutineEntry(String routineId, Map<String, dynamic> routineData) {
    return _db.collection('routine').doc(routineId).update(routineData);
  }

  Future<void> deleteRoutineEntry(String routineId) {
    return _db.collection('routine').doc(routineId).delete();
  }
}
