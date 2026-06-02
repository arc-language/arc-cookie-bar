# Changelog

All notable changes to `@arc-lang/arc-cookie-bar` are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-06-02

### Fixed
- Widget no longer parsed by Arc's lexer due to multi-line `@raw '<style>…</style><div>…</div><script>…</script>'` string spanning lines 10–188. The whole body was a single quoted string but Arc's lexer treats `'…'` as single-line, producing `Unterminated string literal at 10:16` on every consuming page. Rewrote the widget as three single-line `@raw` blocks (style / script) with an Arc-native `div` tree for the bar markup in between.
- Repository URL pointed at the monorepo (`arc-web`) before this package was split out; corrected to `arc-language/arc-cookie-bar`.

### Added
- 5 new caller-overridable labels for full localization without forking the widget: `policyLabel`, `acceptLabel`, `rejectLabel`, `customizeLabel`, `saveLabel`. Defaults are English; pass through `tr.*` for NL/FR/etc.

## [0.1.0] - 2026-06-01

### Added
- `CookieBar` widget with Accept All / Reject All / Customize flows
- Per-category granular consent toggles (`necessary`, `analytics`, `marketing`, `preferences`)
- `localStorage` persistence with configurable expiry (default 365 days)
- `arcCookieConsent` CustomEvent fired on every page load with stored or fresh consent
- `window.arcCookieBar` API: `open()`, `getConsent()`, `reset()`
- Three layout positions: `bottom` (default), `top`, `modal`
- Optional server-side audit log via `POST /arc-cookie-bar/api/consent`
- IPv4 last-octet and IPv6 64-bit anonymization for GDPR compliance
- Arc theme integration via `--ui-*` CSS custom properties
- Full keyboard navigation: Tab, Space/Enter for toggles, Escape to reject all
- ARIA: `role="dialog"`, `aria-modal`, `aria-expanded`, `aria-hidden`
- Double-init guard (`window._arcCBInit`) prevents conflicts with multiple imports
- `will-change: transform, opacity` for GPU-composited animations
- `keepalive: true` on consent POST for reliable beacon on page unload
