import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';

class FeedbackReportsScreen extends StatelessWidget {
  const FeedbackReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: firestoreService.getAllFeedback(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No feedback has been submitted yet.'));
          }

          final feedbackList = snapshot.data!;

          return ListView.builder(
            itemCount: feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = feedbackList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(feedback.rating.toString())),
                  title: Text('Class: ${feedback.classLogId}'),
                  subtitle: Text(feedback.comment ?? 'No comment provided.'),
                  trailing: Text(DateFormat.yMd().format(feedback.submittedAt.toDate())),
                ),
              );
            },
          );
        },
      ),
    );
  }
}