import 'package:emitrace/src/models/breadcrumb.dart';
import 'package:flutter/material.dart';

class BreadcrumbTile extends StatelessWidget {
  final Breadcrumb breadcrumb;
  const BreadcrumbTile({super.key, required this.breadcrumb});

  @override
  Widget build(BuildContext context) {
    return Container(
       margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _typeColor,
          width: 3,
        ),
      ),
      child: Row(
        children: [
  // Type icon
          Text(
            _typeIcon,
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(width: 8),

          // Message + timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message
                Text(
                  breadcrumb.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),

                const SizedBox(height: 2),

                // Timestamp
                Text(
                  _formatTime(breadcrumb.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              breadcrumb.type.toUpperCase(),
              style: TextStyle(
                color: _typeColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

    );
  }

   // Color based on event type
  Color get _typeColor {
    switch (breadcrumb.type) {
      case 'network':
        return const Color(0xFF00D4AA); // teal
      case 'error':
        return const Color(0xFFFF5555); // red
      case 'navigation':
        return const Color(0xFF6C63FF); // purple
      case 'log':
        return const Color(0xFFFFB86C); // orange
      case 'report':
        return const Color(0xFF00D4AA);
      case 'slack':
        return const Color(0xFF4A154B);
      default:
        return Colors.white54;
    }
  }

  // Icon based on event type
  String get _typeIcon {
    switch (breadcrumb.type) {
      case 'network':
        return '🌐';
      case 'error':
        return '❌';
      case 'navigation':
        return '🧭';
      case 'log':
        return '📝';
      case 'report':
        return '📄';
      case 'slack':
        return '💬';
      default:
        return '•';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
