import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/class_log_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class FeedbackScreen extends StatefulWidget {
  final ClassLogModel classLog;
  const FeedbackScreen({super.key, required this.classLog});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double _rating = 3.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  void _submitFeedback() async {
    setState(() => _isLoading = true);
    final user = await Provider.of<AuthService>(
      context,
      listen: false,
    ).user.first;
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    if (user != null) {
      await firestoreService.submitFeedback(
        classLogId: widget.classLog.id,
        studentId: user.uid,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
        Navigator.pop(context);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provide Feedback'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Course: ${widget.classLog.courseId}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              'Your Rating: ${_rating.toInt()} Stars',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _rating,
              onChanged: (newRating) => setState(() => _rating = newRating),
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.toInt().toString(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Additional Comments (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}
