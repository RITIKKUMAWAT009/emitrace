import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/emitrace_controller.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final Set<int> _expanded = <int>{};

  Future<void> _copyNetworkEvent(
    BuildContext context, {
    required dynamic event,
    required int statusCode,
    required int responseTime,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final method = event.data['method']?.toString() ?? 'GET';
    final url = event.data['url']?.toString() ?? '';
    final payload = StringBuffer()
      ..writeln('[NETWORK] ${event.timestamp.toIso8601String()}')
      ..writeln('$method $url -> $statusCode (${responseTime}ms)')
      ..writeln(const JsonEncoder.withIndent('  ').convert(event.data));

    await Clipboard.setData(ClipboardData(text: payload.toString()));
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Network log copied'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
        final statusCode = event.data['statusCode'] as int? ?? 0;
        final responseTime = event.data['responseTimeMs'] as int? ?? 0;
        final isSuccess = statusCode >= 200 && statusCode < 300;
        final isExpanded = _expanded.contains(index);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSuccess ? const Color(0xFF00D4AA) : const Color(0xFFFF5555),
              width: 3,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expanded.remove(index);
                    } else {
                      _expanded.add(index);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
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
                          IconButton(
                            tooltip: 'Copy network log',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: Colors.white54,
                            ),
                            onPressed: () => _copyNetworkEvent(
                              context,
                              event: event,
                              statusCode: statusCode,
                              responseTime: responseTime,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
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
                          Text(
                            '${responseTime}ms',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
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
                ),
              ),
              if (isExpanded)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11111B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(event.data),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
