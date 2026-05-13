# Emitrace

Emitrace helps Flutter developers understand what happened before bugs occur.

One-tap in-app debugging for QA and developers: logs, timeline search, network tracing, actions/events, route transitions, screenshots, and shareable reports.

No backend is required.

## Features

- Floating `E` launcher overlay inside your app
- Familiar in-app panel tabs: `Logs`, `Network`, `Device`
- Timeline UI with grouped cards, type badges, timestamps, and expandable details
- Search + filters: `all`, `log`, `event`, `action`, `navigation`, `network`, `error`
- Route tracking with previous route, current route, timestamp, and transition type
- Dio tracing with request/response/error capture (including 4xx/5xx paths)
- Manual APIs: `log`, `event`, `action`, `breadcrumb`, `error`
- Auto screenshot capture on framework/platform/manual errors
- Crash context summary (latest route, previous route, last 3 actions/events, last failed network, screenshot path)
- Markdown report generation with timeline, crash summary, errors, network, screenshots, and metadata
- Copy Debug Bundle markdown for teammate handoff
- GitHub issue markdown generation via `EmitraceController.generateGitHubIssueMarkdown()`
- Report preview/copy/share from panel
- Optional Slack webhook summary posting
- Optional Discord webhook summary posting

## 2-Minute Quickstart

```yaml
dependencies:
  emitrace: ^1.2.0
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

Open the floating `E` button, inspect logs/network/device context, then generate/copy/share report artifacts.

## Route Tracking Setup

```dart
final routeObserver = EmitraceRouteObserver();

MaterialApp(
  navigatorObservers: [routeObserver],
)
```

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

## Timeline Search and Filters

- Use the Logs tab search box to match message/route/url/method/metadata text.
- Use filters to narrow timeline by type.
- Tap cards to expand details inline or open full detail view.

## Copy Debug Bundle

Use Device tab actions -> `Copy Debug Bundle` to copy a markdown bundle containing:

- app + timestamp overview
- route timeline
- recent actions/events
- recent errors
- network failures
- screenshot references
- device/app metadata

## GitHub Issue Export

```dart
final markdown = EmitraceController().generateGitHubIssueMarkdown();
```

Or Device tab actions -> `Copy GitHub Issue Markdown`.

## Dio Interceptor Setup

```dart
final dio = Dio();
dio.interceptors.add(EmitraceDioInterceptor());
```

## Slack and Discord Webhooks

```dart
EmitraceConfig(
  enableSlackIntegration: true,
  slackWebHookUrl: 'https://hooks.slack.com/services/xxx/yyy/zzz',
  enableDiscordIntegration: true,
  discordWebhookUrl: 'https://discord.com/api/webhooks/xxx/yyy',
)
```

Notes:
- Slack and Discord sends are optional and independent.
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
