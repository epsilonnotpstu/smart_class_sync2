import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AddExtraClassScreen extends StatefulWidget {
  const AddExtraClassScreen({super.key});

  @override
  _AddExtraClassScreenState createState() => _AddExtraClassScreenState();
}

class _AddExtraClassScreenState extends State<AddExtraClassScreen> {
  final _formKey = GlobalKey<FormState>();
  CourseModel? _selectedCourse;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _selectedTime != null) {
      setState(() => _isLoading = true);

      final user = Provider.of<AuthService>(context, listen: false).user.first;
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      final teacher = await user;
      if (teacher == null || _selectedCourse == null) return;

      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      await firestoreService.createClassLog(
        courseId: _selectedCourse!.id,
        teacherId: teacher.uid,
        semester: _selectedCourse!.semester,
        status: 'extra',
        scheduledDate: scheduledDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extra class scheduled successfully!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final currentUser = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Extra Class'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<UserModel?>(
        future: currentUser.first,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          return StreamBuilder<List<CourseModel>>(
            stream: firestoreService.getCourses(), // Simplified: gets all courses
            builder: (context, courseSnapshot) {
              if (!courseSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              // Filter courses for the current teacher
              final teacherCourses = courseSnapshot.data!.where((c) => c.teacherId == userSnapshot.data!.uid).toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      DropdownButtonFormField<CourseModel>(
                        value: _selectedCourse,
                        decoration: const InputDecoration(labelText: 'Select Course', border: OutlineInputBorder()),
                        items: teacherCourses.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text('${course.courseCode} - ${course.courseName}'),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedCourse = value),
                        validator: (value) => value == null ? 'Please select a course' : null,
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        title: Text(_selectedDate == null
                            ? 'Select Date'
                            : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context),
                      ),
                      ListTile(
                        title: Text(_selectedTime == null
                            ? 'Select Time'
                            : 'Time: ${_selectedTime!.format(context)}'),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectTime(context),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Schedule Class'),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}