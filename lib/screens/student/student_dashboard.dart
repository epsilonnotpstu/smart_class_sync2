import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/models/class_log_model.dart';
import 'package:smart_class_sync/models/routine_model.dart';
import 'package:smart_class_sync/services/auth_service.dart';
import 'package:smart_class_sync/services/firestore_service.dart';
import 'package:smart_class_sync/widgets/class_list_item.dart';
import '../../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'feedback_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authService.signOut(),
              tooltip: 'Logout',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Today's Classes", icon: Icon(Icons.today)),
              Tab(text: 'Weekly Routine', icon: Icon(Icons.calendar_month)),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
          ),
        ),
        body: StreamBuilder<UserModel?>(
            stream: authService.user,
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return const Center(child: Text("Not logged in."));
              }

              final student = userSnapshot.data!;
              final semester = student.semester ?? '1st'; // Fallback semester

              return TabBarView(
                children: [
                  _buildTodaysClasses(context, firestoreService, semester),
                  _buildWeeklyRoutine(context, firestoreService, semester),
                ],
              );
            }
        ),
      ),
    );
  }

  Widget _buildTodaysClasses(BuildContext context, FirestoreService service, String semester) {
    return StreamBuilder<List<ClassLogModel>>(
      stream: service.getTodaysClassesForStudent(semester),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No classes scheduled for today.'));
        }
        final classes = snapshot.data!;
        return ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classLog = classes[index];
            // In a real app, you'd fetch the course name from the `courses` collection using `courseId`
            final displayInfo = ClassDisplayInfo(
              courseName: 'Course: ${classLog.courseId}', // Placeholder
              time: DateFormat.jm().format(classLog.scheduledDate.toDate()),
              room: 'N/A', // Room info is in routine, not classLog
              status: classLog.status,
            );
            return ClassListItem(
              info: displayInfo,
              onDownloadNotes: classLog.notesUrl == null ? null : () async {
                final uri = Uri.parse(classLog.notesUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              onProvideFeedback: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackScreen(classLog: classLog)),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyRoutine(BuildContext context, FirestoreService service, String semester) {
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getWeeklyRoutineForStudent(semester),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Weekly routine not available.'));
        }
        final routine = snapshot.data!;
        // Group by day for better display
        final Map<String, List<RoutineModel>> groupedRoutine = {};
        for (var item in routine) {
          (groupedRoutine[item.dayOfWeek] ??= []).add(item);
        }

        final sortedDays = groupedRoutine.keys.toList()..sort((a,b) {
          const dayOrder = {"Saturday": 1, "Sunday": 2, "Monday": 3, "Tuesday": 4, "Wednesday": 5, "Thursday": 6, "Friday": 7};
          return dayOrder[a]!.compareTo(dayOrder[b]!);
        });

        return ListView.builder(
          itemCount: sortedDays.length,
          itemBuilder: (context, index) {
            final day = sortedDays[index];
            final dayClasses = groupedRoutine[day]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(day, style: Theme.of(context).textTheme.headlineSmall),
                ),
                ...dayClasses.map((item) {
                  final displayInfo = ClassDisplayInfo(
                      courseName: 'Course: ${item.courseId}', // Placeholder
                      time: '${DateFormat.jm().format(item.startTime.toDate())} - ${DateFormat.jm().format(item.endTime.toDate())}',
                      room: item.room,
                      status: 'Scheduled'
                  );
                  return ClassListItem(info: displayInfo);
                }),
              ],
            );
          },
        );
      },
    );
  }
}