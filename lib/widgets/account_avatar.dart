import 'package:flutter/material.dart';

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
      backgroundColor: dark ? const Color(0xff252525) : const Color(0xffdff1ef),
      foregroundColor: dark ? Colors.white : const Color(0xff171717),
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
