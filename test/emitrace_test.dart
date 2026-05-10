import 'package:emitrace/emitrace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Emitrace static API is callable', () async {
    Emitrace.log('hello');
    Emitrace.event('event');
    Emitrace.action('action');
    Emitrace.breadcrumb('crumb');

    final reportData = EmitraceController().reportToJson();
    expect(reportData['totalEvents'], greaterThan(0));
  });
}
