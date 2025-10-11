class CourseModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String teacherId;
  final String semester;

  CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.teacherId,
    required this.semester,
  });

  factory CourseModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return CourseModel(
      id: documentId,
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      semester: data['semester'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}