import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class TeacherListScreen extends StatelessWidget {
  const TeacherListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Teachers',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        elevation: 0,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.getUsersByRole('teacher'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load teachers: ${snapshot.error}'),
            );
          }

          final teachers = snapshot.data ?? [];
          if (teachers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No teachers found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add teachers from the registration or admin panel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final t = teachers[index];
              final displayName = _displayNameFor(t);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      _initials(displayName),
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(t.email),
                  trailing: IconButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[700]),
                    onPressed: () => _showTeacherDetails(context, t),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _displayNameFor(UserModel t) {
    // Prefer a human-readable name if available; fall back to email/uid
    final fields = <String?>[t.fullName, t.displayName, t.email, t.uid];
    for (var f in fields) {
      if (f != null && f.isNotEmpty) return f;
    }
    return 'Teacher';
  }

  String _initials(String text) {
    final parts = text.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  void _showTeacherDetails(BuildContext context, UserModel t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.fullName ?? t.email),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('UID', t.uid),
            const SizedBox(height: 8),
            _detailRow('Email', t.email),
            const SizedBox(height: 8),
            if (t.department != null) ...[
              _detailRow('Department', t.department!),
              const SizedBox(height: 8),
            ],
            if (t.designation != null) ...[
              _detailRow('Designation', t.designation!),
              const SizedBox(height: 8),
            ],
            if (t.phone != null) ...[_detailRow('Phone', t.phone!)],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value, textAlign: TextAlign.right)),
      ],
    );
  }
}
