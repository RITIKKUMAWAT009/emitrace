import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/emitrace_controller.dart';
import '../../models/breadcrumb.dart';
import '../widgets/breadcrumb_tile.dart';

/// Shows all breadcrumbs in reverse chronological order
/// Most recent event at top
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _controller = EmitraceController();

  // Filter options
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'label': 'All', 'value': 'all'},
    {'label': '🌐 Network', 'value': 'network'},
    {'label': '❌ Errors', 'value': 'error'},
    {'label': '🧭 Nav', 'value': 'navigation'},
    {'label': '📝 Logs', 'value': 'log'},
  ];

  List get _filteredBreadcrumbs {
    final all = _controller.breadCrumbs.reversed.toList();
    if (_selectedFilter == 'all') return all;
    return all.where((b) => b.type == _selectedFilter).toList();
  }

  String _prettyJson(dynamic value) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  Future<void> _openDetails(Breadcrumb breadcrumb) async {
    final screenshotPath = breadcrumb.data['screenshotPath']?.toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0F),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${breadcrumb.type.toUpperCase()}  •  ${breadcrumb.timestamp.toIso8601String()}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      breadcrumb.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Metadata / Body',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF11111B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _prettyJson(breadcrumb.data),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (screenshotPath != null && screenshotPath.isNotEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog<void>(
                                context: sheetContext,
                                builder: (dialogContext) {
                                  final file = File(screenshotPath);
                                  return Dialog(
                                    backgroundColor: Colors.black,
                                    child: file.existsSync()
                                        ? InteractiveViewer(
                                            child: Image.file(file),
                                          )
                                        : const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                              'Screenshot file not found',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                  );
                                },
                              );
                            },
                            child: const Text('View Screenshot'),
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Expanded(
                        //   child: ElevatedButton(
                        //     onPressed: () async {
                        //       final result = await _controller
                        //           .saveScreenshotToGallery(screenshotPath);
                        //       if (!mounted) return;
                        //       final ok = result['ok'] == true;
                        //       final msg = result['message']?.toString() ??
                        //           (ok ? 'Saved' : 'Failed');
                        //       _showFloatingMessage(
                        //         msg,
                        //         background: ok
                        //             ? const Color(0xFF00D4AA)
                        //             : const Color(0xFFFF5555),
                        //       );
                        //     },
                        //     child: const Text('Save Screenshot'),
                        //   ),
                        // ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips row
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter['value'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['value']!;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF6C63FF) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    filter['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Breadcrumb count
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_filteredBreadcrumbs.length} events',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),

              // Clear button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.clear();
                  });
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Color(0xFFFF5555),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Events list
        Expanded(
          child: _filteredBreadcrumbs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔍',
                        style: TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No events yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Interact with your app to see events',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredBreadcrumbs.length,
                  itemBuilder: (context, index) {
                    final breadcrumb =
                        _filteredBreadcrumbs[index] as Breadcrumb;
                    return GestureDetector(
                      onTap: () => _openDetails(breadcrumb),
                      child: BreadcrumbTile(
                        breadcrumb: breadcrumb,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
