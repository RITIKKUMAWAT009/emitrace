
/// Emitrace — Never reproduce a QA bug manually again
///
/// Quick start:
/// ```dart
/// void main() {
///   final navigatorKey = GlobalKey<NavigatorState>();
///
///   runApp(
///     EmitraceScope(
///       config: EmitraceConfig(
///         appName: 'My App',
///         navigatorKey: navigatorKey,
///         enableAutoScreenshotOnError: true,
///         enableReportGenerator: true,
///         enableSlackIntegration: true,
///         slackWebHookUrl: 'https://hooks.slack.com/services/xxx/yyy/zzz',
///       ),
///       child: MaterialApp(
///         navigatorKey: navigatorKey,
///         home: const MyHomePage(),
///       ),
///     ),
///   );
/// }
/// ```

library emitrace;

// Core
export 'src/core/emitrace_config.dart';
export 'src/core/emitrace_controller.dart';

// Overlay
export 'src/overlay/emitrace_scope.dart';

// Network
export 'src/modules/network/emitrace_dio_interceptor.dart';


export 'src/ui/emitrace_panel.dart';
