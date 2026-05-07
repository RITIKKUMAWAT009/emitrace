# Emitrace Example

This example demonstrates how to integrate Emitrace in a Flutter app.

## What this example shows

- Wrapping your app with `EmitraceScope`
- Configuring `EmitraceConfig` with `navigatorKey`
- Adding `EmitraceDioInterceptor` to Dio
- Creating manual log events using `EmitraceController().log(...)`

## Run example

```bash
cd example
flutter pub get
flutter run
```

After launch, use the floating `E` button to open the panel and inspect logs.
