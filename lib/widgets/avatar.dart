import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class Avatar extends StatelessWidget {
  final String name;
  final String photoUrl;
  final double radius;
  final bool showOnline;

  const Avatar({
    super.key,
    required this.name,
    this.photoUrl = '',
    this.radius = 28,
    this.showOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: photoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitials(theme, isDark),
                  ),
                )
              : _buildInitials(theme, isDark),
        ),
        if (showOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF10b981),
                border: Border.all(
                  color: isDark ? const Color(0xFF1e293b) : Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials(ThemeData theme, bool isDark) {
    return Center(
      child: Text(
        getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
