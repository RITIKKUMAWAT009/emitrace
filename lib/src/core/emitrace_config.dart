import 'package:flutter/widgets.dart';

/// Runtime configuration for the Emitrace overlay and capture behavior.
class EmitraceConfig {
  /// Enables or disables Emitrace instrumentation.
  final bool enabled;

  /// Slack incoming webhook URL used when sending report summaries.
  final String? slackWebHookUrl;

  /// App display name shown in generated reports.
  final String appName;

  /// Shows or hides the floating `E` overlay launcher.
  final bool showOverlay;

  /// Maximum number of breadcrumb events kept in memory.
  final int maxBreadCrumbs;

  /// Navigator key used to open panel UI from root navigator context.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Captures screenshots automatically when uncaught errors occur.
  final bool enableAutoScreenshotOnError;

  /// Enables markdown report generation actions.
  final bool enableReportGenerator;

  /// Enables Slack send action in the device tab.
  final bool enableSlackIntegration;

  /// Pixel ratio used when rendering screenshots.
  final int screenshotPixelRatio;

  /// Calls host native method channel to save screenshots to gallery.
  final bool autoSaveScreenshotToGallery;

  /// Creates an [EmitraceConfig] instance.
  EmitraceConfig({
    this.enabled = true,
    this.appName = "My App",
    this.showOverlay = true,
    this.maxBreadCrumbs = 50,
    this.slackWebHookUrl,
    this.navigatorKey,
    this.enableAutoScreenshotOnError = true,
    this.enableReportGenerator = true,
    this.enableSlackIntegration = false,
    this.screenshotPixelRatio = 2,
    this.autoSaveScreenshotToGallery = false,
  });
}
