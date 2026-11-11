import 'package:flutter/material.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 24,
  });

  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final value = avatarUrl?.trim();
    if (value != null && value.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        backgroundImage: NetworkImage(value),
        onBackgroundImageError: (_, __) {},
      );
    }

    if (value != null && value.startsWith('preset:')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Text(
          value.substring('preset:'.length),
          style: TextStyle(fontSize: radius * 1.15),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.person_outline, size: radius * 1.15),
    );
  }
}
