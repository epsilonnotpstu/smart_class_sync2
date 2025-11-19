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
import 'student_profile_screen.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

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
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Student Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.person, color: Colors.grey[700]),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StudentProfileScreen(),
                  ),
                );
              },
              tooltip: 'Profile',
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.grey[700]),
              onPressed: () => _showLogoutDialog(context, authService),
              tooltip: 'Logout',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                text: "Upcoming",
                icon: Icon(Icons.upcoming_outlined),
                iconMargin: EdgeInsets.zero,
              ),
              Tab(
                text: 'Routine',
                icon: Icon(Icons.calendar_today_outlined),
                iconMargin: EdgeInsets.zero,
              ),
            ],
            indicatorColor: Colors.blue.shade600,
            labelColor: Colors.blue.shade600,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
          ),
        ),
        body: StreamBuilder<UserModel?>(
          stream: authService.user,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (!userSnapshot.hasData || userSnapshot.data == null) {
              return _buildErrorState(
                'Authentication Error',
                'Please login again',
                Icons.error_outline,
              );
            }

            if (userSnapshot.hasError) {
              return _buildErrorState(
                'Connection Error',
                'Unable to load user data',
                Icons.cloud_off,
              );
            }

            final student = userSnapshot.data!;
            final semester = student.semester ?? '1st';

            return TabBarView(
              children: [
                _buildUpcomingClasses(context, firestoreService, semester),
                _buildWeeklyRoutine(context, firestoreService, semester),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                authService.signOut();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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
            'Loading...',
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

  Widget _buildUpcomingClasses(
    BuildContext context,
    FirestoreService service,
    String semester,
  ) {
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getWeeklyRoutineForStudent(semester),
      builder: (context, routineSnapshot) {
        if (routineSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (routineSnapshot.hasError) {
          return _buildErrorState(
            'Network Error',
            'Failed to load routine data',
            Icons.wifi_off,
          );
        }

        final routines = routineSnapshot.data ?? [];

        return StreamBuilder<List<ClassLogModel>>(
          stream: service.getUpcomingClassesForStudent(semester),
          builder: (context, logSnapshot) {
            if (logSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (logSnapshot.hasError) {
              return _buildErrorState(
                'Network Error',
                'Failed to load class data',
                Icons.wifi_off,
              );
            }

            final logs = logSnapshot.data ?? [];

            return FutureBuilder<Map<String, String>>(
              future: service.getCourseIdToNameMap(),
              builder: (context, mapSnapshot) {
                if (mapSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (mapSnapshot.hasError) {
                  return _buildErrorState(
                    'Data Error',
                    'Failed to load course information',
                    Icons.error_outline,
                  );
                }

                final courseMap = mapSnapshot.data ?? {};

                // Compute upcoming classes
                List<ClassLogModel> upcoming = _computeUpcomingClasses(
                  logs,
                  routines,
                  semester,
                );

                if (upcoming.isEmpty) {
                  return _buildEmptyState(
                    'No Upcoming Classes',
                    'Classes scheduled for the next 7 days will appear here',
                    Icons.event_available_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Force refresh by rebuilding streams
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: upcoming.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final classLog = upcoming[index];
                      final courseName =
                          courseMap[classLog.courseId] ?? classLog.courseId;
                      final room = _findRoomForClass(classLog, routines);

                      final displayInfo = ClassDisplayInfo(
                        courseName: courseName,
                        time: DateFormat(
                          'E, MMM d • hh:mm a',
                        ).format(classLog.scheduledDate.toDate()),
                        room: room,
                        status: classLog.status,
                      );

                      bool isVirtual = classLog.id.startsWith('virtual_');

                      return _buildClassCard(
                        context,
                        displayInfo,
                        classLog,
                        isVirtual,
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<ClassLogModel> _computeUpcomingClasses(
    List<ClassLogModel> logs,
    List<RoutineModel> routines,
    String semester,
  ) {
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

      DateTime routineStartTime = routine.startTime.toDate();

      for (
        DateTime date = startOfToday;
        date.isBefore(endPeriod);
        date = date.add(const Duration(days: 1))
      ) {
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

          bool exists = logs.any(
            (log) =>
                log.courseId == routine.courseId &&
                log.scheduledDate == scheduledTimestamp,
          );

          if (!exists) {
            Map<String, dynamic> virtualData = {
              'courseId': routine.courseId,
              'teacherId': '',
              'semester': semester,
              'status': 'Scheduled',
              'scheduledDate': scheduledTimestamp,
              'notesUrl': null,
              'notificationSent': false,
            };
            ClassLogModel virtual = ClassLogModel.fromFirestore(
              virtualData,
              'virtual_${routine.id}_${date.millisecondsSinceEpoch}',
            );
            upcoming.add(virtual);
          }
        }
      }
    }

    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return upcoming;
  }

  String _findRoomForClass(
    ClassLogModel classLog,
    List<RoutineModel> routines,
  ) {
    String dayName = DateFormat('EEEE').format(classLog.scheduledDate.toDate());
    try {
      RoutineModel? matchingRoutine = routines.firstWhere(
        (r) => r.courseId == classLog.courseId && r.dayOfWeek == dayName,
      );
      return matchingRoutine.room;
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildClassCard(
    BuildContext context,
    ClassDisplayInfo displayInfo,
    ClassLogModel classLog,
    bool isVirtual,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(displayInfo.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayInfo.courseName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayInfo.time,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            displayInfo.room,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(displayInfo.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayInfo.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(displayInfo.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (classLog.notesUrl != null) ...[
                  _buildActionButton(
                    context,
                    'Download Notes',
                    Icons.download_outlined,
                    () async {
                      final uri = Uri.parse(classLog.notesUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (!isVirtual) ...[
                  _buildActionButton(
                    context,
                    'Feedback',
                    Icons.feedback_outlined,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FeedbackScreen(classLog: classLog),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue.shade600,
        side: BorderSide(color: Colors.blue.shade100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'ongoing':
        return Colors.orange;
      case 'scheduled':
      default:
        return Colors.blue;
    }
  }

  Widget _buildWeeklyRoutine(
    BuildContext context,
    FirestoreService service,
    String semester,
  ) {
    return FutureBuilder<Map<String, String>>(
      future: service.getCourseIdToNameMap(),
      builder: (context, mapSnapshot) {
        if (mapSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (mapSnapshot.hasError) {
          return _buildErrorState(
            'Data Error',
            'Failed to load course information',
            Icons.error_outline,
          );
        }

        final courseMap = mapSnapshot.data ?? {};

        return StreamBuilder<List<RoutineModel>>(
          stream: service.getWeeklyRoutineForStudent(semester),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(
                'Network Error',
                'Failed to load routine data',
                Icons.wifi_off,
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(
                'No Routine Available',
                'Your weekly routine will appear here once scheduled',
                Icons.calendar_today_outlined,
              );
            }

            final routine = snapshot.data!;
            final Map<String, List<RoutineModel>> groupedRoutine = {};
            for (var item in routine) {
              (groupedRoutine[item.dayOfWeek] ??= []).add(item);
            }

            final sortedDays = _sortDays(groupedRoutine.keys.toList());

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDays.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final day = sortedDays[index];
                final dayClasses = groupedRoutine[day]!;
                dayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

                return _buildDaySection(context, day, dayClasses, courseMap);
              },
            );
          },
        );
      },
    );
  }

  List<String> _sortDays(List<String> days) {
    const dayOrder = {
      "Saturday": 1,
      "Sunday": 2,
      "Monday": 3,
      "Tuesday": 4,
      "Wednesday": 5,
      "Thursday": 6,
      "Friday": 7,
    };
    days.sort((a, b) => (dayOrder[a] ?? 8).compareTo(dayOrder[b] ?? 8));
    return days;
  }

  Widget _buildDaySection(
    BuildContext context,
    String day,
    List<RoutineModel> dayClasses,
    Map<String, String> courseMap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              ],
            ),
            const SizedBox(height: 12),
            ...dayClasses.map((item) {
              final courseName = courseMap[item.courseId] ?? item.courseId;
              return _buildRoutineItem(context, item, courseName);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineItem(
    BuildContext context,
    RoutineModel item,
    String courseName,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat.jm().format(item.startTime.toDate())} - ${DateFormat.jm().format(item.endTime.toDate())}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.place_outlined, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  item.room,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
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
}
