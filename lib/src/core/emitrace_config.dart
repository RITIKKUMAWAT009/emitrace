import 'package:flutter/widgets.dart';

class EmitraceConfig {
  final bool enabled;
  final String? slackWebHookUrl;
  final String appName;
  final bool showOverlay;
  final int maxBreadCrumbs;
  final GlobalKey<NavigatorState>? navigatorKey;
  final bool enableAutoScreenshotOnError;
  final bool enableReportGenerator;
  final bool enableSlackIntegration;
  final int screenshotPixelRatio;
  final bool autoSaveScreenshotToGallery;

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
