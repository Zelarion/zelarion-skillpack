---
name: elegant-design-for-system
description: Design and build internal systems (business workspaces, admin and operator consoles, dashboards, analytics, CRUD screens) in the same elegant "atelier" language as a premium landing page, adapted for daily work. Covers design tokens with measured contrast, light and dark themes without flash, one per-device size scale (phone, tablet, laptop, desktop), app shell (sidebar, collapsed rail, header with person menu vs business card, route breadcrumb), modern mobile UI (bottom tab bar + Menu bottom sheet while keeping the hamburger drawer), bento KPI grids, themed banner art (same image rendered for light and dark), data tables that become cards on phones, forms in sheets, charts, micro-interactions, empty/loading/error states, the shared 404, and a Playwright QA loop. Use when building or restyling a dashboard, workspace, console, admin panel or any logged-in app, or when asked for light/dark mode, mobile navigation, responsive scales, or "make the system match the landing page". For public marketing pages use elegant-design-with-3d.
---

# Elegant design for systems
> Sample code and copy use "Brand" and "yourbrand.example" as placeholders; swap in your own product name, mark and domain.

Reference implementation: a production business workspace (Next.js 15, Tailwind v4, Radix,
lucide). The working code is copied into `references/`; scripts in `scripts/`. A system is used
for hours a day, so restraint beats spectacle: no WebGL, no preloader, no scroll-jacking. Keep the
landing's type, palette, labels and curves; spend motion only on feedback.

Run with: `design-md-library` (read linear.app, posthog, sentry for density) → `ui-ux-pro-max`
→ this skill → `impeccable` as the QA gate. Brand palette and fonts come from the product's
landing page (see `elegant-design-with-3d`).

## 1. Tokens and the two themes

Semantic tokens, not brand names, so components never know which theme is on
(`references/workspace-globals.css`):

| Token | Light | Dark | Purpose |
|---|---|---|---|
| canvas | #f5efe6 paper | #120e0b night | page ground |
| surface | #fffcf7 | #1b1511 | cards, header, sidebar |
| border | #e2d7c8 | #3a2e25 | hairlines |
| navy (text) | #1f1712 | #f5efe6 | primary text |
| muted | #6b5e53 (5.5:1) | #b9ada0 (8.2:1) | secondary text |
| active | #ece1cf | #261d17 | selected rows, nav, hovers |
| accent | #7a5830 gold-ink (5.6:1) | #d4b483 champagne (9.2:1) | **text**: links, active icons, rings |
| primary / primary-ink | #1f1712 / #f5efe6 | #d4b483 / #120e0b | **filled** controls (8:1+) |
| danger | #b3311f | #ff8a7a | |
| gold-soft / gold-text, green-soft / green-text, neutral-soft / neutral-text | tinted chips |

Rules learned the hard way:
- **Accent is a text colour; primary is a fill.** White text on a gold fill measured 2.34:1.
  Filled buttons use dark ink on champagne at night and paper on espresso by day.
- Measure every pair with `scripts/contrast.mjs` and write the ratio beside the token.
- Status chips: text at least 5.5:1 on their own tint in light mode. Light tints are easy to get
  wrong when a product only ever shipped dark.
- Third-party widgets: current Clerk (verified on @clerk/nextjs 7.9) reads `--clerk-color-primary`,
  `--clerk-color-primary-foreground`, `--clerk-color-background`, `--clerk-color-foreground`,
  `--clerk-color-muted-foreground`, `--clerk-color-input`, `--clerk-color-input-foreground`,
  `--clerk-color-neutral`, `--clerk-color-ring`, `--clerk-font-family` set on a wrapper, so it
  follows the theme with no JavaScript. Older setups (or widgets without CSS variables) get a
  per-theme value map chosen from the resolved theme.

### Theme mechanism (no flash, no forced theme)

`references/theme-boot.ts`, `references/theme.ts`, `references/layout.tsx`:

1. A boot script string runs in `<head>` before paint: reads `localStorage['<app>-theme']`
   (`light|dark|system`), resolves `system` with `prefers-color-scheme`, sets
   `<html data-<app>-theme>`. `suppressHydrationWarning` on `<html>`.
2. Keep the constants in a **non-"use client"** module: a server component that imports a
   constant from a client module gets a reference, not the string.
3. `useTheme()` is `useSyncExternalStore` over localStorage, a custom event, the `storage` event
   (other tabs) and the media query (OS switch while on "system"). Guard `matchMedia` for jsdom.
