import 'package:flutter/material.dart';
import '../../core/emitrace_controller.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = EmitraceController();
    final networkEvents = controller.breadCrumbs.reversed
        .where((b) => b.type == 'network')
        .toList();

    if (networkEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'No network calls yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add EmitraceDioInterceptor to your Dio instance',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: networkEvents.length,
      itemBuilder: (context, index) {
        final event = networkEvents[index];
        final statusCode =
            event.data['statusCode'] as int? ?? 0;
        final responseTime =
            event.data['responseTimeMs'] as int? ?? 0;
        final isSuccess =
            statusCode >= 200 && statusCode < 300;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSuccess
                  ? const Color(0xFF00D4AA)
                  : const Color(0xFFFF5555),
              width: 3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Method badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.data['method'] ?? 'GET',
                      style: const TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // URL
                  Expanded(
                    child: Text(
                      event.data['url'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  // Status code
                  Text(
                    '$statusCode',
                    style: TextStyle(
                      color: isSuccess
                          ? const Color(0xFF00D4AA)
                          : const Color(0xFFFF5555),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Response time
                  Text(
                    '${responseTime}ms',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),

                  const Spacer(),

                  // Timestamp
                  Text(
                    '${event.timestamp.hour}:'
                    '${event.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${event.timestamp.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
