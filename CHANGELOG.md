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
