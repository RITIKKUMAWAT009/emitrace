import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:emitrace/src/core/emitrace_config.dart';
import 'package:emitrace/src/models/breadcrumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Central singleton that stores events and powers reports/screenshots.
class EmitraceController {
  static final EmitraceController _instance = EmitraceController._internal();
  EmitraceController._internal();
  factory EmitraceController() => _instance;

  EmitraceConfig? _config;
  GlobalKey? _captureBoundaryKey;
  DateTime? _lastScreenshotAt;
  String? _latestReportPath;
  String? _currentRoute;

  final List<Breadcrumb> _breadCrumbs = [];
  static const MethodChannel _galleryChannel =
      MethodChannel('emitrace/gallery');

  /// Read-only list of recorded breadcrumbs.
  List<Breadcrumb> get breadCrumbs => List.unmodifiable(_breadCrumbs);

  /// Absolute path of the most recently generated report, if available.
  String? get latestReportPath => _latestReportPath;

  /// Latest route observed by [EmitraceRouteObserver] if configured.
  String? get currentRoute => _currentRoute;

  void configure({
    required EmitraceConfig config,
    required GlobalKey captureBoundaryKey,
  }) {
    _config = config;
    _captureBoundaryKey = captureBoundaryKey;
  }

  int get _maxBreadCrumbs => _config?.maxBreadCrumbs ?? 50;

  /// Add breadcrumb to rolling buffer.
  void addBreadCrumb(Breadcrumb breadCrumb) {
    if (_breadCrumbs.length >= _maxBreadCrumbs) {
      _breadCrumbs.removeAt(0);
    }
    _breadCrumbs.add(breadCrumb);
  }

  void breadcrumb(String message, {Map<String, dynamic> data = const {}}) {
    log(message, data: data);
  }

