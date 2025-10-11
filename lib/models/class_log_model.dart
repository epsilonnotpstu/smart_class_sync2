import 'package:cloud_firestore/cloud_firestore.dart';

class ClassLogModel {
  final String id;
  final String courseId;
  final String teacherId;
  final Timestamp scheduledDate;
  final String status; // e.g., "confirmed", "cancelled", "extra", "late"
  final String? notesUrl;
  final String semester;

  ClassLogModel({
    required this.id,
    required this.courseId,
    required this.teacherId,
    required this.scheduledDate,
    required this.status,
    this.notesUrl,
    required this.semester,
  });

  factory ClassLogModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return ClassLogModel(
      id: documentId,
      courseId: data['courseId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      scheduledDate: data['scheduledDate'] as Timestamp,
      status: data['status'] ?? '',
      notesUrl: data['notesUrl'],
      semester: data['semester'] ?? '',
    );
  }
}