import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course_model.dart';
import '../../models/routine_model.dart';
import '../../services/firestore_service.dart';

class ManageRoutineScreen extends StatelessWidget {
  const ManageRoutineScreen({super.key});

  void _showRoutineDialog(
    BuildContext context,
    FirestoreService service,
    List<CourseModel> courses, {
    RoutineModel? routine,
  }) {
    final _formKey = GlobalKey<FormState>();
    final _roomController = TextEditingController(text: routine?.room);
    final isEditing = routine != null;

    String? _selectedCourseId = routine?.courseId;
    List<String> _selectedDays = isEditing ? [routine.dayOfWeek] : [];
    TimeOfDay? _startTime = routine != null
        ? TimeOfDay.fromDateTime(routine.startTime.toDate())
        : null;
    TimeOfDay? _endTime = routine != null
        ? TimeOfDay.fromDateTime(routine.endTime.toDate())
        : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Routine' : 'Add Routine Entry'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: StatefulBuilder(
              // Use StatefulBuilder to update dialog state
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCourseId,
                      hint: const Text('Select Course'),
                      items: courses
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.courseName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCourseId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    const Text('Select Days'),
                    Wrap(
                      spacing: 8.0,
                      children:
                          [
                            'Saturday',
                            'Sunday',
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                          ].map((day) {
                            return ChoiceChip(
                              label: Text(day),
                              selected: _selectedDays.contains(day),
                              onSelected: (selected) {
                                setState(() {
                                  if (isEditing) {
                                    // In edit mode, only allow one day to be selected
                                    _selectedDays = [day];
                                  } else {
                                    // In add mode, allow multiple days
                                    if (selected) {
                                      _selectedDays.add(day);
                                    } else {
                                      _selectedDays.remove(day);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        labelText: 'Room Number',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      title: Text(
                        _startTime == null
                            ? 'Select Start Time'
                            : 'Start: ${_startTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime ?? TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _startTime = time);
                      },
                    ),
                    ListTile(
                      title: Text(
                        _endTime == null
                            ? 'Select End Time'
                            : 'End: ${_endTime!.format(context)}',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _endTime = time);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text(isEditing ? 'Update' : 'Add'),
            onPressed: () {
              if (_formKey.currentState!.validate() &&
                  _startTime != null &&
                  _endTime != null &&
                  _selectedDays.isNotEmpty) {
                final selectedCourse = courses.firstWhere(
                  (c) => c.id == _selectedCourseId,
                );
                final now = DateTime.now();
                if (isEditing) {
                  final data = {
                    'courseId': _selectedCourseId,
                    'dayOfWeek': _selectedDays.first,
                    'room': _roomController.text,
                    'semester': selectedCourse.semester,
                    'startTime': Timestamp.fromDate(
                      DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _startTime!.hour,
                        _startTime!.minute,
                      ),
                    ),
                    'endTime': Timestamp.fromDate(
                      DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      ),
                    ),
                  };
                  service.updateRoutineEntry(routine.id, data);
                } else {
                  for (String day in _selectedDays) {
                    final data = {
                      'courseId': _selectedCourseId,
                      'dayOfWeek': day,
                      'room': _roomController.text,
                      'semester': selectedCourse.semester,
                      'startTime': Timestamp.fromDate(
                        DateTime(
                          now.year,
                          now.month,
                          now.day,
                          _startTime!.hour,
                          _startTime!.minute,
                        ),
                      ),
                      'endTime': Timestamp.fromDate(
                        DateTime(
                          now.year,
                          now.month,
                          now.day,
                          _endTime!.hour,
                          _endTime!.minute,
                        ),
                      ),
                    };
                    service.addRoutineEntry(data);
                  }
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
    return MultiProvider(
      providers: [
        StreamProvider<List<RoutineModel>>.value(
          value: firestoreService.getFullRoutine(),
          initialData: const [],
        ),
        StreamProvider<List<CourseModel>>.value(
          value: firestoreService.getCourses(),
          initialData: const [],
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Routine'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: Consumer2<List<RoutineModel>, List<CourseModel>>(
          builder: (context, routines, courses, child) {
            if (routines.isEmpty)
              return const Center(
                child: Text('No routine entries found. Add one!'),
              );

            // Create a map of courseId to courseName for easy lookup
            final courseMap = {
              for (var course in courses) course.id: course.courseName,
            };

            return ListView.builder(
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final item = routines[index];
                final courseName = courseMap[item.courseId] ?? 'Unknown Course';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('$courseName (${item.semester} Sem)'),
                    subtitle: Text(
                      '${item.dayOfWeek}, ${DateFormat.jm().format(item.startTime.toDate())} - ${DateFormat.jm().format(item.endTime.toDate())} | Room: ${item.room}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showRoutineDialog(
                            context,
                            firestoreService,
                            courses,
                            routine: item,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              firestoreService.deleteRoutineEntry(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: Consumer<List<CourseModel>>(
          builder: (context, courses, child) => FloatingActionButton(
            onPressed: () =>
                _showRoutineDialog(context, firestoreService, courses),
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
