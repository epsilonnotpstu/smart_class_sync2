import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A simple model to unify data from RoutineModel and ClassLogModel for display
class ClassDisplayInfo {
  final String courseName; // You will need to fetch this based on courseId
  final String time;
  final String room;
  final String status;

  ClassDisplayInfo({
    required this.courseName,
    required this.time,
    required this.room,
    required this.status,
  });
}

class ClassListItem extends StatelessWidget {
  final ClassDisplayInfo info;
  final VoidCallback? onDownloadNotes;
  final VoidCallback? onProvideFeedback;

  const ClassListItem({
    super.key,
    required this.info,
    this.onDownloadNotes,
    this.onProvideFeedback,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.schedule;

    switch (info.status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      case 'extra':
        statusColor = Colors.blue;
        statusIcon = Icons.add_circle_outline;
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.watch_later_outlined;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(info.courseName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${info.time} • Room: ${info.room}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDownloadNotes != null)
              IconButton(
                icon: Icon(Icons.download_outlined, color: Colors.blue.shade700),
                onPressed: onDownloadNotes,
                tooltip: 'Download Notes',
              ),
            if (onProvideFeedback != null)
              IconButton(
                icon: Icon(Icons.feedback_outlined, color: Colors.amber.shade700),
                onPressed: onProvideFeedback,
                tooltip: 'Provide Feedback',
              ),
          ],
        ),
      ),
    );
  }
}