4. Dark tokens are keyed on `html[data-<app>-theme="dark"]` only. Grep for and delete any code
   that forces a theme on mount (an access gate did it in the reference and silently overrode
   the user's choice).
5. Controls: a sun/moon icon button in the header (one click) and a Light/Dark/Match system
   radio group in the account menu and the phone Menu sheet.

## 2. One size scale per device class

One source of truth, stepped per device rather than ad-hoc breakpoints in components:

| Token | Phone <640 | Tablet 640+ | Laptop 1024+ | Desktop 1440+ |
|---|---|---|---|---|
| text-micro (labels) | 11 | 11 | 11 | 11 |
| text-small | 13 | 13 | 13 | 14 |
| text-body | 15 | 15 | 14 | 15 |
| text-input | **16** (no iOS zoom) | 15 | 14 | 14 |
| text-section | 18 | 18 | 18 | 20 |
| text-kpi | 24 | 26 | 28 | 30 |
| text-title (page h1) | 30 | 34 | 36 | 40 |
| text-hero (banner h1) | 32 | 40 | 44 | 52 |
| control height | **44** (touch) | 42 | 40 | 40 |
| gutter | 16 | 24 | 32 | 40 |
| gap | 12 | 16 | 16 | 20 |
| card radius | 18 | 18 | 16 | 16 |
| header / tab bar | 60 / 68 | 64 | 64 | 64 |

Implementation: CSS variables on `:root` with four media blocks, mapped to utilities through
Tailwind v4 `@theme inline` (`text-ws-title`, `h-ws-control`, `px-ws-gutter`, `gap-ws-gap`,
`rounded-ws-card`). `@theme inline` matters: it inlines `var()` so the media queries take effect.
Base `Input`, `Textarea` and `Button` read the scale, so every form inherits it.

## 3. Type

- Display face (Didone) for page titles, banner headlines, section headings, and the brand
  wordmark only. One class (`.dashboard-page-title`) so titles never disagree.
- Sans (Jost) for everything else. **Numbers use the sans with `tabular-nums`**: Didone
  numerals read as letters at KPI sizes (a 0 looks like O, a 1 like I).
- Uppercase micro labels (`.dashboard-eyebrow`): 0.3em tracking, weight 500.
- One `h1` per page. A section layout (Settings) shows "Settings" as the eyebrow and the
  sub-page name as the h1. Hide embedded widget titles (`display:none`, not just visually).
- Italic accent word in banners: `Your rental business <em class="text-accent">today</em>`.

## 4. App shell

`references/dashboard-sidebar.tsx`, `dashboard-header.tsx`, `workspace-nav.ts`.

- **Two identities, two shapes.** Business = sidebar card with a *square* logo tile, an eyebrow
  "Workspace" and business links. Person = header button with a *round* avatar, name and email,
  and the personal menu (profile, security, theme, sign out). Never show the same role label in
  both places.
- Every menu item does something. Use `DropdownMenuItem asChild` + `Link`, or `onSelect`
  handlers. For hash-routed widgets on the same path, set `location.hash` directly: a client
  push does not fire `hashchange`.
- Sidebar: eyebrow "Menu", items with a 2px accent bar on the active item, accent-coloured active
  icon, muted inactive text. Collapsed rail (72px): icons with hover/focus tooltips, and nothing
  disappears (help included).
- Breadcrumb derived from the route via one label map (`references/workspace-routes.ts`): every
  level linked except the current page. On phones show parent › current only. Remove in-page
  back links that duplicate it.
- One nav model (`workspace-nav.ts`) feeds the sidebar, the tab bar and the Menu sheet.

## 5. Mobile UI (below 768px)

`references/mobile-tab-bar.tsx`.

- **Bottom tab bar, five slots:** four daily screens plus **Menu**. Icon in a 56×32 pill that
  fills when active, label under it, a gold indicator that slides to the active slot
  (`translateX(index * 100%)`, 300ms reveal curve), `active:scale-95` press feedback,
  `env(safe-area-inset-bottom)` padding.
- Put the bar **in the shell's flex column**, not `position: fixed`, so sticky save bars and
  page footers end above it with no padding hacks.
- **Menu bottom sheet:** drag handle, eyebrow + Didone title (business name), a 3-column tile
  grid of the remaining pages with staggered entrance (80ms), a "You" card, a 3-way theme
  segmented control, and a tinted danger "Sign out" tile showing who is signed out.
- **Keep the hamburger.** It still opens the full sidebar drawer (TikTok keeps both a tab bar and
  a full menu); the tab bar is the thumb-reach shortcut.
- Tables become cards below 640px: name + status chip, contact line, counts, actions menu on the
  right. Stats become a 2-column bento (an odd last card spans both columns).
- In jsdom both layouts render; scope tests with `within(getByRole('table'|'navigation', …))`.

## 6. Pages

- **Banner** (`references/page-hero.tsx`): themed art behind eyebrow, Didone headline, lead
  copy, drawn gold rule; content rises in 80ms steps. A gradient scrim on the text side keeps
  copy at 4.5:1. Use it on the dashboard and on hub pages (Help), not on every list.
- **Themed art**: one composition rendered twice, for light and dark
  (`scripts/themed-banner.py`, PIL, fixed seed; gold-thread constellation with glow, bokeh,
  sweep line and grain). Render both `<img>`s and hide the wrong one with
  `html[data-theme=dark] .art-light, html:not([data-theme=dark]) .art-dark { display:none }`, so
  nothing swaps after hydration. No stock or hotlinked images.
- **KPI bento**: icon tile in a tinted rounded square, chevron that nudges 2px on hover, label,
  tabular number, one line of meaning ("Currently with customers"). The whole card is the link.
- **Lists**: search + filters card on top, rows clickable (pointer cursor, hover tint), the name
  is a real `<button>` for keyboard users, and the actions cell stops propagation. One shared
  pagination footer (`references/list-pagination.tsx`): "Page 2 · 1 customer", Previous/Next with
  text labels.
- **Forms**: grouped `Section` cards with an icon tile, title and one-line description; sticky
  save bar with live status ("You have unsaved changes", "Saved"); `beforeunload` guard while dirty.
  Mutations use the project's submit guard (disabled + pending + idempotency key).
- **Help Center**: themed banner, four topic tiles, `<details>` guides written against the real
  screens, a support card with email and the public FAQ.
- **404 and error**: the same markup in every app of the product: brand mark, eyebrow
  "Error 404", Didone "Page not found", a short gold rule, one line, a pill primary action that
  fits the app (Back to dashboard / Back to console / Back to site) and a ghost Go back, a
  faint giant italic "404" behind.

## 7. Charts and analytics

- Draw with the tokens: series 1 = accent, series 2 = muted, positive = green-text, negative =
  danger. Gridlines = border at 60%, axis labels = muted text-small, tooltips = surface card with border.
- Prefer plain SVG or a light library (Recharts, visx). One chart type per question: trend =
  line or area, comparison = bars, share = stacked bar (avoid pies above 4 slices).
- Every chart has a text summary (the number and its change) above it, an empty state, and a
  loading skeleton with the same height. Numbers are tabular; units are stated.
- Animate once on entry (draw a line over 700ms with the reveal curve), never on every update.

## 8. Micro-interactions and motion

Three curves only: UI `cubic-bezier(0.4,0,0.2,1)` 150–300ms (hover, press, colour); reveal
`cubic-bezier(0.22,1,0.36,1)` (entrances, indicators); drama `cubic-bezier(0.77,0,0.175,1)` only
for the banner rule. Press `scale(0.97)`, chevron nudge, sheet slide 260ms in / 200ms out, staggered
tiles 80ms. Under `prefers-reduced-motion` every keyframe is off and transitions are instant.

## 9. Accessibility gates

- 4.5:1 text, 3:1 large text and UI boundaries, in **both** themes.
- Icon-only buttons have `aria-label` (the phone avatar button was nameless).
- One h1 per page; valid `<dl>` (dt/dd only, wrap pairs in `<div>`); visible `:focus-visible`.
- Scroll containers that hold tables must be keyboard focusable (`tabIndex=0` + label) or axe
  flags `scrollable-region-focusable`.

## 10. Plain-CSS codebases (no Tailwind)

Same system, expressed as CSS custom properties (reference: an operator console). Keep legacy
token names if renaming would churn the codebase, but remap their values and document the meaning
(`--blue-dark` = filled-control colour, text on it is `--primary-ink`). Redefine the tokens under
`:root[data-theme="dark"]`. The tab bar can be `position: fixed` there because nothing is sticky at
the bottom; then pad the page content by the bar height plus `env(safe-area-inset-bottom)`. The
banner art can be a CSS `background-image` swapped by the theme selector.

## 11. QA loop (Playwright)

`scripts/verify-themes.mjs`: persistent signed-in profile, `addInitScript` to set the theme
before load, every in-scope page at 1440 and 390 wide, in light and dark. Record h1s, breadcrumb,
horizontal overflow, console errors and axe violations; screenshot each. Then an interaction
script: every menu item navigates, the theme persists after reload, row click vs actions menu,
collapsed-rail links, the tab bar and Menu sheet. Dev-only overlays (the Next.js "N" badge) can
block clicks in the bottom-left corner; use keyboard activation there. Compare unit-test
failures against `main` (stash, run, diff) so only regressions you caused are counted.

## Checklist

- [ ] Semantic tokens for both themes, contrast measured and commented
- [ ] Boot script before paint; no component forces a theme
- [ ] Per-device size scale through `@theme inline`; inputs 16px and controls 44px on phones
- [ ] Display face for titles only; tabular sans numbers
- [ ] Person menu and business card visibly different, every item working
- [ ] Route breadcrumb from one label map
- [ ] Phone tab bar + Menu sheet in the shell column; hamburger kept
- [ ] Tables to cards and 2-column bento on phones
- [ ] Themed art rendered for both themes, CSS-swapped
- [ ] Shared 404 across every app of the product
- [ ] Playwright light + dark × desktop + phone, axe clean

---

## 12. Ledger layout and five-class scale (OPT-IN)

**Apply this section only when the user explicitly says to apply elegant-design-for-system (or
"the ledger layout") to a page.** It does not change sections 1–11 or any page nobody asked about.
Reference: the car-loan amortization console (a private WebForms project;
`Content/Site.css` §2 and §6–9, `Reports/Amortization.aspx`); the excerpt lives in
`references/ledger-console.css`.

### 12.1 Hairlines before cards

The page is one sheet of paper. Structure comes from type, hairline rules, alignment and white
space; a box is the exception, kept for the single task area of a page.

| Need | Use | Not |
|---|---|---|
| Page header | eyebrow · Didone title · muted lead · actions, closed by a `3px double` rule | a banner card |
| Section | `border-top: 1px` hairline, Didone section title + muted meta on one baseline | a card per section |
| Key/value details | `dl.facts`: label left (muted, small), value right (ink, 500, tabular), one hairline between rows, none after the last | a card grid of tiny boxes |
| KPI row | `.figures`: a grid whose dividers are each item's `-1px 0` / `0 -1px` box-shadow inside an `overflow:hidden` wrapper, so the same markup draws a clean grid when it wraps | four floating cards |
| Lists | `.ledger` table: micro uppercase sticky header, hairline rows, `tabular-nums` right-aligned money, `3px double` rule above the totals row, row states as a 2px inset bar (accent = next, danger = overdue) | striped or boxed rows |
| Status | a 7px dot + text (`.status`), colour from meaning | filled pills everywhere |
| Primary task | `.well`: tinted ground, 12px radius, the only box on the page | — |

Use the free width: two `dl.facts` side by side (`columns-2`, 3.5rem gap at 1024+), main + 21rem
aside at 1200+. Negative inline margins let row hover tint reach the gutter while text stays on the
page edge.

### 12.2 No horizontal scrolling on phones, ever

Horizontal scroll ruins a phone UI. Below 640px:
- **Tables become stacked rows separated by hairlines, not cards**: hide `thead` visually, each
  `td` becomes a flex row with its `data-label` on the left and the value right-aligned; the first
  cell is the row title at 17px. Never wrap a table in `overflow-x:auto` on phones.
- **Tabs / segmented sub-navigation wrap or stack; they never scroll sideways.** Up to 4 short
  items: an equal-width grid (2 columns if labels are long). More than 4, or labels that do not fit:
  a full-width native-feeling select/menu ("Section: Business information ▾") or a vertical hairline
  list. The reference console's `.tabs { overflow-x:auto }` is the pattern NOT to copy.
- Long values wrap (`overflow-wrap:anywhere`), figures go 2 per row, step indicators collapse to
  numbers with only the current label shown.
- QA gate: at 360, 390 and 430 wide, `document.documentElement.scrollWidth === clientWidth` and no
  element inside `main` has `scrollWidth > clientWidth` except deliberate media.

### 12.3 One size scale, five device classes, interpolated in between

Stepped tokens per class (px). Between two anchors, type and spacing interpolate with `clamp()`
anchored at the two class widths, so in-between widths never jump.

| Token | Phone <640 | Tablet 640+ | Laptop 1024+ | Desktop 1440+ | Big monitor 1920+ |
|---|---|---|---|---|---|
| micro (labels) | 11 | 11 | 11 | 12 | 12 |
| small | 13 | 13 | 13 | 14 | 15 |
| body | 15 | 15 | 14 | 15 | 16 |
| input | **16** | 15 | 14 | 15 | 16 |
| section title | 20 | 20 | 20 | 22 | 24 |
| kpi | 24 | 26 | 28 | 30 | 34 |
| page title | 30 | 34 | 36 | 40 | 46 |
| control height | **44** | 42 | 40 | 40 | 44 |
| gutter | 16 | 24 | 32 | 40 | 48 |
| gap | 12 | 16 | 16 | 20 | 24 |
| section gap | 36 | 44 | 44 | 52 | 64 |
| content max | — | — | 78rem | 78rem | 96rem |

Interpolation recipe (example, page title 30→34 between 360 and 640, then stepped):
`--t-title: clamp(1.875rem, calc(1.875rem + (2.125 - 1.875) * ((100vw - 22.5rem) / (40 - 22.5))), 2.125rem);`
Generate one such clamp per token per adjacent pair; a component never sets its own px size.
