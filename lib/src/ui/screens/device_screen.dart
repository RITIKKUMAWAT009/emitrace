import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:emitrace/src/core/emitrace_controller.dart';
import 'package:share_plus/share_plus.dart';

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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    final info = <String, String>{
      'App Name': packageInfo.appName,
      'Version': packageInfo.version,
      'Build Number': packageInfo.buildNumber,
      'Package': packageInfo.packageName,
    };

    try {
      info.addAll({
        'Platform': Platform.operatingSystem,
        'OS Version': Platform.operatingSystemVersion,
        'Processors': Platform.numberOfProcessors.toString(),
        'Locale': Platform.localeName,
        'Hostname': Platform.localHostname,
      });
    } catch (_) {
      info['Platform'] = 'Web/Desktop';
    }

    if (mounted) {
      setState(() {
        _deviceInfo = info;
        _loading = false;
      });
    }
  }

  Future<void> _copyDebugBundle() async {
    final markdown = _controller.generateDebugBundleMarkdown(
      deviceInfo: _deviceInfo,
    );
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) return;
    _showMessage(
      'Debug bundle copied',
      background: const Color(0xFF00D4AA),
    );
  }

  Future<void> _copyGitHubIssue() async {
    final markdown = _controller.generateGitHubIssueMarkdown(
      deviceInfo: _deviceInfo,
    );
    await Clipboard.setData(ClipboardData(text: markdown));
    if (!mounted) return;
    _showMessage(
      'GitHub issue markdown copied',
      background: const Color(0xFF00D4AA),
    );
  }

  Widget _actionCard({
    required String title,
    required Color border,
    required Color text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: border.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border.withValues(alpha: 0.45)),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const _SectionHeader(title: '📦 App Info'),
        ..._deviceInfo.entries
            .where((e) => ['App Name', 'Version', 'Build Number', 'Package']
                .contains(e.key))
            .map((e) => _InfoRow(label: e.key, value: e.value)),
        const SizedBox(height: 14),
        const _SectionHeader(title: '📱 Device Info'),
        ..._deviceInfo.entries
            .where((e) => !['App Name', 'Version', 'Build Number', 'Package']
                .contains(e.key))
            .map((e) => _InfoRow(label: e.key, value: e.value)),
        const SizedBox(height: 14),
        const _SectionHeader(title: '🧰 Actions'),
        _actionCard(
          title: '📋 Copy All Device Info',
          border: const Color(0xFF6C63FF),
          text: const Color(0xFF8C85FF),
          onTap: () {
            final text = _deviceInfo.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n');
            Clipboard.setData(ClipboardData(text: text));
            _showMessage('Device info copied successfully');
          },
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Generate Report',
          border: const Color(0xFF00D4AA),
          text: const Color(0xFF00D4AA),
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
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Copy Debug Bundle',
          border: const Color(0xFF00D4AA),
          text: const Color(0xFF00D4AA),
          onTap: _copyDebugBundle,
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Copy GitHub Issue Markdown',
          border: const Color(0xFF6AA2FF),
          text: const Color(0xFF8EB7FF),
          onTap: _copyGitHubIssue,
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Open/Share Latest Report',
          border: const Color(0xFF2A2A52),
          text: Colors.white,
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
            } catch (_) {
              if (!mounted) return;
              _showMessage(
                'Report share failed',
                background: const Color(0xFFFF5555),
              );
            }
          },
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Send Report To Slack',
          border: const Color(0xFF4A154B),
          text: const Color(0xFFEBD4EC),
          onTap: () async {
            final result = await _controller.sendLatestReportToSlackDetailed();
            if (!mounted) return;
            final ok = result['ok'] == true;
            _showMessage(
              result['message']?.toString() ?? 'Slack send failed',
              background:
                  ok ? const Color(0xFF00D4AA) : const Color(0xFFFF5555),
            );
          },
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Send Report To Discord',
          border: const Color(0xFF5865F2),
          text: const Color(0xFFA5AEFF),
          onTap: () async {
            final result =
                await _controller.sendLatestReportToDiscordDetailed();
            if (!mounted) return;
            final ok = result['ok'] == true;
            _showMessage(
              result['message']?.toString() ?? 'Discord send failed',
              background:
                  ok ? const Color(0xFF00D4AA) : const Color(0xFFFF5555),
            );
          },
        ),
        const SizedBox(height: 10),
        _actionCard(
          title: 'Clear Logs & History',
          border: const Color(0xFFFF9F43),
          text: const Color(0xFFFFC56E),
          onTap: () {
            _controller.clear();
            _showMessage(
              'Logs and action history cleared',
              background: const Color(0xFFFF9F43),
            );
          },
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
          letterSpacing: 1.0,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Flexible(
            child: Text(
              value,
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
    );
  }
}
