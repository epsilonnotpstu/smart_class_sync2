import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class ManageCoursesScreen extends StatelessWidget {
  const ManageCoursesScreen({super.key});

  void _showCourseDialog(BuildContext context, FirestoreService service, List<UserModel> teachers, {CourseModel? course}) {
    final _formKey = GlobalKey<FormState>();
    final _codeController = TextEditingController(text: course?.courseCode);
    final _nameController = TextEditingController(text: course?.courseName);
    String? _selectedSemester = course?.semester;
    String? _selectedTeacherId = course?.teacherId;
    final isEditing = course != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Course' : 'Add Course'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _codeController, decoration: const InputDecoration(labelText: 'Course Code'), validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Course Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
                DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  hint: const Text('Semester'),
                  items: ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => _selectedSemester = v,
                  validator: (v) => v == null ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedTeacherId,
                  hint: const Text('Teacher'),
                  items: teachers.map((t) => DropdownMenuItem(value: t.uid, child: Text(t.fullName))).toList(),
                  onChanged: (v) => _selectedTeacherId = v,
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
            child: Text(isEditing ? 'Update' : 'Add'),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final data = {
                  'courseCode': _codeController.text,
                  'courseName': _nameController.text,
                  'semester': _selectedSemester,
                  'teacherId': _selectedTeacherId,
                };
                if (isEditing) {
                  service.updateCourse(course!.id, data);
                } else {
                  service.addCourse(data);
                }
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Courses'), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: MultiProvider(
        providers: [
          StreamProvider<List<CourseModel>>.value(value: firestoreService.getCourses(), initialData: const []),
          StreamProvider<List<UserModel>>.value(value: firestoreService.getUsersByRole('teacher'), initialData: const []),
        ],
        child: Consumer2<List<CourseModel>, List<UserModel>>(
          builder: (context, courses, teachers, child) {
            if (courses.isEmpty) return const Center(child: Text('No courses found. Add one!'));
            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${course.courseCode}: ${course.courseName}'),
                    subtitle: Text('Semester: ${course.semester}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCourseDialog(context, firestoreService, teachers, course: course)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => firestoreService.deleteCourse(course.id)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Consumer<List<UserModel>>(
        builder: (context, teachers, child) => FloatingActionButton(
          onPressed: () => _showCourseDialog(context, firestoreService, teachers),
          child: const Icon(Icons.add),
          backgroundColor: Colors.indigo,
        ),
      ),
    );
  }
}