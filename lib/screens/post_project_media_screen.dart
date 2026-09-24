import 'package:flutter/material.dart';

// TEMPORARY placeholder. Will be replaced with the actual
// Project-level Media (photos/video/cover) screen in the next step.
class PostProjectMediaScreen extends StatelessWidget {
  final int projectId;

  const PostProjectMediaScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Media (coming soon)")),
      body: Center(
        child: Text("Units saved! Project ID: $projectId\n\nThe next step will be built here."),
      ),
    );
  }
}