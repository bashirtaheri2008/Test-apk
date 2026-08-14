import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class Avatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double radius;
  final bool showOnline;
  final bool showRing;
  final bool ringViewed;

  const Avatar({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.radius = 28,
    this.showOnline = false,
    this.showRing = false,
    this.ringViewed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (showRing)
          Container(
            width: radius * 2 + 6,
            height: radius * 2 + 6,
            decoration: BoxDecoration(
              gradient: ringViewed
                ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade400])
                : const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF0ea5e9)]),
              borderRadius: BorderRadius.circular(radius + 3),
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: _buildInner(theme),
            ),
          )
        else
          _buildInner(theme),
        if (showOnline)
          Positioned(
            bottom: -1,
            right: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF10b981),
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInner(ThemeData theme) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: photoUrl.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(photoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(theme)),
          )
        : _initials(theme),
    );
  }

  Widget _initials(ThemeData theme) {
    return Center(child: Text(getInitials(name),
      style: TextStyle(color: Colors.white, fontSize: radius * 0.5, fontWeight: FontWeight.bold)));
  }
}
