import 'package:dio/dio.dart';
import 'package:emitrace/emitrace.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
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
      ),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        home: const ExampleHomePage(),
      ),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emitrace Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                EmitraceController().log(
                  'Manual log from example',
                  data: {'source': 'example_button'},
                );
              },
              child: const Text('Add Log Event'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _dio.get('https://jsonplaceholder.typicode.com/todos/1');
                } catch (_) {}
              },
              child: const Text('Send Sample Network Request'),
            ),
          ],
        ),
      ),
    );
  }
}
