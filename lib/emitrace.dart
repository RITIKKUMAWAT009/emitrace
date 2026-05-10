// Emitrace package entry point.
// Import this library to enable the in-app debug overlay, capture logs and
// network events, and generate shareable QA reports.

// Core
export 'src/core/emitrace_config.dart';
export 'src/core/emitrace_controller.dart';
export 'src/api/emitrace_api.dart';

// Overlay
export 'src/overlay/emitrace_scope.dart';

// Network
export 'src/modules/network/emitrace_dio_interceptor.dart';
export 'src/modules/navigation/emitrace_route_observer.dart';

export 'src/ui/emitrace_panel.dart';
