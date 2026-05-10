# Emitrace

Emitrace helps Flutter developers understand what happened before bugs occur.

One-tap in-app debugging for QA and developers: logs, network tracing, actions, route transitions, screenshots, and shareable reports.

## Features

- Floating `E` launcher overlay inside your app
- Filterable timeline: `all`, `network`, `error`, `navigation`, `action`, `event`, `log`
- Route tracking with previous route, current route, timestamp, and transition type
- Dio tracing with request/response/error capture (including 4xx/5xx paths)
- Manual APIs: `log`, `event`, `action`, `breadcrumb`, `error`
- Auto screenshot capture on framework/platform/manual errors
- Markdown report generation with navigation, actions, errors, network, and metadata
- Report preview/copy/share from panel
- Optional Slack webhook summary posting

## 2-Minute Quickstart

```yaml
dependencies:
  emitrace: ^1.1.0
```

```dart
import 'package:emitrace/emitrace.dart';
import 'package:flutter/material.dart';

final navKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    EmitraceScope(
      config: EmitraceConfig(
        appName: 'My App',
        navigatorKey: navKey,
      ),
      child: MaterialApp(
        navigatorKey: navKey,
        home: const HomePage(),
      ),
    ),
  );
}
```

Open the floating `E` button, reproduce the issue, inspect timeline/network/errors, then generate/share report.

## Route Tracking Setup

```dart
final routeObserver = EmitraceRouteObserver();

MaterialApp(
  navigatorObservers: [routeObserver],
)
```

Works with standard Navigator usage and does not force a specific routing package.

## Manual API Examples

```dart
Emitrace.log('User opened checkout', data: {'cartItems': 3});
Emitrace.event('checkout_started', data: {'flow': 'guest'});
Emitrace.action('tap_pay_now', data: {'buttonId': 'pay_now'});
Emitrace.breadcrumb('Reached payment screen');

try {
  // risky call
} catch (e, st) {
  await Emitrace.error(e, st, data: {'feature': 'payment'});
}

await Emitrace.captureScreenshot(reason: 'before_submit');
await Emitrace.captureReport();
```

## Dio Interceptor Setup

```dart
final dio = Dio();
dio.interceptors.add(EmitraceDioInterceptor());
```

## Report Generation Flow

1. Reproduce a bug.
2. Capture relevant `Emitrace.action`/`Emitrace.event` calls around user interactions.
3. Open Emitrace panel and inspect logs/network/errors.
4. Tap **Generate Report**.
5. Preview, copy, or share from device tab.

## Slack Webhook Setup

```dart
EmitraceConfig(
  enableSlackIntegration: true,
  slackWebHookUrl: 'https://hooks.slack.com/services/xxx/yyy/zzz',
)
```

Notes:
- Incoming webhook posts a summary text message.
- Local file paths in report are device-local references.

## Platform Notes

- `navigatorKey` is recommended for reliable panel presentation.
- iOS gallery save requires photo library usage descriptions when host app implements save.
- Android gallery save requires proper media/storage permissions in host app.
- Host-app gallery save contract uses `MethodChannel('emitrace/gallery')` with `saveToGallery`.

## Roadmap

See [ROADMAP.md](ROADMAP.md).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT License. See [LICENSE](LICENSE).
