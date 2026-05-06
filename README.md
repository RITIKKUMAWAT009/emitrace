# Emitrace

One-tap Flutter debugging for QA and developers.  
Capture logs, network calls, runtime errors, screenshots, and export clean reports from inside your app.

## Why Emitrace
- Fast in-app debugging without leaving the device.
- Better bug reports with event timeline + metadata.
- Team-ready summaries via Slack webhook.

## Features
- Floating `E` launcher overlay.
- Logs with filters: `all`, `network`, `error`, `navigation`, `log`.
- Tap any log to inspect full metadata/body.
- Dio network tracing using `EmitraceDioInterceptor`.
- Auto screenshot capture on framework/platform errors.
- Optional guidance for saving screenshots to gallery via host-app specific integration.
- Markdown report generation.
- Share/export report from device.
- Send report summary to Slack webhook.

## Installation
```yaml
dependencies:
  emitrace: ^1.0.1
```

## Quick Start
```dart
import 'package:emitrace/emitrace.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    EmitraceScope(
      config: EmitraceConfig(
        appName: 'My App',
        navigatorKey: appNavigatorKey,
        showOverlay: true,
        enableAutoScreenshotOnError: true,
        enableReportGenerator: true,
        enableSlackIntegration: false,
      ),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        home: const HomePage(),
      ),
    ),
  );
}
```

## Network Tracking (Dio)
```dart
final dio = Dio();
dio.interceptors.add(EmitraceDioInterceptor());
```

## Configuration
| Option | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | `true` | Enable/disable Emitrace. |
| `appName` | `String` | `"My App"` | App label in reports/messages. |
| `showOverlay` | `bool` | `true` | Show floating `E` launcher. |
| `navigatorKey` | `GlobalKey<NavigatorState>?` | `null` | Required for reliable panel presentation. |
| `maxBreadCrumbs` | `int` | `50` | Max stored events (rolling buffer). |
| `slackWebHookUrl` | `String?` | `null` | Incoming webhook URL for Slack summary posting. |
| `enableAutoScreenshotOnError` | `bool` | `true` | Capture screenshot on runtime errors. |
| `enableReportGenerator` | `bool` | `true` | Enable report generation. |
| `enableSlackIntegration` | `bool` | `false` | Enable Slack send action. |
| `screenshotPixelRatio` | `int` | `2` | Screenshot resolution scale. |
| `autoSaveScreenshotToGallery` | `bool` | `false` | Reserved for host app integrations that handle gallery save. |

## Platform Notes
- iOS: add photo library usage keys if your host app implements gallery save.
- Slack webhook can post summary text; local file paths are not shareable outside device.
- Slack file upload via bot token/API is planned for a future version.
- Some iOS/macOS dependencies currently resolve through CocoaPods because upstream plugins may not fully support Swift Package Manager yet.
- If screenshot save fails, add:
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`
  in your app `Info.plist`.
- On Android, ensure media/gallery permissions are present in `AndroidManifest.xml` if gallery save is implemented by host app.

### Native Gallery Save Contract (No External Package)
- Emitrace uses `MethodChannel('emitrace/gallery')`.
- Implement method `saveToGallery` on host app native side (Android/iOS).
- Arguments:
  - `path` (`String`): absolute screenshot file path
- Return:
  - `true` on success
  - `false` on failure

## Dependency Updates
- This repository includes Dependabot config at `.github/dependabot.yml` for weekly dependency update PRs.
- Keep version constraints explicit (do not leave them blank) and review PRs before merging.

## QA Flow
1. Reproduce issue.
2. Open `E` panel.
3. Inspect logs/network/errors.
4. Tap error log for metadata + screenshot.
5. Generate report and share/copy it using host app flow.
6. Send summary to Slack.

## Roadmap
- Slack file upload (actual report attachment).
- Hosted report URLs.
- Rich HTML report export.

## License
MIT License. See [LICENSE](LICENSE).
