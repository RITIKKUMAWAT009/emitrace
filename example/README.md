# Emitrace Example

This example demonstrates the recommended Emitrace integration flow:

- `EmitraceScope` setup with `EmitraceConfig`
- `EmitraceRouteObserver` setup in `navigatorObservers`
- Manual APIs: `Emitrace.log`, `Emitrace.event`, `Emitrace.action`, `Emitrace.breadcrumb`
- Dio integration with `EmitraceDioInterceptor`
- Error capture + screenshot flow
- Report generation flow

Run:

```bash
flutter run
```
