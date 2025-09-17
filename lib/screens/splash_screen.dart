// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/utils/app_styles.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'teacher/teacher_dashboard.dart';
import 'student/student_dashboard.dart';
import 'admin/admin_dashboard.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: Provider.of<AuthService>(context, listen: false).user,
      builder: (context, snapshot) {
        // Use a post-frame callback to navigate after the first frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            Widget destination;

            if (user == null) {
              destination = const LoginScreen();
            } else {
              switch (user.role) {
                case 'teacher':
                  destination = user.isVerified
                      ? const TeacherDashboard()
                      : const VerificationPendingScreen();
                  break;
                case 'student':
                  destination = const StudentDashboard();
                  break;
                case 'admin':
                  destination = user.isVerified
                      ? const AdminDashboard()
                      : const VerificationPendingScreen();
                  break;
                default:
                  destination = const LoginScreen();
              }
            }
            // Navigate with a fade transition
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => destination,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          }
        });

        // While waiting, show a branded splash screen
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/app_logo.png', width: 150),
                const SizedBox(height: 30),
                const SpinKitFadingCircle(
                  color: Colors.white,
                  size: 50.0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// A generic screen for users pending verification
class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty_rounded, size: 60, color: AppColors.primary),
              const SizedBox(height: 20),
              const Text(
                'Verification Pending',
                style: AppTextStyles.headline2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your account is awaiting approval from an administrator. Please check back later.',
                style: AppTextStyles.bodyText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextButton(
                  onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
                  child: const Text('Logout')),
            ],
          ),
        ),
      ),
    );
  }
}