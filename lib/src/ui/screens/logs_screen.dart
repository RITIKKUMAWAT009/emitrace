import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/emitrace_controller.dart';
import '../../models/breadcrumb.dart';
import '../widgets/breadcrumb_tile.dart';

/// Timeline and log exploration screen.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final EmitraceController _controller = EmitraceController();

  String _selectedFilter = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _filters = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Log', 'value': 'log'},
    {'label': 'Event', 'value': 'event'},
    {'label': 'Action', 'value': 'action'},
    {'label': 'Nav', 'value': 'navigation'},
    {'label': 'Network', 'value': 'network'},
    {'label': 'Error', 'value': 'error'},
  ];

  List<Breadcrumb> get _filteredBreadcrumbs {
    return _controller.queryTimeline(
      filter: _selectedFilter,
      searchQuery: _searchQuery,
    );
  }

  Map<String, List<Breadcrumb>> get _groupedTimeline {
    final map = <String, List<Breadcrumb>>{};
    for (final breadcrumb in _filteredBreadcrumbs) {
      final key = _dateHeader(breadcrumb.timestamp);
      map.putIfAbsent(key, () => <Breadcrumb>[]).add(breadcrumb);
    }
    return map;
  }

  String _prettyJson(dynamic value) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openDetails(Breadcrumb breadcrumb) async {
    final screenshotPath = breadcrumb.data['screenshotPath']?.toString();
    final crashSummary = _controller.buildCrashContextSummary();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0F),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.84,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timeline Details',
                    style: TextStyle(
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
                  if (breadcrumb.type == 'error') ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171B2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x26FF6B6B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crash Context Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Latest route: ${crashSummary['latestRoute'] ?? 'unknown'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Previous route: ${crashSummary['previousRoute'] ?? 'unknown'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Screenshot: ${crashSummary['screenshotPath'] ?? 'not available'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                  );
                                },
                              );
                            },
                            child: const Text('View Screenshot'),
                          ),
                        ),
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
    final groups = _groupedTimeline;
    final items = _filteredBreadcrumbs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search message, route, url, method, metadata...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white54, size: 18),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(
                        Icons.clear,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFF141728),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6AA2FF)),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3459FF)
                        : const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF3459FF) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    filter['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} events',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.clear();
                  });
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyState(
                  hasSearch: _searchQuery.trim().isNotEmpty,
                  hasFilter: _selectedFilter != 'all',
                )
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: groups.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        ...entry.value.map(
                          (breadcrumb) => BreadcrumbTile(
                            breadcrumb: breadcrumb,
                            onOpenDetails: () => _openDetails(breadcrumb),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  String _dateHeader(DateTime time) {
    return '${time.year.toString().padLeft(4, '0')}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final bool hasFilter;

  const _EmptyState({required this.hasSearch, required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    String title = 'No timeline events yet';
    String subtitle =
        'Start interacting with your app to capture logs, actions, routes, and network calls.';

    if (hasSearch) {
      title = 'No matching results';
      subtitle = 'Try a broader search term or clear the search.';
    } else if (hasFilter) {
      title = 'No events for this filter';
      subtitle = 'Switch to another filter or reproduce that event type.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline_rounded, color: Colors.white30, size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
