import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_class_sync/models/course_model.dart';
import 'package:smart_class_sync/models/user_model.dart';
import '../models/routine_model.dart';
import '../models/class_log_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    // This is a bit complex as routine doesn't store teacherId directly.
    // A better data model would be to denormalize teacherId into the routine.
    // For now, we fetch courses first, then routines. This is not optimal for performance.
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
    await _db.collection('classLog').add({
      'courseId': courseId,
      'teacherId': teacherId,
      'semester': semester,
      'status': status,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'notesUrl': null,
      'notificationSent': false, // For Module 4
    });
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
      // Deleting a user should be handled by a Cloud Function for security
      // For now, we just delete the Firestore document. The auth user remains.
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