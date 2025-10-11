import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_class_sync/services/auth_service.dart';
import 'manage_courses_screen.dart';
import 'manage_routine_screen.dart';
import 'manage_teachers_screen.dart';
import 'feedback_reports_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardItem(
            context,
            icon: Icons.verified_user_outlined,
            label: 'Verify Teachers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageTeachersScreen()),
              );
            },
          ),
          _buildDashboardItem(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Manage Routine',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageRoutineScreen()),
              );
            },
          ),
          _buildDashboardItem(
            context,
            icon: Icons.book_outlined,
            label: 'Manage Courses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageCoursesScreen()),
              );
            },
          ),
          _buildDashboardItem(
            context,
            icon: Icons.bar_chart_outlined,
            label: 'Feedback Reports',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackReportsScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This feature will be available in a future module.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.indigo),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}