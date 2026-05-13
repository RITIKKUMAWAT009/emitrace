import 'package:emitrace/emitrace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    EmitraceController().clear();
  });

  test('Emitrace static API is callable', () async {
    Emitrace.log('hello');
    Emitrace.event('event');
    Emitrace.action('action');
    Emitrace.breadcrumb('crumb');

    final reportData = EmitraceController().reportToJson();
    expect(reportData['totalEvents'], greaterThan(0));
  });

  test('reportToJson includes additive crashContextSummary', () {
    final controller = EmitraceController();
    controller.navigation('/login', '/home', transition: 'push');
    controller.action('tap_login', data: {'button': 'login'});
    controller.event('login_success');
    controller.network(
      method: 'GET',
      url: 'https://api.example.com/profile',
      statusCode: 500,
      responseTime: 300,
      data: const {'isError': true},
    );
    controller.error('Unhandled exception', exception: 'boom');

    final json = controller.reportToJson();
    expect(json.containsKey('crashContextSummary'), isTrue);

    final summary =
        Map<String, dynamic>.from(json['crashContextSummary'] as Map);
    expect(summary['latestRoute'], '/home');
    expect(summary['previousRoute'], '/login');
    expect(summary['lastFailedNetworkRequest'], isNotNull);
    expect(
      List<Map<String, dynamic>>.from(
        summary['lastThreeActionsOrEvents'] as List,
      ).isNotEmpty,
      isTrue,
    );
  });

  test('generateGitHubIssueMarkdown includes expected sections', () {
    final controller = EmitraceController();
    controller.navigation('/home', '/details', transition: 'push');
    controller.action('tap_open_details');
    controller.error('Broken state');

    final markdown = controller.generateGitHubIssueMarkdown(
      deviceInfo: const {'Platform': 'Android', 'Version': '1.0.0'},
    );

    expect(markdown.contains('## Summary'), isTrue);
    expect(markdown.contains('## Steps / Timeline'), isTrue);
    expect(markdown.contains('## Current Route'), isTrue);
    expect(markdown.contains('## Errors'), isTrue);
    expect(markdown.contains('## Network Calls'), isTrue);
    expect(markdown.contains('## Device Info'), isTrue);
    expect(markdown.contains('## Screenshots'), isTrue);
  });

  test('generateDebugBundleMarkdown includes crash summary section', () {
    final controller = EmitraceController();
    controller.navigation('/a', '/b', transition: 'push');
    controller.event('did_something');
    controller.error('Oops');

    final markdown = controller.generateDebugBundleMarkdown(
      deviceInfo: const {'Platform': 'iOS'},
    );

    expect(markdown.contains('## Crash Context Summary'), isTrue);
    expect(markdown.contains('## Route Timeline'), isTrue);
    expect(markdown.contains('## Recent Errors'), isTrue);
  });

  test(
      'queryTimeline supports type filter and search by message/url/method/meta',
      () {
    final controller = EmitraceController();
    controller.log('Opened checkout', data: const {'flow': 'guest'});
    controller.network(
      method: 'POST',
      url: 'https://api.example.com/checkout',
      statusCode: 201,
      responseTime: 120,
      data: const {'requestId': 'abc-123'},
    );

    final byType = controller.queryTimeline(filter: 'network');
    expect(byType.length, 1);

    final byMessage = controller.queryTimeline(searchQuery: 'checkout');
    expect(byMessage.length, 2);

    final byMethod = controller.queryTimeline(searchQuery: 'post');
    expect(byMethod.length, 1);

    final byUrl = controller.queryTimeline(searchQuery: 'api.example.com');
    expect(byUrl.length, 1);

    final byMeta = controller.queryTimeline(searchQuery: 'abc-123');
    expect(byMeta.length, 1);
  });

  test('crash context summary handles missing data gracefully', () {
    final controller = EmitraceController();
    final summary = controller.buildCrashContextSummary();

    expect(summary['hasErrors'], isFalse);
    expect(summary['latestRoute'], isNull);
    expect(summary['lastFailedNetworkRequest'], isNull);
    expect(
      List<Map<String, dynamic>>.from(
        summary['lastThreeActionsOrEvents'] as List,
      ).isEmpty,
      isTrue,
    );
  });

  test('buildSessionOverview returns expected counters and duration', () {
    final controller = EmitraceController();
    controller.navigation('/start', '/home', transition: 'push');
    controller.action('tap_refresh');
    controller.network(
      method: 'GET',
      url: 'https://api.example.com/ok',
      statusCode: 200,
      responseTime: 50,
    );
    controller.network(
      method: 'GET',
      url: 'https://api.example.com/fail',
      statusCode: 500,
      responseTime: 70,
      data: const {'isError': true},
    );
    controller.error('Something failed');

    final overview = controller.buildSessionOverview();
    expect(overview['currentRoute'], '/home');
    expect(overview['totalEvents'], 5);
    expect(overview['errorCount'], 1);
    expect(overview['networkFailureCount'], 1);
    expect(overview['sessionDurationMs'], isNotNull);
  });

  test('buildSessionOverview has null duration for small sessions', () {
    final controller = EmitraceController();
    controller.log('single');
    final overview = controller.buildSessionOverview();
    expect(overview['totalEvents'], 1);
    expect(overview['sessionDurationMs'], isNull);
  });
}
