import 'package:emitrace/src/models/breadcrumb.dart';
import 'package:emitrace/src/core/emitrace_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';

class EmitraceController {
  static final EmitraceController _instance = EmitraceController._internal();
  EmitraceController._internal();
  factory EmitraceController() => _instance;

  final int maxBreadCrumbs = 50;
  EmitraceConfig? _config;
  GlobalKey? _captureBoundaryKey;
  DateTime? _lastScreenshotAt;
  String? _latestReportPath;

  final List<Breadcrumb> _breadCrumbs = [];

  List<Breadcrumb> get breadCrumbs => List.unmodifiable(_breadCrumbs);
  String? get latestReportPath => _latestReportPath;

  void configure({
    required EmitraceConfig config,
    required GlobalKey captureBoundaryKey,
  }) {
    _config = config;
    _captureBoundaryKey = captureBoundaryKey;
  }

  /// Add bread crumb [CORE]
  void addBreadCrumb(Breadcrumb breadCrumb) {
    if (_breadCrumbs.length >= maxBreadCrumbs) {
      _breadCrumbs.removeAt(0);
    }
    _breadCrumbs.add(breadCrumb);
  }

  ///[HELPERS]
  void log(String message, {Map<String, dynamic> data = const {}}) {
    addBreadCrumb(
      Breadcrumb(
        type: "log",
        message: message,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  void navigation(String from, String to) {
    addBreadCrumb(
      Breadcrumb(
        type: "navigation",
        message: "$from -> $to",
        timestamp: DateTime.now(),
      ),
    );
  }

  void error(String message, {dynamic exception}) {
    addBreadCrumb(
      Breadcrumb(
        type: "error",
        message: message,
        timestamp: DateTime.now(),
        data: exception != null ? {"exception": exception} : {},
      ),
    );
  }

  void network({
    required String method,
    required String url,
    required int statusCode,
    required int responseTime,
    Map<String, dynamic> data = const {},
  }) {
    addBreadCrumb(Breadcrumb(
      type: 'network',
      message: '$method $url → $statusCode',
      timestamp: DateTime.now(),
      data: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        'responseTimeMs': responseTime,
        ...data,
      },
    ));
  }
  Future<String?> captureScreenshot({
    String reason = 'manual',
  }) async {
    final config = _config;
    final boundaryKey = _captureBoundaryKey;
    if (config == null || boundaryKey == null) return null;

    final now = DateTime.now();
    if (_lastScreenshotAt != null &&
        now.difference(_lastScreenshotAt!) <
            const Duration(milliseconds: 800)) {
      return null;
    }

    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;

    final ui.Image image = await renderObject.toImage(
      pixelRatio: config.screenshotPixelRatio.toDouble(),
    );
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/emitrace_${reason}_${now.millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    if (config.autoSaveScreenshotToGallery) {
      try {
        await ImageGallerySaver.saveFile(path);
      } catch (_) {}
    }
    _lastScreenshotAt = now;
    return path;
  }

  Future<void> captureErrorAndScreenshot({
    required String message,
    dynamic exception,
    StackTrace? stackTrace,
    String source = 'flutter',
  }) async {
    String? screenshotPath;
    final config = _config;
    if (config != null && config.enableAutoScreenshotOnError) {
      screenshotPath = await captureScreenshot(reason: 'error');
    }
    final screenshotExists = screenshotPath != null &&
        File(screenshotPath).existsSync();

    addBreadCrumb(
      Breadcrumb(
        type: 'error',
        message: message,
        timestamp: DateTime.now(),
        data: {
          'exception': exception?.toString(),
          'stackTrace': stackTrace?.toString(),
          'source': source,
          'screenshotPath': screenshotPath,
          'screenshotCaptured': screenshotPath != null,
          'screenshotFileExists': screenshotExists,
          'autoSaveToGalleryEnabled':
              config?.autoSaveScreenshotToGallery ?? false,
        },
      ),
    );
  }

  Future<String?> generateReport() async {
    final config = _config;
    if (config != null && !config.enableReportGenerator) {
      return null;
    }

    final now = DateTime.now();
    final dir = await getTemporaryDirectory();
    final reportPath =
        '${dir.path}/emitrace_report_${now.millisecondsSinceEpoch}.md';

    final summary = <String, int>{};
    for (final b in _breadCrumbs) {
      summary[b.type] = (summary[b.type] ?? 0) + 1;
    }

    final buffer = StringBuffer()
      ..writeln('# Emitrace Debug Report')
      ..writeln()
      ..writeln('## Overview')
      ..writeln('- **App**: ${config?.appName ?? "Unknown"}')
      ..writeln('- **Generated At**: ${now.toIso8601String()}')
      ..writeln('- **Total Events**: ${_breadCrumbs.length}')
      ..writeln();

    summary.forEach((key, value) {
      buffer.writeln('- **$key**: $value');
    });

    buffer
      ..writeln()
      ..writeln('## Timeline')
      ..writeln();

    for (int i = 0; i < _breadCrumbs.length; i++) {
      final b = _breadCrumbs[i];
      final screenshotPath =
          b.data['screenshotPath']?.toString();
      buffer.writeln(
        '### ${i + 1}. ${b.type.toUpperCase()}',
      );
      buffer.writeln('- **Time**: ${b.timestamp.toIso8601String()}');
      buffer.writeln('- **Message**: ${b.message}');
      if (screenshotPath != null && screenshotPath.isNotEmpty) {
        buffer.writeln('- **Screenshot**: `$screenshotPath`');
      }
      if (b.data.isNotEmpty) {
        buffer.writeln('- **Metadata**:');
        buffer.writeln('```json');
        buffer.writeln(const JsonEncoder.withIndent('  ').convert(b.data));
        buffer.writeln('```');
      }
      buffer.writeln();
    }

    final file = File(reportPath);
    await file.writeAsString(buffer.toString(), flush: true);
    _latestReportPath = reportPath;

    addBreadCrumb(
      Breadcrumb(
        type: 'report',
        message: 'Report generated (${_fileName(reportPath)})',
        timestamp: DateTime.now(),
        data: {
          'reportPath': reportPath,
          'reportFileName': _fileName(reportPath),
        },
      ),
    );
    return reportPath;
  }

  Future<bool> sendLatestReportToSlack() async {
    final config = _config;
    if (config == null || !config.enableSlackIntegration) {
      return false;
    }
    final webhook = config.slackWebHookUrl;
    if (webhook == null || webhook.isEmpty) return false;

    final reportPath = await generateReport();
    if (reportPath == null) return false;

    final summary = <String, int>{};
    for (final b in _breadCrumbs) {
      summary[b.type] = (summary[b.type] ?? 0) + 1;
    }
    final summaryText = summary.entries
        .map((e) => '${e.key}:${e.value}')
        .join(' | ');

    final response = await http.post(
      Uri.parse(webhook),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': 'Emitrace Report\n'
            'App: ${config.appName}\n'
            'Events: ${_breadCrumbs.length}\n'
            'Summary: $summaryText\n'
            'Local report path: $reportPath\n'
            'Recent errors:\n'
            '${_latestErrorSummary()}',
      }),
    );

    final ok = response.statusCode >= 200 &&
        response.statusCode < 300;
    addBreadCrumb(
      Breadcrumb(
        type: 'slack',
        message: ok ? 'Report sent to Slack' : 'Slack send failed',
        timestamp: DateTime.now(),
        data: {
          'statusCode': response.statusCode,
          'responseBody': response.body,
          'reportFileName': _fileName(reportPath),
          'reportPath': reportPath,
        },
      ),
    );
    return ok;
  }

  Future<Map<String, dynamic>> saveScreenshotToGallery(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      return {
        'ok': false,
        'message': 'Screenshot file not found at path',
      };
    }
    try {
      final result = await ImageGallerySaver.saveFile(path);
      if (result is Map) {
        final ok = result['isSuccess'] == true || result['success'] == true;
        return {
          'ok': ok,
          'message': ok
              ? 'Screenshot saved to gallery'
              : 'Failed to save screenshot to gallery',
          'raw': result,
        };
      }
      return {
        'ok': true,
        'message': 'Save request sent to gallery',
      };
    } catch (e) {
      return {
        'ok': false,
        'message': 'Save failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> sendLatestReportToSlackDetailed() async {
    final config = _config;
    if (config == null || !config.enableSlackIntegration) {
      return {
        'ok': false,
        'message': 'Slack integration disabled',
      };
    }
    final webhook = config.slackWebHookUrl;
    if (webhook == null || webhook.isEmpty) {
      return {
        'ok': false,
        'message': 'Slack webhook URL is missing',
      };
    }
    final ok = await sendLatestReportToSlack();
    if (ok) {
      return {
        'ok': true,
        'message': 'Report sent to Slack successfully',
      };
    }
    final last = _breadCrumbs.isNotEmpty ? _breadCrumbs.last : null;
    return {
      'ok': false,
      'message': 'Slack send failed',
      'details': last?.data,
    };
  }

  void clear() => _breadCrumbs.clear();

  String _latestErrorSummary() {
    final latestErrors = _breadCrumbs
        .where((b) => b.type == 'error')
        .toList()
        .reversed
        .take(3);
    if (latestErrors.isEmpty) return 'No recent errors';
    return latestErrors.map((e) {
      final path = e.data['screenshotPath']?.toString();
      final screenshotInfo = path != null && path.isNotEmpty
          ? ' screenshot=$path'
          : '';
      return '- ${e.message}$screenshotInfo';
    }).join('\n');
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

}
