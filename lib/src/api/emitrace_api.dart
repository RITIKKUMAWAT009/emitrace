import 'package:emitrace/src/core/emitrace_controller.dart';

/// Beginner-friendly static API for recording logs, actions, and reports.
class Emitrace {
  static EmitraceController get _controller => EmitraceController();

  static void log(String message, {Map<String, dynamic>? data}) {
    _controller.log(message, data: data ?? const {});
  }

  static void event(String name, {Map<String, dynamic>? data}) {
    _controller.event(name, data: data ?? const {});
  }

  static void action(String name, {Map<String, dynamic>? data}) {
    _controller.action(name, data: data ?? const {});
  }

  static void breadcrumb(String message, {Map<String, dynamic>? data}) {
    _controller.breadcrumb(message, data: data ?? const {});
  }

  static Future<void> error(
    Object error,
    StackTrace? stackTrace, {
    Map<String, dynamic>? data,
  }) {
    return _controller.captureErrorAndScreenshot(
      message: error.toString(),
      exception: {
        'error': error.toString(),
        if (data != null) ...data,
      },
      stackTrace: stackTrace,
      source: 'manual',
    );
  }

  static Future<String?> captureReport() => _controller.generateReport();

  static Future<String?> captureScreenshot({String reason = 'manual'}) {
    return _controller.captureScreenshot(reason: reason);
  }
}
