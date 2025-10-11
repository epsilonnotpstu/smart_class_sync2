import 'package:cloud_firestore/cloud_firestore.dart';

class RoutineModel {
  final String id;
  final String courseId;
  final String dayOfWeek;
  final Timestamp startTime;
  final Timestamp endTime;
  final String room;
  final String semester;

  RoutineModel({
    required this.id,
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.semester,
  });

  factory RoutineModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return RoutineModel(
      id: documentId,
      courseId: data['courseId'] ?? '',
      dayOfWeek: data['dayOfWeek'] ?? '',
      startTime: data['startTime'] as Timestamp,
      endTime: data['endTime'] as Timestamp,
      room: data['room'] ?? '',
      semester: data['semester'] ?? '',
    );
  }
}