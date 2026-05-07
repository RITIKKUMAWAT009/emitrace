## 1.0.2

Improves pub.dev package quality and release readiness.

### Added
- Added dartdoc comments for core public API symbols (`emitrace` library, `EmitraceConfig`, `EmitraceScope`, `EmitraceController`, and `EmitraceDioInterceptor`).
- Added runnable Flutter example app under `example/` showing `EmitraceScope` and `EmitraceDioInterceptor` integration.

### Changed
- Updated dependency constraints to support latest stable majors for `package_info_plus` and `share_plus`.

## 1.0.1

Improves report/screenshot reliability and clarifies host-app integration for gallery save.

### Changed
- Persist screenshots and generated reports in application documents directories instead of temporary storage.
- Add redirect-aware Slack webhook posting for better compatibility with webhook endpoints that return HTTP redirects.
- Add in-app "View Latest Report" flow with report content preview and quick copy action.
- Expand device diagnostics shown in the panel (processors, locale, hostname).
- Replace direct gallery package flow with native host-app `MethodChannel('emitrace/gallery')` contract guidance.
- Add Dependabot configuration for weekly dependency update PRs.

### Fixed
- Harden screenshot capture timing by waiting for end-of-frame and validating mounted render context before capture.
- Improve user-facing error/success feedback for report generation and sharing actions.

## 1.0.0

Initial stable release of emitrace.

### Added
- Overlay launcher (`E`) with in-app debug panel.
- Logs tab with type filters (`all`, `network`, `error`, `navigation`, `log`).
- Tap log to view full metadata/body details.
- Network tracking with `EmitraceDioInterceptor`.
- Device and app info screen with copy action.
- Automatic screenshot capture on app/framework errors.
- Optional screenshot save-to-gallery support.
- Markdown report generation from captured events.
- Slack webhook integration for report summaries.
- Manual report share/export actions from panel.

### Notes
- Slack incoming webhook sends rich text summary and report context.
- Slack file upload via bot token/API is planned for a future version.
