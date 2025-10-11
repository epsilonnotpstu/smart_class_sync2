import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String classLogId;
  final String studentId;
  final int rating;
  final String? comment;
  final Timestamp submittedAt;

  FeedbackModel({
    required this.id,
    required this.classLogId,
    required this.studentId,
    required this.rating,
    this.comment,
    required this.submittedAt,
  });

  factory FeedbackModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return FeedbackModel(
      id: documentId,
      classLogId: data['classLogId'] ?? '',
      studentId: data['studentId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      submittedAt: data['submittedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classLogId': classLogId,
      'studentId': studentId,
      'rating': rating,
      'comment': comment,
      'submittedAt': submittedAt,
    };
  }
}