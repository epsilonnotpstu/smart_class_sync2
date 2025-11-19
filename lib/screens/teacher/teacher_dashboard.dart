import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/models/routine_model.dart';
import 'package:smart_class_sync/services/auth_service.dart';
import 'package:smart_class_sync/services/firestore_service.dart';
import '../../models/user_model.dart';
import 'add_extra_class_screen.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  void _showActionDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Confirm'),
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Today's Actions", icon: Icon(Icons.today)),
              Tab(text: 'Weekly Schedule', icon: Icon(Icons.calendar_month)),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: FutureBuilder<UserModel?>(
          future: authService.user.first,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final teacher = userSnapshot.data!;

            return TabBarView(
              children: [
                _buildTodaysActions(context, firestoreService, teacher),
                _buildWeeklySchedule(context, firestoreService, teacher.uid),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddExtraClassScreen(),
              ),
            );
          },
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add),
          tooltip: 'Add Extra Class',
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule(
    BuildContext context,
    FirestoreService service,
    String teacherId,
  ) {
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getTeacherWeeklyRoutine(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No classes in your weekly schedule.'),
          );
        }
        // ... build a list view similar to student's weekly routine ...
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final routine = snapshot.data![index];
            return ListTile(
              title: Text("Course ID: ${routine.courseId}"), // Placeholder
              subtitle: Text(
                "${routine.dayOfWeek} at ${DateFormat.jm().format(routine.startTime.toDate())}",
              ),
              leading: const Icon(Icons.schedule),
            );
          },
        );
      },
    );
  }

  Widget _buildTodaysActions(
    BuildContext context,
    FirestoreService service,
    UserModel teacher,
  ) {
    // In a real scenario, this would show today's routine classes for the teacher
    // And allow them to confirm, cancel, or mark as late.
    // For now, we use the weekly schedule as a placeholder for action items.
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getTeacherWeeklyRoutine(teacher.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final routineForToday = snapshot.data!
            .where(
              (r) =>
                  r.dayOfWeek.toLowerCase() ==
                  DateFormat('EEEE').format(DateTime.now()).toLowerCase(),
            )
            .toList();
        if (routineForToday.isEmpty)
          return Center(child: Text('No classes scheduled for today.'));

        return ListView.builder(
          itemCount: routineForToday.length,
          itemBuilder: (context, index) {
            final routineItem = routineForToday[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text("Course: ${routineItem.courseId}"),
                subtitle: Text(
                  "Time: ${DateFormat.jm().format(routineItem.startTime.toDate())}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Confirm Class',
                      onPressed: () {
                        _showActionDialog(
                          context,
                          'Confirm Class',
                          'This will notify students that class is on.',
                          () {
                            service.createClassLog(
                              courseId: routineItem.courseId,
                              teacherId: teacher.uid,
                              semester: routineItem.semester,
                              status: 'confirmed',
                              scheduledDate: routineItem.startTime
                                  .toDate(), // simplified date
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Cancel Class',
                      onPressed: () {
                        _showActionDialog(
                          context,
                          'Cancel Class',
                          'Are you sure you want to cancel? This will notify students.',
                          () {
                            service.createClassLog(
                              courseId: routineItem.courseId,
                              teacherId: teacher.uid,
                              semester: routineItem.semester,
                              status: 'cancelled',
                              scheduledDate: routineItem.startTime
                                  .toDate(), // simplified date
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.upload_file, color: Colors.blue),
                      tooltip: 'Upload Notes',
                      onPressed: () {
                        // We need the classLog ID here. For simplicity, we'll assume a log was created.
                        // In a real app, you would fetch the specific log for this routine item.
                        // This is a simplified logic for demonstration.
                        _showActionDialog(
                          context,
                          'Upload Notes',
                          'Do you want to upload notes for this class?',
                          () {
                            // Find the classLog created today for this routine
                            // This logic is complex, so for now we just show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Find this class in the logs and upload from there.',
                                ),
                              ),
                            );
                            // A better UI would be a dedicated "Class History" page where a teacher can
                            // select a past class and upload notes to it.
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
