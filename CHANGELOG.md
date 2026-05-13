## 1.2.0

### UX
- Kept the familiar bottom-sheet panel structure with `Logs`, `Network`, and `Device` tabs.
- Cleaned up spacing and action grouping in Device tab to reduce visual clutter without changing workflow.

### Added
- Timeline UX upgrade with grouped cards, clearer type badges, timestamps, and inline expandable details.
- Search in timeline with filters for `all`, `log`, `event`, `action`, `navigation`, `network`, and `error`.
- Crash context summary generation including latest route, previous route, last 3 actions/events, last failed network request, and screenshot path when available.
- New report builders:
  - `EmitraceController.generateGitHubIssueMarkdown()`
  - debug bundle markdown generation for copy/share workflows.
- Optional Discord webhook support in `EmitraceConfig`:
  - `enableDiscordIntegration`
  - `discordWebhookUrl`
- Device tab actions include report/debug operations with simple section grouping:
  - Generate Report
  - Copy Debug Bundle
  - Copy GitHub Issue Markdown
  - Send Report To Slack/Discord
  - Clear Logs & History

### Changed
- `reportToJson()` now includes additive `crashContextSummary` payload.
- Markdown report output now includes crash context summary and team-oriented debug sections.
- Example app updated to demonstrate new timeline/report workflow and Discord config disabled by default.
- Documentation refresh across README, ROADMAP, and example docs for v1.2.0 workflows.

### Compatibility
- Existing v1.1.x public APIs remain compatible.
- Slack integration behavior remains unchanged.

## 1.1.1

### Fixed
- Tightened dependency lower bounds to improve compatibility with pub.dev downgrade/static checks on current stable Dart/Flutter.
- Updated share API usage to avoid deprecated `share_plus` calls and improve pub points for static analysis.
- Improved release readiness and publish validation reliability for this patch release.

## 1.1.0

Focused DX and report-quality upgrade without breaking existing APIs.

### Added
- Added `EmitraceRouteObserver` for easy route transition tracking (`push/pop/replace/remove`) with previous and current route context.
- Added beginner-friendly static API:
  - `Emitrace.log(...)`
  - `Emitrace.event(...)`
  - `Emitrace.action(...)`
  - `Emitrace.breadcrumb(...)`
  - `Emitrace.error(...)`
  - `Emitrace.captureReport()`
  - `Emitrace.captureScreenshot()`
- Added action/event timeline support in logs and reports.
- Added JSON-serializable report payload via `EmitraceController.reportToJson()`.
- Added docs: `ROADMAP.md`, `CONTRIBUTING.md`, and GitHub issue templates.

### Changed
- Improved markdown report format with app name, timestamp, current route, recent navigation, recent actions/events/logs, errors, network logs, screenshots, and metadata.
- Device tab now includes explicit “Clear Logs & History”.
- Example app now demonstrates full Emitrace flow: scope setup, route observer, manual APIs, dio success/failure, forced error, screenshot capture, and report generation.
- Pubspec metadata refined for better pub.dev discoverability.

### Fixed
- Error handlers now install independently from auto-screenshot toggle.
- Dio error path now records failed calls into `network` timeline as well.
- Request timing in Dio interceptor now handles concurrent same-path requests safely.

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
