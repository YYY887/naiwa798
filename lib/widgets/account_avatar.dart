import 'package:flutter/material.dart';

import '../core/app_palette.dart';

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({
    required this.account,
    required this.size,
    this.dark = false,
    super.key,
  });

  final Map<String, dynamic>? account;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final url = account?['img']?.toString();
    final name = account?['name']?.toString();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors(dark).tint,
      foregroundColor: AppColors(dark).accent,
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: url == null || url.isEmpty
          ? Text(
              name == null || name.isEmpty
                  ? '我'
                  : name.substring(0, 1).toUpperCase(),
            )
          : null,
    );
  }
}
