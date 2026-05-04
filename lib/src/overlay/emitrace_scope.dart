import 'package:emitrace/src/core/emitrace_config.dart';
import 'package:emitrace/src/core/emitrace_controller.dart';
import 'package:emitrace/src/ui/emitrace_panel.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EmitraceScope extends StatefulWidget {
  final Widget child;
  final EmitraceConfig config;
  const EmitraceScope({super.key, required this.child, required this.config});

  @override
  State<EmitraceScope> createState() => _EmitraceScopeState();
}

class _EmitraceScopeState extends State<EmitraceScope> {
  final EmitraceController _controller = EmitraceController();
  final GlobalKey _captureBoundaryKey = GlobalKey();
  FlutterExceptionHandler? _previousFlutterErrorHandler;
  ui.ErrorCallback? _previousPlatformErrorHandler;

  @override
  void initState() {
    if (!kDebugMode && !widget.config.enabled) return;

    _controller.log("Emitrace initialized ✅");
    _controller.configure(
      config: widget.config,
      captureBoundaryKey: _captureBoundaryKey,
    );
    _installErrorHandlers();

    super.initState();
  }

  @override
  void dispose() {
    if (_previousFlutterErrorHandler != null) {
      FlutterError.onError = _previousFlutterErrorHandler;
    }
    if (_previousPlatformErrorHandler != null) {
      ui.PlatformDispatcher.instance.onError =
          _previousPlatformErrorHandler;
    }
    super.dispose();
  }

  void _installErrorHandlers() {
    if (!widget.config.enableAutoScreenshotOnError) return;
    _previousFlutterErrorHandler = FlutterError.onError;
    _previousPlatformErrorHandler =
        ui.PlatformDispatcher.instance.onError;

    FlutterError.onError = (FlutterErrorDetails details) async {
      await _controller.captureErrorAndScreenshot(
        message: details.exceptionAsString(),
        exception: details.exception,
        stackTrace: details.stack,
        source: 'flutter',
      );
      _previousFlutterErrorHandler?.call(details);
    };

    ui.PlatformDispatcher.instance.onError =
        (Object error, StackTrace stack) {
      _controller.captureErrorAndScreenshot(
        message: error.toString(),
        exception: error,
        stackTrace: stack,
        source: 'platform',
      );
      if (_previousPlatformErrorHandler != null) {
        return _previousPlatformErrorHandler!(
          error,
          stack,
        );
      }
      return false;
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode && !widget.config.enabled) {
      return widget.child;
    }
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(
          key: _captureBoundaryKey,
          child: widget.child,
        ),

        if (widget.config.showOverlay)
          _EmitraceButton(config: widget.config),
      ],
    );
  }
}

// Floating draggable button

class _EmitraceButton extends StatefulWidget {
  final EmitraceConfig config;
  const _EmitraceButton({required this.config});

  @override
  State<_EmitraceButton> createState() => _EmitraceButtonState();
}

class _EmitraceButtonState extends State<_EmitraceButton> {
  // Button ki position screen pe
  double _bottom = 100;
  double _right = 16;
  bool _showContextError = false;
  bool _isSheetOpen = false;

  BuildContext? get _hostContext {
    final navigatorContext =
        widget.config.navigatorKey?.currentContext;
    if (navigatorContext != null) return navigatorContext;
    return Navigator.maybeOf(context, rootNavigator: true)
        ?.context;
  }

  Future<void> _openPanel() async {
    if (_isSheetOpen) return;

    final hostContext = _hostContext;
    if (hostContext == null) {
      setState(() {
        _showContextError = true;
      });
      return;
    }

    setState(() {
      _showContextError = false;
      _isSheetOpen = true;
    });

    try {
      await showModalBottomSheet<void>(
        context: hostContext,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const EmitracePanel(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          if (!_isSheetOpen)
            Positioned(
              bottom: _bottom,
              right: _right,
              child: SafeArea(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _bottom -= details.delta.dy;
                      _right -= details.delta.dx;
                    });
                  },
                  onTap: () {
                    debugPrint('Emitrace button tapped');
                    _openPanel();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'E',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showContextError)
            Positioned(
              left: 16,
              right: 16,
              bottom: _bottom + 64,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF5555),
                      ),
                    ),
                    child: const Text(
                      'Emitrace: provide EmitraceConfig.navigatorKey linked to your MaterialApp.navigatorKey.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
