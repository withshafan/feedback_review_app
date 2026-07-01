import 'package:flutter/material.dart';

class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'All Feedback',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
