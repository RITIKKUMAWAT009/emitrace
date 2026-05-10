import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:emitrace/src/core/emitrace_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Map<String, String> _deviceInfo = {};
  bool _loading = true;
  final EmitraceController _controller = EmitraceController();

  void _showMessage(
    String text, {
    Color background = const Color(0xFF6C63FF),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 20,
        right: 20,
        bottom: 28,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Future<void> _openLatestReportViewer() async {
    final path =
        _controller.latestReportPath ?? await _controller.generateReport();
    if (!mounted) return;
    if (path == null) {
      _showMessage(
        'Report generation is disabled',
        background: const Color(0xFFFF5555),
      );
      return;
    }
    final content = await _controller.loadLatestReportContent();
    if (!mounted) return;
    if (content == null || content.isEmpty) {
      _showMessage(
        'Could not load report file',
        background: const Color(0xFFFF5555),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0F),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Latest Report',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy Report',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: content));
                        if (!mounted) return;
                        _showMessage(
                          'Report content copied',
                          background: const Color(0xFF00D4AA),
                        );
                      },
                      icon: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  path,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
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
                        content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Rect _sharePositionOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  Future<void> _loadInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    Map<String, String> info = {
      'App Name': packageInfo.appName,
      'Version': packageInfo.version,
      'Build Number': packageInfo.buildNumber,
      'Package': packageInfo.packageName,
    };

    try {
      if (Platform.isAndroid) {
        info.addAll({
          'Platform': 'Android',
          'OS Version': Platform.operatingSystemVersion,
          'Processors': Platform.numberOfProcessors.toString(),
          'Locale': Platform.localeName,
          'Hostname': Platform.localHostname,
        });
      } else if (Platform.isIOS) {
        info.addAll({
          'Platform': 'iOS',
          'OS Version': Platform.operatingSystemVersion,
          'Processors': Platform.numberOfProcessors.toString(),
          'Locale': Platform.localeName,
          'Hostname': Platform.localHostname,
        });
      } else {
        info.addAll({
          'Platform': Platform.operatingSystem,
          'OS Version': Platform.operatingSystemVersion,
          'Processors': Platform.numberOfProcessors.toString(),
          'Locale': Platform.localeName,
          'Hostname': Platform.localHostname,
        });
      }
    } catch (e) {
      info['Platform'] = 'Web/Desktop';
    }

    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // App info section
        _SectionHeader(title: '📦 App Info'),
        ..._deviceInfo.entries
            .where((e) => ['App Name', 'Version', 'Build Number', 'Package']
                .contains(e.key))
            .map((e) => _InfoRow(
                  label: e.key,
                  value: e.value,
                )),

        const SizedBox(height: 16),

        // Device info section
        _SectionHeader(title: '📱 Device Info'),
        ..._deviceInfo.entries
            .where((e) => !['App Name', 'Version', 'Build Number', 'Package']
                .contains(e.key))
            .map((e) => _InfoRow(
                  label: e.key,
                  value: e.value,
                )),

        const SizedBox(height: 16),

        // Copy all button
        GestureDetector(
          onTap: () {
            final text = _deviceInfo.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n');
            Clipboard.setData(ClipboardData(text: text));
            _showMessage('Device info copied successfully');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              ),
            ),
            child: const Center(
              child: Text(
                '📋 Copy All Device Info',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final reportPath = await _controller.generateReport();
            if (!mounted) return;
            _showMessage(
              reportPath == null
                  ? 'Report generation is disabled'
                  : 'Report exported successfully',
              background: reportPath == null
                  ? const Color(0xFFFF5555)
                  : const Color(0xFF00D4AA),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
              ),
            ),
            child: const Center(
              child: Text(
                'Generate Report',
                style: TextStyle(
                  color: Color(0xFF00D4AA),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _controller.clear();
            _showMessage(
              'Logs and action history cleared',
              background: const Color(0xFFFF9F43),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F43).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFF9F43).withValues(alpha: 0.4),
              ),
            ),
            child: const Center(
              child: Text(
                'Clear Logs & History',
                style: TextStyle(
                  color: Color(0xFFFFC56E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _openLatestReportViewer,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2740),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Center(
              child: Text(
                'View Latest Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final path = _controller.latestReportPath ??
                await _controller.generateReport();
            if (!mounted) return;
            if (path == null) {
              _showMessage(
                'No report available to share',
                background: const Color(0xFFFF5555),
              );
              return;
            }
            try {
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(path)],
                  text: 'Emitrace report file',
                  sharePositionOrigin: _sharePositionOrigin(),
                ),
              );
              if (!mounted) return;
              _showMessage(
                'Report share sheet opened',
                background: const Color(0xFF00D4AA),
              );
            } catch (e) {
              if (!mounted) return;
              _showMessage(
                'Report share failed',
                background: const Color(0xFFFF5555),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A52),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Center(
              child: Text(
                'Open/Share Latest Report',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final result = await _controller.sendLatestReportToSlackDetailed();
            if (!mounted) return;
            final ok = result['ok'] == true;
            final message = result['message']?.toString() ??
                (ok ? 'Slack success' : 'Slack failed');
            _showMessage(
              message,
              background:
                  ok ? const Color(0xFF00D4AA) : const Color(0xFFFF5555),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF4A154B).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF4A154B).withValues(alpha: 0.5),
              ),
            ),
            child: const Center(
              child: Text(
                'Send Report To Slack',
                style: TextStyle(
                  color: Color(0xFFEBD4EC),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