  void log(String message, {Map<String, dynamic> data = const {}}) {
    addBreadCrumb(
      Breadcrumb(
        type: 'log',
        message: message,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  void event(String name, {Map<String, dynamic> data = const {}}) {
    addBreadCrumb(
      Breadcrumb(
        type: 'event',
        message: name,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  void action(String name, {Map<String, dynamic> data = const {}}) {
    addBreadCrumb(
      Breadcrumb(
        type: 'action',
        message: name,
        timestamp: DateTime.now(),
        data: data,
      ),
    );
  }

  void navigation(
    String from,
    String to, {
    String transition = 'unknown',
  }) {
    _currentRoute = to;
    addBreadCrumb(
      Breadcrumb(
        type: 'navigation',
        message: '$from -> $to',
        timestamp: DateTime.now(),
        data: {
          'previousRoute': from,
          'currentRoute': to,
          'transition': transition,
        },
      ),
    );
  }

  void error(String message, {dynamic exception, StackTrace? stackTrace}) {
    addBreadCrumb(
      Breadcrumb(
        type: 'error',
        message: message,
        timestamp: DateTime.now(),
        data: {
          if (exception != null) 'exception': exception.toString(),
          if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        },
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
    addBreadCrumb(
      Breadcrumb(
        type: 'network',
        message: '$method $url -> $statusCode',
        timestamp: DateTime.now(),
        data: {
          'method': method,
          'url': url,
          'statusCode': statusCode,
          'responseTimeMs': responseTime,
          ...data,
        },
      ),
    );
  }

  Future<String?> captureScreenshot({String reason = 'manual'}) async {
    final config = _config;
    final boundaryKey = _captureBoundaryKey;
    if (config == null || boundaryKey == null) return null;

    final now = DateTime.now();
    if (_lastScreenshotAt != null &&
        now.difference(_lastScreenshotAt!) <
            const Duration(milliseconds: 800)) {
      return null;
    }

    try {
      await SchedulerBinding.instance.endOfFrame;
      final context = boundaryKey.currentContext;
      if (context == null || !context.mounted) return null;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;

      final ui.Image image = await renderObject.toImage(
        pixelRatio: config.screenshotPixelRatio.toDouble(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${dir.path}/emitrace_screenshots');
      if (!screenshotsDir.existsSync()) {
        screenshotsDir.createSync(recursive: true);
      }
      final path =
          '${screenshotsDir.path}/emitrace_${reason}_${now.millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (config.autoSaveScreenshotToGallery) {
        try {
          await _galleryChannel
              .invokeMethod<bool>('saveToGallery', {'path': path});
        } catch (_) {}
      }

      _lastScreenshotAt = now;
      return path;
    } catch (_) {
      return null;
    }
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
    final screenshotExists =
        screenshotPath != null && File(screenshotPath).existsSync();

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

  Map<String, dynamic> reportToJson() {
    final now = DateTime.now();
    final summary = <String, int>{};
    for (final b in _breadCrumbs) {
      summary[b.type] = (summary[b.type] ?? 0) + 1;
    }

    final navigationEvents =
        _breadCrumbs.where((b) => b.type == 'navigation').toList();
    final actions = _breadCrumbs.where((b) => b.type == 'action').toList();
    final errors = _breadCrumbs.where((b) => b.type == 'error').toList();
    final networkLogs = _breadCrumbs.where((b) => b.type == 'network').toList();

    return {
      'appName': _config?.appName ?? 'Unknown',
      'generatedAt': now.toIso8601String(),
      'currentRoute': _currentRoute,
      'totalEvents': _breadCrumbs.length,
      'summary': summary,
      'recentNavigationEvents':
          navigationEvents.take(15).map((e) => e.toJson()).toList(),
      'recentActions': actions.take(25).map((e) => e.toJson()).toList(),
      'errors': errors.map((e) => e.toJson()).toList(),
      'networkLogs': networkLogs.map((e) => e.toJson()).toList(),
      'timeline': _breadCrumbs.map((e) => e.toJson()).toList(),
    };
  }

  Future<String?> generateReport() async {
    final config = _config;
    if (config != null && !config.enableReportGenerator) {
      return null;
    }

    final now = DateTime.now();
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/emitrace_reports');
    if (!reportsDir.existsSync()) {
      reportsDir.createSync(recursive: true);
    }
    final reportPath =
        '${reportsDir.path}/emitrace_report_${now.millisecondsSinceEpoch}.md';

    final data = reportToJson();
    final summary = Map<String, dynamic>.from(data['summary'] as Map);
    final navEvents =
        List<Map<String, dynamic>>.from(data['recentNavigationEvents'] as List);
    final errors = List<Map<String, dynamic>>.from(data['errors'] as List);
    final networkLogs =
        List<Map<String, dynamic>>.from(data['networkLogs'] as List);

    final buffer = StringBuffer()
      ..writeln('# Emitrace Debug Report')
      ..writeln()
      ..writeln('## Overview')
      ..writeln('- **App**: ${data['appName']}')
      ..writeln('- **Generated At**: ${data['generatedAt']}')
      ..writeln('- **Current Route**: ${data['currentRoute'] ?? 'unknown'}')
      ..writeln('- **Total Events**: ${data['totalEvents']}')
      ..writeln()
      ..writeln('## Event Summary');

    summary.forEach((key, value) {
      buffer.writeln('- **$key**: $value');
    });

    buffer
      ..writeln()
      ..writeln('## Recent Navigation')
      ..writeln();

    if (navEvents.isEmpty) {
      buffer.writeln('- No navigation events recorded.');
    } else {
      for (final event in navEvents.reversed.take(10)) {
        final eventData =
            Map<String, dynamic>.from(event['data'] as Map? ?? {});
        buffer.writeln(
          '- ${event['timeStamp']}: ${eventData['previousRoute'] ?? 'unknown'} -> '
          '${eventData['currentRoute'] ?? 'unknown'} '
          '(${eventData['transition'] ?? 'unknown'})',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## Recent Actions & Breadcrumbs')
      ..writeln();

    final recentBehavior = _breadCrumbs
        .where(
            (b) => b.type == 'action' || b.type == 'event' || b.type == 'log')
        .toList()
        .reversed
        .take(20)
        .toList();

    if (recentBehavior.isEmpty) {
      buffer.writeln('- No actions/events recorded.');
    } else {
      for (final item in recentBehavior.reversed) {
        buffer.writeln(
            '- ${item.timestamp.toIso8601String()} [${item.type}] ${item.message}');
      }
    }

    buffer
      ..writeln()
      ..writeln('## Errors')
      ..writeln();

    if (errors.isEmpty) {
      buffer.writeln('- No errors recorded.');
    } else {
      for (final errorItem in errors.reversed.take(20)) {
        final errorData =
            Map<String, dynamic>.from(errorItem['data'] as Map? ?? {});
        buffer
            .writeln('- **${errorItem['timeStamp']}** ${errorItem['message']}');
        if ((errorData['screenshotPath']?.toString().isNotEmpty ?? false)) {
          buffer.writeln('  - screenshot: `${errorData['screenshotPath']}`');
        }
      }
    }

    buffer
      ..writeln()
      ..writeln('## Network Logs')
      ..writeln();

    if (networkLogs.isEmpty) {
      buffer.writeln('- No network logs recorded.');
    } else {
      for (final networkItem in networkLogs.reversed.take(30)) {
        final networkData =
            Map<String, dynamic>.from(networkItem['data'] as Map? ?? {});
        buffer.writeln(
          '- **${networkItem['timeStamp']}** ${networkData['method'] ?? ''} '
          '${networkData['url'] ?? ''} -> ${networkData['statusCode'] ?? ''} '
          '(${networkData['responseTimeMs'] ?? 0}ms)',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## Full Timeline')
      ..writeln();

    for (int i = 0; i < _breadCrumbs.length; i++) {
      final b = _breadCrumbs[i];
      final screenshotPath = b.data['screenshotPath']?.toString();
      buffer.writeln('### ${i + 1}. ${b.type.toUpperCase()}');
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
          'report': data,
        },
      ),
    );
    return reportPath;
  }

  Future<String?> loadLatestReportContent() async {
    final path = _latestReportPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsString();
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
    final summaryText =
        summary.entries.map((e) => '${e.key}:${e.value}').join(' | ');

    final payload = jsonEncode({
      'text': 'Emitrace Report\n'
          'App: ${config.appName}\n'
          'Events: ${_breadCrumbs.length}\n'
          'Current route: ${_currentRoute ?? 'unknown'}\n'
          'Summary: $summaryText\n'
          'Local report path: $reportPath\n'
          'Recent errors:\n'
          '${_latestErrorSummary()}',
    });

    final response = await _postJsonWithRedirects(Uri.parse(webhook), payload);

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    addBreadCrumb(
      Breadcrumb(
        type: 'slack',
        message: ok ? 'Report sent to Slack' : 'Slack send failed',
        timestamp: DateTime.now(),
        data: {
          'statusCode': response.statusCode,
          'responseBody': response.body,
          'location': response.location,
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
      final result = await _galleryChannel
          .invokeMethod<bool>('saveToGallery', {'path': path});
      final ok = result == true;
      if (ok) {
        return {
          'ok': true,
          'message': 'Screenshot saved to gallery',
          'raw': {'nativeResult': true},
        };
      }
      return {
        'ok': false,
        'message':
            'Failed to save screenshot to gallery. ${_galleryPermissionHint()}',
        'raw': {'nativeResult': result},
      };
    } on MissingPluginException {
      return {
        'ok': false,
        'message':
            'Native gallery saver is not implemented in host app. ${_galleryPermissionHint()}',
      };
    } catch (e) {
      return {
        'ok': false,
        'message': 'Save failed: $e. ${_galleryPermissionHint()}',
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
    final latestErrors =
        _breadCrumbs.where((b) => b.type == 'error').toList().reversed.take(3);
    if (latestErrors.isEmpty) return 'No recent errors';
    return latestErrors.map((e) {
      final path = e.data['screenshotPath']?.toString();
      final screenshotInfo =
          path != null && path.isNotEmpty ? ' screenshot=$path' : '';
      return '- ${e.message}$screenshotInfo';
    }).join('\n');
  }

  String _fileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  String _galleryPermissionHint() {
    if (Platform.isIOS) {
      return 'Add NSPhotoLibraryUsageDescription and NSPhotoLibraryAddUsageDescription in Info.plist.';
    }
    if (Platform.isAndroid) {
      return 'Ensure gallery/media permissions are declared in AndroidManifest and granted on device.';
    }
    return 'Check platform storage/photo permissions.';
  }

  Future<_HttpPostResult> _postJsonWithRedirects(
    Uri uri,
    String payload, {
    int maxRedirects = 5,
  }) async {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    final status = response.statusCode;
    final isRedirect =
        status == 301 || status == 302 || status == 307 || status == 308;
    if (!isRedirect || maxRedirects <= 0) {
      return _HttpPostResult(
        statusCode: response.statusCode,
        body: response.body,
        location: response.headers['location'],
      );
    }

    final locationHeader = response.headers['location'];
    if (locationHeader == null || locationHeader.isEmpty) {
      return _HttpPostResult(
        statusCode: response.statusCode,
        body: response.body,
        location: null,
      );
    }

    final nextUri = uri.resolve(locationHeader);
    return _postJsonWithRedirects(
      nextUri,
      payload,
      maxRedirects: maxRedirects - 1,
    );
  }
}

class _HttpPostResult {
  final int statusCode;
  final String body;
  final String? location;

  const _HttpPostResult({
    required this.statusCode,
    required this.body,
    required this.location,
  });
}
