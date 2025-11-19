import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course_model.dart';
import '../../models/routine_model.dart';
import '../../services/firestore_service.dart';

class ManageRoutineScreen extends StatefulWidget {
  const ManageRoutineScreen({super.key});

  @override
  State<ManageRoutineScreen> createState() => _ManageRoutineScreenState();
}

class _ManageRoutineScreenState extends State<ManageRoutineScreen> {
  final Map<String, List<RoutineModel>> _groupedRoutines = {};
  final List<String> _sortedDays = [];

  void _groupRoutines(List<RoutineModel> routines) {
    _groupedRoutines.clear();
    _sortedDays.clear();

    for (var routine in routines) {
      (_groupedRoutines[routine.dayOfWeek] ??= []).add(routine);
    }

    _sortedDays.addAll(_groupedRoutines.keys.toList());
    _sortedDays.sort((a, b) => _getDayOrder(a).compareTo(_getDayOrder(b)));

    // Sort routines within each day by start time
    for (var day in _sortedDays) {
      _groupedRoutines[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
  }

  int _getDayOrder(String day) {
    const dayOrder = {
      "Saturday": 1,
      "Sunday": 2,
      "Monday": 3,
      "Tuesday": 4,
      "Wednesday": 5,
      "Thursday": 6,
      "Friday": 7,
    };
    return dayOrder[day] ?? 8;
  }

  void _showDeleteDialog(
    BuildContext context,
    FirestoreService service,
    RoutineModel routine,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Routine',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this routine entry for ${routine.dayOfWeek}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              service.deleteRoutineEntry(routine.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Routine deleted successfully'),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Manage Routine',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.grey[700]),
        ),
        body: Consumer2<List<RoutineModel>, List<CourseModel>>(
          builder: (context, routines, courses, child) {
            if (routines.isEmpty && courses.isEmpty) {
              return _buildLoadingState();
            }

            if (courses.isEmpty) {
              return _buildErrorState(
                'No Courses Available',
                'Please add courses first before managing routine',
                Icons.menu_book_outlined,
              );
            }

            _groupRoutines(routines);

            if (routines.isEmpty) {
              return _buildEmptyState();
            }

            return _buildRoutineList(context, firestoreService, courses);
          },
        ),
        floatingActionButton: Consumer<List<CourseModel>>(
          builder: (context, courses, child) => FloatingActionButton(
            onPressed: () =>
                _showRoutineDialog(context, firestoreService, courses),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 2,
            child: const Icon(Icons.add),
            tooltip: 'Add Routine Entry',
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading routine...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Routine Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first routine entry to get started',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineList(
    BuildContext context,
    FirestoreService service,
    List<CourseModel> courses,
  ) {
    final courseMap = {for (var course in courses) course.id: course};

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sortedDays.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final day = _sortedDays[index];
        final dayRoutines = _groupedRoutines[day]!;

        return _buildDaySection(context, service, day, dayRoutines, courseMap);
      },
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    FirestoreService service,
    String day,
    List<RoutineModel> routines,
    Map<String, CourseModel> courseMap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${routines.length} ${routines.length == 1 ? 'class' : 'classes'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...routines.map(
              (routine) => _buildRoutineItem(
                context,
                service,
                routine,
                courseMap[routine.courseId],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(
    BuildContext context,
    FirestoreService service,
    RoutineModel routine,
    CourseModel? course,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.class_outlined,
              color: Colors.blue.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course?.courseName ?? 'Unknown Course',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat.jm().format(routine.startTime.toDate())} - ${DateFormat.jm().format(routine.endTime.toDate())}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      routine.room,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      routine.semester,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text('Delete'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showRoutineDialog(
                  context,
                  service,
                  Provider.of<List<CourseModel>>(context, listen: false),
                  routine: routine,
                );
              } else if (value == 'delete') {
                _showDeleteDialog(context, service, routine);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showRoutineDialog(
    BuildContext context,
    FirestoreService service,
    List<CourseModel> courses, {
    RoutineModel? routine,
  }) {
    final _formKey = GlobalKey<FormState>();
    final _roomController = TextEditingController(text: routine?.room ?? '');
    final isEditing = routine != null;

    String? _selectedCourseId = routine?.courseId;
    String? _selectedDay = routine?.dayOfWeek;
    TimeOfDay? _startTime = routine != null
        ? TimeOfDay.fromDateTime(routine.startTime.toDate())
        : null;
    TimeOfDay? _endTime = routine != null
        ? TimeOfDay.fromDateTime(routine.endTime.toDate())
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text(
              isEditing ? 'Edit Routine' : 'Add Routine Entry',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Selection
                    Text(
                      'Course *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: InputDecoration(
                        hintText: 'Select a course',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: courses.map((course) {
                        return DropdownMenuItem(
                          value: course.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                course.courseCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                course.courseName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCourseId = value),
                      validator: (value) =>
                          value == null ? 'Please select a course' : null,
                    ),
                    const SizedBox(height: 20),
                    // Day Selection
                    Text(
                      'Day *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: InputDecoration(
                        hintText: 'Select day',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items:
                          const [
                            'Saturday',
                            'Sunday',
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                          ].map((day) {
                            return DropdownMenuItem(
                              value: day,
                              child: Text(day),
                            );
                          }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDay = value),
                      validator: (value) =>
                          value == null ? 'Please select a day' : null,
                    ),
                    const SizedBox(height: 20),
                    // Room Input
                    TextFormField(
                      controller: _roomController,
                      decoration: InputDecoration(
                        labelText: 'Room Number *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter room number' : null,
                    ),
                    const SizedBox(height: 20),
                    // Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null)
                                    setState(() => _startTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _startTime == null
                                          ? Colors.grey.shade400
                                          : Colors.blue.shade600,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[50],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: _startTime == null
                                            ? Colors.grey[600]
                                            : Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _startTime == null
                                            ? 'Select time'
                                            : _startTime!.format(context),
                                        style: TextStyle(
                                          color: _startTime == null
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Time *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime ?? TimeOfDay.now(),
                                  );
                                  if (time != null)
                                    setState(() => _endTime = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _endTime == null
                                          ? Colors.grey.shade400
                                          : Colors.blue.shade600,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[50],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: _endTime == null
                                            ? Colors.grey[600]
                                            : Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _endTime == null
                                            ? 'Select time'
                                            : _endTime!.format(context),
                                        style: TextStyle(
                                          color: _endTime == null
                                              ? Colors.grey[600]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _startTime != null &&
                      _endTime != null &&
                      _selectedDay != null &&
                      _selectedCourseId != null) {
                    final selectedCourse = courses.firstWhere(
                      (c) => c.id == _selectedCourseId,
                    );
                    final now = DateTime.now();

                    final data = {
                      'courseId': _selectedCourseId,
                      'dayOfWeek': _selectedDay!,
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

                    if (isEditing) {
                      service.updateRoutineEntry(routine.id, data);
                    } else {
                      service.addRoutineEntry(data);
                    }

                    Navigator.of(ctx).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Routine ${isEditing ? 'updated' : 'added'} successfully',
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
