import 'dart:convert';

import 'package:emitrace/src/models/breadcrumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BreadcrumbTile extends StatefulWidget {
  final Breadcrumb breadcrumb;
  final VoidCallback? onOpenDetails;

  const BreadcrumbTile({
    super.key,
    required this.breadcrumb,
    this.onOpenDetails,
  });

  @override
  State<BreadcrumbTile> createState() => _BreadcrumbTileState();
}

class _BreadcrumbTileState extends State<BreadcrumbTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final breadcrumb = widget.breadcrumb;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF151726),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _typeColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: _typeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _typeColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _typeLabel,
                                style: TextStyle(
                                  color: _typeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDateTime(breadcrumb.timestamp),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          breadcrumb.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      InkWell(
                        onTap: _copyTileContent,
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy_rounded,
                            color: Colors.white54,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white54,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1120),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _prettyJson(widget.breadcrumb.data),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (widget.onOpenDetails != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onOpenDetails,
                        child: const Text('Open full details'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _prettyJson(dynamic value) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _copyTileContent() async {
    final content = StringBuffer()
      ..writeln('[${widget.breadcrumb.type.toUpperCase()}] '
          '${_formatDateTime(widget.breadcrumb.timestamp)}')
      ..writeln(widget.breadcrumb.message)
      ..writeln(_prettyJson(widget.breadcrumb.data));

    await Clipboard.setData(ClipboardData(text: content.toString()));
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Log copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Color get _typeColor {
    switch (widget.breadcrumb.type) {
      case 'network':
        return const Color(0xFF00C7A8);
      case 'error':
        return const Color(0xFFFF6B6B);
      case 'navigation':
        return const Color(0xFF6AA2FF);
      case 'action':
        return const Color(0xFFFFB347);
      case 'event':
        return const Color(0xFF7EE081);
      case 'log':
        return const Color(0xFFCEB9FF);
      case 'report':
        return const Color(0xFF4CD5FF);
      case 'slack':
        return const Color(0xFFB17ACC);
      case 'discord':
        return const Color(0xFF8097FF);
      default:
        return Colors.white54;
    }
  }

  String _formatDateTime(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  String get _typeLabel {
    if (widget.breadcrumb.type == 'navigation') return 'ROUTE';
    return widget.breadcrumb.type.toUpperCase();
  }
}
