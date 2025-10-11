import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/models/class_log_model.dart';
import 'package:smart_class_sync/models/routine_model.dart';
import 'package:smart_class_sync/services/auth_service.dart';
import 'package:smart_class_sync/services/firestore_service.dart';
import 'package:smart_class_sync/widgets/class_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
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
              Tab(text: "Upcoming Classes", icon: Icon(Icons.event)),
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
                  _buildUpcomingClasses(context, firestoreService, semester),
                  _buildWeeklyRoutine(context, firestoreService, semester),
                ],
              );
            }
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses(BuildContext context, FirestoreService service, String semester) {
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getWeeklyRoutineForStudent(semester),
      builder: (context, routineSnapshot) {
        if (routineSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (routineSnapshot.hasError) {
          return Center(child: Text('Error: ${routineSnapshot.error}'));
        }
        final routines = routineSnapshot.data ?? [];

        return StreamBuilder<List<ClassLogModel>>(
          stream: service.getUpcomingClassesForStudent(semester),
          builder: (context, logSnapshot) {
            if (logSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (logSnapshot.hasError) {
              return Center(child: Text('Error: ${logSnapshot.error}'));
            }
            final logs = logSnapshot.data ?? [];

            return FutureBuilder<Map<String, String>>(
              future: service.getCourseIdToNameMap(),
              builder: (context, mapSnapshot) {
                if (mapSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (mapSnapshot.hasError) {
                  return Center(child: Text('Error: ${mapSnapshot.error}'));
                }
                final courseMap = mapSnapshot.data ?? {};

                // Compute upcoming classes: projected routines + logs
                List<ClassLogModel> upcoming = List.from(logs);

                DateTime now = DateTime.now();
                DateTime startOfToday = DateTime(now.year, now.month, now.day);
                DateTime endPeriod = startOfToday.add(const Duration(days: 7));

                const Map<String, int> dayToWeekday = {
                  "Monday": DateTime.monday,
                  "Tuesday": DateTime.tuesday,
                  "Wednesday": DateTime.wednesday,
                  "Thursday": DateTime.thursday,
                  "Friday": DateTime.friday,
                  "Saturday": DateTime.saturday,
                  "Sunday": DateTime.sunday,
                };

                for (var routine in routines) {
                  int? weekday = dayToWeekday[routine.dayOfWeek];
                  if (weekday == null) continue;

                  DateTime? routineStartTime = routine.startTime?.toDate();
                  if (routineStartTime == null) continue;

                  for (DateTime date = startOfToday; date.isBefore(endPeriod); date = date.add(const Duration(days: 1))) {
                    if (date.weekday == weekday) {
                      DateTime scheduledDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        routineStartTime.hour,
                        routineStartTime.minute,
                        routineStartTime.second,
                      );
                      Timestamp scheduledTimestamp = Timestamp.fromDate(scheduledDateTime);

                      // Check if a matching log already exists (same course and exact time)
                      bool exists = logs.any((log) =>
                      log.courseId == routine.courseId &&
                          log.scheduledDate == scheduledTimestamp
                      );

                      if (!exists) {
                        // Create virtual ClassLogModel
                        Map<String, dynamic> virtualData = {
                          'courseId': routine.courseId,
                          'teacherId': '', // Not needed for display
                          'semester': semester,
                          'status': 'Scheduled',
                          'scheduledDate': scheduledTimestamp,
                          'notesUrl': null,
                          'notificationSent': false,
                        };
                        ClassLogModel virtual = ClassLogModel.fromFirestore(virtualData, 'virtual_${routine.id ?? ''}_${date.millisecondsSinceEpoch}');
                        upcoming.add(virtual);
                      }
                    }
                  }
                }

                // Sort by scheduled date
                upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

                if (upcoming.isEmpty) {
                  return const Center(child: Text('No classes scheduled in the next 7 days.'));
                }

                return ListView.builder(
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final classLog = upcoming[index];
                    final courseName = courseMap[classLog.courseId] ?? classLog.courseId;

                    // Lookup room from matching routine based on day and course
                    String room = 'N/A';
                    String dayName = DateFormat('EEEE').format(classLog.scheduledDate.toDate());
                    RoutineModel? matchingRoutine;
                    try {
                      matchingRoutine = routines.firstWhere(
                            (r) => r.courseId == classLog.courseId && r.dayOfWeek == dayName,
                      );
                    } catch (e) {
                      matchingRoutine = null;
                    }
                    if (matchingRoutine != null) {
                      room = matchingRoutine.room ?? 'N/A';
                    }

                    final displayInfo = ClassDisplayInfo(
                      courseName: courseName,
                      time: DateFormat('E, MMM d • hh:mm a').format(classLog.scheduledDate.toDate()),
                      room: room,
                      status: classLog.status,
                    );

                    bool isVirtual = classLog.id.startsWith('virtual_');

                    return ClassListItem(
                      info: displayInfo,
                      onDownloadNotes: classLog.notesUrl == null ? null : () async {
                        final uri = Uri.parse(classLog.notesUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      onProvideFeedback: isVirtual ? null : () {
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
          },
        );
      },
    );
  }

  Widget _buildWeeklyRoutine(BuildContext context, FirestoreService service, String semester) {
    return FutureBuilder<Map<String, String>>(
      future: service.getCourseIdToNameMap(),
      builder: (context, mapSnapshot) {
        if (mapSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (mapSnapshot.hasError) {
          return Center(child: Text('Error: ${mapSnapshot.error}'));
        }
        final courseMap = mapSnapshot.data ?? {};

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
            final Map<String, List<RoutineModel>> groupedRoutine = {};
            for (var item in routine) {
              (groupedRoutine[item.dayOfWeek] ??= []).add(item);
            }

            final sortedDays = groupedRoutine.keys.toList()..sort((a, b) {
              const dayOrder = {"Saturday": 1, "Sunday": 2, "Monday": 3, "Tuesday": 4, "Wednesday": 5, "Thursday": 6, "Friday": 7};
              return (dayOrder[a] ?? 8).compareTo(dayOrder[b] ?? 8);
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
                      final courseName = courseMap[item.courseId] ?? item.courseId;
                      final displayInfo = ClassDisplayInfo(
                          courseName: courseName,
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
      },
    );
  }
}
