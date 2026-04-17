import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final bool glow;
  final IconData fallbackIcon;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.glow = false,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size / 2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageUrl.isEmpty
            ? const RadialGradient(
                colors: [Colors.cyanAccent, Color(0xFF006666)],
              )
            : null,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: imageUrl.isEmpty
            ? Icon(fallbackIcon, color: Colors.black, size: size * 0.45)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.cyanAccent, Color(0xFF006666)],
                    ),
                  ),
                  child: Icon(
                    fallbackIcon,
                    color: Colors.black,
                    size: size * 0.45,
                  ),
                ),
              ),
      ),
    );
  }
}
