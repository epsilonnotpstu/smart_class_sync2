import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'teacher/teacher_dashboard.dart';
import 'student/student_dashboard.dart';
import 'admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthService _authService;
  Stream<UserModel?>? _userStream;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _userStream = _authService.user;
    _userStream!.listen(_initNotificationsOnLogin);
  }

  void _initNotificationsOnLogin(UserModel? user) {
    if (user != null) {
      // ✅ User is logged in → initialize notification system
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final notificationService = NotificationService(firestoreService);
      notificationService.initNotifications(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        switch (user.role) {
          case 'teacher':
            return user.isVerified
                ? const TeacherDashboard()
                : const Scaffold(
              body: Center(child: Text('Pending Verification')),
            );
          case 'student':
            return const StudentDashboard();
          case 'admin':
            return user.isVerified
                ? const AdminDashboard()
                : const Scaffold(
              body: Center(child: Text('Pending Verification')),
            );
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
