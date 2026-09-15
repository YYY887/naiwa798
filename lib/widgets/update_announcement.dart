import 'package:flutter/material.dart';

class UpdateAnnouncement extends StatelessWidget {
  const UpdateAnnouncement({required this.notes, super.key});

  final String notes;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 260),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('更新公告', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(notes),
        ],
      ),
    ),
  );
}
