# Emitrace Example

This example demonstrates the recommended Emitrace v1.2.0 integration flow:

- `EmitraceScope` setup with `EmitraceConfig`
- `EmitraceRouteObserver` setup in `navigatorObservers`
- Manual APIs: `Emitrace.log`, `Emitrace.event`, `Emitrace.action`, `Emitrace.breadcrumb`
- Dio integration with `EmitraceDioInterceptor`
- Error capture + screenshot flow
- Timeline search/filter in Logs tab
- Crash context summary shown in error details
- Copy Debug Bundle and GitHub issue export from Device tab actions
- Discord webhook config shown but disabled by default

Run:

```bash
flutter run
```
