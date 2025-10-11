import 'package:flutter/material.dart';

class ManageRoutineScreen extends StatelessWidget {
  const ManageRoutineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Routine'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Routine management UI will be built in Module 3.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}