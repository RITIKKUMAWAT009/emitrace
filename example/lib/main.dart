import 'package:dio/dio.dart';
import 'package:emitrace/emitrace.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
final EmitraceRouteObserver _routeObserver = EmitraceRouteObserver();
final Dio _dio = Dio()..interceptors.add(EmitraceDioInterceptor());

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return EmitraceScope(
      config: EmitraceConfig(
        appName: 'Emitrace Example',
        navigatorKey: _navigatorKey,
        showOverlay: true,
        enableAutoScreenshotOnError: true,
        enableReportGenerator: true,
        enableSlackIntegration: false,
        slackWebHookUrl: '',
      ),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        navigatorObservers: [_routeObserver],
        home: const ExampleHomePage(),
      ),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  Future<void> _safeFailingRequest() async {
    try {
      await _dio.get('https://httpstat.us/500');
    } catch (e, st) {
      await Emitrace.error(e, st, data: {'source': 'failing_request'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emitrace Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {
              Emitrace.log(
                'Manual log from example',
                data: {'screen': 'home'},
              );
            },
            child: const Text('Emitrace.log'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Emitrace.event(
                'checkout_started',
                data: {'cartItems': 3},
              );
            },
            child: const Text('Emitrace.event'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Emitrace.action(
                'tap_primary_cta',
                data: {'cta': 'start_debug'},
              );
            },
            child: const Text('Emitrace.action'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await _dio.get('https://jsonplaceholder.typicode.com/todos/1');
            },
            child: const Text('Dio Success Request'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _safeFailingRequest,
            child: const Text('Dio Failing Request (500)'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Emitrace.captureScreenshot(reason: 'manual_example');
            },
            child: const Text('Capture Screenshot'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              await Emitrace.captureReport();
            },
            child: const Text('Generate Report'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: 'details_page'),
                  builder: (_) => const DetailsPage(),
                ),
              );
            },
            child: const Text('Navigate to Details Page'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              throw StateError('Forced crash from example app');
            },
            child: const Text('Force Error'),
          ),
        ],
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Emitrace.breadcrumb('Back tapped from details page');
            Navigator.of(context).pop();
          },
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
