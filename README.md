# arc-cookie-bar

GDPR/CCPA-compliant cookie consent bar for Arc public pages. Three consent flows, granular per-category toggles, localStorage persistence, and an optional server-side audit log — zero dependencies, ~3.5KB inline (CSS + JS + HTML).

## Features

- **Three consent flows** — Accept All, Reject All, or per-category customization
- **localStorage persistence** — survives reloads; configurable expiry (default 365 days)
- **`arcCookieConsent` event** — fires on every page load with stored or fresh prefs
- **`window.arcCookieBar` API** — `open()`, `getConsent()`, `reset()` for programmatic control
- **Three positions** — `bottom` (default), `top`, `modal`
- **Server audit log** — opt-in `POST /arc-cookie-bar/api/consent` with IP anonymization
- **Arc theme** — inherits `--ui-*` CSS variables automatically
- **GPU-composited animations** — `will-change: transform, opacity` on the banner
- **Accessible** — `role="dialog"`, `aria-modal`, `aria-expanded`, keyboard nav, Escape to dismiss
- **GDPR-safe server logging** — IPv4 last octet zeroed, IPv6 truncated to 64 bits
- **Zero dependencies** — no npm installs, no build step

## Install

```bash
npm install @arc-lang/arc-cookie-bar
```

Add to `arc.config.json`:

```json
{
  "packages": ["@arc-lang/arc-cookie-bar"]
}
```

## Quick start

```arc
import CookieBar from "@arc-cookie-bar/widgets/CookieBar.arc"

page "Home"
  CookieBar(policyUrl="/privacy")
  main
    h1 "Welcome"
```

The bar appears on first visit, stores consent for 365 days, and fires `arcCookieConsent` on every subsequent load so your scripts can conditionally initialise trackers.

## Widget props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `position` | String | `"bottom"` | `"bottom"` \| `"top"` \| `"modal"` |
| `categories` | String | `"necessary,analytics,marketing"` | Comma-separated consent categories |
| `policyUrl` | String | `"/privacy"` | Link to your cookie/privacy policy |
| `expires` | Int | `365` | Days before consent expires and bar re-appears |
| `title` | String | `"We use cookies"` | Banner headline |
| `description` | String | `"…"` | Banner body text |
| `serverPersist` | Bool | `false` | POST each decision to `/arc-cookie-bar/api/consent` |

## Reacting to consent

`arcCookieConsent` fires on every page load — immediately with stored prefs if consent already exists, or after the user acts on the banner. Wire it before any tracker initialisation:

```html
<script>
window.addEventListener('arcCookieConsent', function(e) {
  if (e.detail.analytics) initGA4()
  if (e.detail.marketing) initMetaPixel()
})
</script>
```

`e.detail` is a flat object of booleans, one per category:

```json
{ "necessary": true, "analytics": true, "marketing": false, "_e": 1748736000000 }
```

(`_e` is the expiry timestamp — ignore it in your handler.)

## `window.arcCookieBar` API

```javascript
window.arcCookieBar.open()         // re-open the bar (e.g. from a footer "Cookie settings" link)
window.arcCookieBar.getConsent()   // returns stored consent object, or null if not yet set / expired
window.arcCookieBar.reset()        // clear localStorage and re-show the bar (useful for testing)
```

Wire a footer link:

```arc
button onclick="window.arcCookieBar.open()" "Cookie settings"
```

## Custom categories

You can define any categories:

```arc
CookieBar(
  categories="necessary,analytics,marketing,preferences,social"
  policyUrl="/cookies"
)
```

`necessary` is always locked on. Built-in descriptions exist for `necessary`, `analytics`, `marketing`, and `preferences`. Any other name renders without a description.

## Server-side consent logging

For GDPR audit trails, enable server persistence:

```arc
CookieBar(serverPersist=true policyUrl="/privacy")
```

Each consent decision POSTs to `POST /arc-cookie-bar/api/consent`. The table is created lazily on first request — no migration needed.

**Schema:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER | Auto-increment PK |
| `necessary` | INTEGER | Always `1` |
| `analytics` | INTEGER | `1` if accepted |
| `marketing` | INTEGER | `1` if accepted |
| `preferences` | INTEGER | `1` if accepted |
| `ip` | TEXT | Anonymized IP — IPv4 last octet zeroed (`1.2.3.0`), IPv6 truncated to 64 bits (`2001:db8:1:2::`) |
| `ua` | TEXT | User-agent string, max 512 chars |
| `created_at` | TEXT | UTC timestamp |

**Security:** The consent endpoint accepts anonymous POSTs. It records consent decisions only — no personal data beyond the anonymized IP. If you want to reject requests from outside your domain, add a CSRF check or restrict with an Arc middleware.

## Positions

```arc
CookieBar(position="bottom")   // fixed to bottom (default) — slides up on show
CookieBar(position="top")      // fixed to top — slides down on show
CookieBar(position="modal")    // centered overlay with semi-transparent backdrop
```

## Theming

The bar inherits your Arc theme's CSS variables:

| Variable | Used for |
|----------|---------|
| `--ui-bg` | Banner background |
| `--ui-bg-2` | "Reject all" button background |
| `--ui-text` | Primary text |
| `--ui-muted` | Secondary text and category descriptions |
| `--ui-border` | Border, divider, and toggle track |
| `--ui-accent` | "Accept all" button, links, active toggle |
| `--ui-radius` | Border radius for bar and buttons |
| `--arc-font-sans` | Font family |

Override specific elements by targeting `.arc-cb` in your own stylesheet:

```css
.arc-cb { --ui-accent: #6366f1; }         /* custom accent */
.arc-cb__btn--accept { font-weight: 700; } /* bolder accept button */
```

## Performance

| Metric | Value |
|--------|-------|
| Client payload (CSS + JS + HTML) | ~3.5 KB inline |
| Consent check on repeat visit | ~0.1 ms (single `localStorage.getItem` + `JSON.parse`) |
| First-paint impact | None — bar starts hidden, shown after paint |
| DOM nodes (banner) | 14 |
| DOM nodes (customize panel, when open) | +4 per category |
| Server INSERT | O(log n) SQLite B-tree — < 0.1 ms |

## GDPR compliance notes

- `necessary` is always `true` and its toggle is disabled — no legal basis needed
- All other categories default to `false` — opt-in by default
- Consent is re-prompted after `expires` days
- Server-side IP is anonymized before storage — IPv4 last octet zeroed, IPv6 truncated to first 64 bits
- Consent records are write-only from the browser — no read endpoint is provided

## Browser support

All evergreen browsers (Chrome 80+, Firefox 75+, Safari 14+, Edge 80+). No IE11 support — uses `CustomEvent`, `fetch`, `localStorage`, `requestAnimationFrame`, and optional chaining via `?.` in Arc-compiled server code only.

## License

MIT — see [LICENSE](./LICENSE)
