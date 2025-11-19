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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
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
            'Teacher Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.grey[700]),
              onPressed: () => _showLogoutDialog(context, authService),
              tooltip: 'Logout',
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                text: "Today's Classes",
                icon: Icon(Icons.today_outlined),
                iconMargin: EdgeInsets.zero,
              ),
              Tab(
                text: 'Weekly Schedule',
                icon: Icon(Icons.calendar_month_outlined),
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
                'Unable to load teacher data',
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
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          child: const Icon(Icons.add),
          tooltip: 'Add Extra Class',
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

  Widget _buildWeeklySchedule(
    BuildContext context,
    FirestoreService service,
    String teacherId,
  ) {
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getTeacherWeeklyRoutine(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Network Error',
            'Failed to load schedule data',
            Icons.wifi_off,
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No Weekly Schedule',
            'Your weekly teaching schedule will appear here',
            Icons.calendar_today_outlined,
          );
        }

        final routines = snapshot.data!;
        final Map<String, List<RoutineModel>> groupedRoutine = {};

        for (var item in routines) {
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

            return _buildDaySection(context, day, dayClasses);
          },
        );
      },
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    String day,
    List<RoutineModel> dayClasses,
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
              ],
            ),
            const SizedBox(height: 16),
            ...dayClasses.map(
              (routine) => _buildScheduleItem(context, routine),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context, RoutineModel routine) {
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
                  routine.courseId,
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
        ],
      ),
    );
  }

  Widget _buildTodaysActions(
    BuildContext context,
    FirestoreService service,
    UserModel teacher,
  ) {
    return StreamBuilder<List<RoutineModel>>(
      stream: service.getTeacherWeeklyRoutine(teacher.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(
            'Network Error',
            'Failed to load today\'s classes',
            Icons.wifi_off,
          );
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            'No Schedule Data',
            'Unable to load teaching schedule',
            Icons.error_outline,
          );
        }

        final routineForToday = snapshot.data!
            .where(
              (r) =>
                  r.dayOfWeek.toLowerCase() ==
                  DateFormat('EEEE').format(DateTime.now()).toLowerCase(),
            )
            .toList();

        if (routineForToday.isEmpty) {
          return _buildEmptyState(
            'No Classes Today',
            'You have no classes scheduled for today',
            Icons.event_available_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: routineForToday.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final routineItem = routineForToday[index];
            return _buildTodayClassCard(context, service, teacher, routineItem);
          },
        );
      },
    );
  }

  Widget _buildTodayClassCard(
    BuildContext context,
    FirestoreService service,
    UserModel teacher,
    RoutineModel routineItem,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        routineItem.courseId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat.jm().format(routineItem.startTime.toDate())} - ${DateFormat.jm().format(routineItem.endTime.toDate())}',
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
                            routineItem.room,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            routineItem.semester,
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
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 16),
            _buildActionButtons(context, service, teacher, routineItem),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    FirestoreService service,
    UserModel teacher,
    RoutineModel routineItem,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Confirm',
            Icons.check_circle_outline,
            Colors.green,
            () {
              _showActionDialog(
                context,
                'Confirm Class',
                'This will notify students that "${routineItem.courseId}" class is happening as scheduled.',
                () {
                  service.createClassLog(
                    courseId: routineItem.courseId,
                    teacherId: teacher.uid,
                    semester: routineItem.semester,
                    status: 'confirmed',
                    scheduledDate: routineItem.startTime.toDate(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${routineItem.courseId} class confirmed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            'Cancel',
            Icons.cancel_outlined,
            Colors.red,
            () {
              _showActionDialog(
                context,
                'Cancel Class',
                'Are you sure you want to cancel "${routineItem.courseId}" class? This will notify all students.',
                () {
                  service.createClassLog(
                    courseId: routineItem.courseId,
                    teacherId: teacher.uid,
                    semester: routineItem.semester,
                    status: 'cancelled',
                    scheduledDate: routineItem.startTime.toDate(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${routineItem.courseId} class cancelled'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            'Upload Notes',
            Icons.upload_file_outlined,
            Colors.blue,
            () {
              _showActionDialog(
                context,
                'Upload Notes',
                'You can upload notes for "${routineItem.courseId}" class after it has been confirmed.',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please confirm the class first to upload notes',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}
