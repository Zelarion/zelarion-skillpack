---
name: anti-flop-design-system
description: Audit and restyle a UI so it stops looking AI-generated. Finds the five "AI tells" (decorative gradients, colored icon tiles, flat same-size hierarchy, shadows on everything, generic copy and fake-uniform numbers) and applies the matching fix (one flat accent, the number is the hero, one primary + secondaries, shadow only on what floats with a radius ladder, numbers with a shape). Use on dashboards, KPI rows, admin panels, SaaS screens, landing sections, or any screen the user calls "AI-looking", "generic", "template", "flop", "de-AI", "kill the AI look", or when they invoke /anti-flop-design-system. Works as an audit (report tells with locations) or a restyle (apply the fixes).
---

# Anti-flop design system: five AI tells, five fixes

Source: the "De-AI your UI · 01" short (two screen recordings, 2026-10-15). Each tell is a default
that AI tools reach for because it looks finished at a glance. Each fix replaces the default with a
decision. Run the five in order; later fixes assume the earlier ones.

## How to run

1. **Audit first.** Screenshot or read the screen. For each tell below, list every occurrence with
   `file:line` (or the on-screen location) and severity. Do not fix while auditing.
2. **Restyle.** Apply fixes 01→05 in order. One tell per pass; re-screenshot after each so the change
   is attributable.
3. **Verify.** Re-run the audit checklist at the bottom. A screen passes when no tell remains that
   lacks a written reason.

Respect the project's own design system: these rules remove defaults, they never override a token the
project chose on purpose. When a project skill (e.g. elegant-design-for-system) sets a value, that
value wins and this skill only removes what is decoration.

## Tell 01 · The gradient → "One flat accent"

**Tell:** gradients with nothing to say. A purple-to-blue header bar, a gradient "Upgrade" button,
a gradient area fill under every chart line, glow behind cards.

**Fix:**
- Surfaces are flat. The header is the page ground, separated by a hairline, not a colored band.
- **One** accent colour, used flat, only on the single primary action (e.g. "Upgrade") and the
  current selection. Everything else is neutral.
- Charts: a plain line in the text or accent colour. No area gradient unless the area itself carries
  meaning (a range, a forecast band).
- A gradient is allowed only when it encodes data (a heatmap, a ramp legend) or is brand art.

## Tell 02 · Icon tiles → "The number is the hero"

**Tell:** four colors, four numbers. Each KPI card has its own colored rounded icon tile (blue $,
green people, purple arrow, orange pulse). The colors carry no meaning and compete with the value.

**Fix:**
- Delete the icon tiles from metric cards. Label (small, muted) above, value (large) below.
- Colour is reserved for state (positive/negative/warning), never for "which card is this".
- If an icon is truly needed for scanning, use one monochrome icon size, in the muted text colour.

## Tell 03 · Hierarchy → "One primary. Three secondary."

**Tell:** same size, same weight. Every card is identical (e.g. four 402×160 tiles in a 2×2 grid),
so nothing says what matters most.

**Fix:**
- Pick the **one** metric the screen exists for. Give it a large card (about 2× the width of the
  others) with a larger value (≈1.5–2× the secondary value size) and its breakdown inside it
  (e.g. Revenue $48,250 → Subscriptions $41,900 · One-time $6,350).
- The secondary metrics stack in a narrow column beside it, compact: label + value on the left,
  delta on the right, one line each.
- Type scale does the ranking: primary value > secondary value > labels. Never the same size twice
  for things of different importance.

## Tell 04 · Shadows → "Shadow only on what floats"

**Tell:** when everything floats. Drop shadow on the header, every card, the chart, the search
input, badges; one radius (16) on everything from cards to badges.

**Fix:**
- **Shadows only on layers that sit above the page**: menus, popovers, dropdowns (e.g. the
  Export / Filter / Share menu), dialogs, toasts. Cards, inputs, charts, tables: no shadow; separate
  them with a hairline border or spacing.
- **Radius ladder, outer → inner**, so nested shapes stay concentric:

  | Element | Radius |
  |---|---|
  | Page panel / large container | 16 |
  | Card | 12 |
  | Input, button, menu | 8 |
  | Badge, chip, pill | 6 |

  Rule: an inner radius is never larger than its container's radius minus the gap between them.

## Tell 05 · Copy → "Numbers with a shape"

**Tell:** "Welcome back, Jordan 👋" as the page title; the identical "+12.5%" green pill on every
metric; "+12.5% from last month" repeated; amounts not aligned.

**Fix:**
- **The heading states what and when**, not a greeting: `Revenue · Aug 1 to Aug 31, 2026`.
  No emoji in product chrome.
- **Deltas in the metric's own unit and honest sign**: `+12.5% vs Jul`, `+3.1%`, `+0.4 pt` for a
  rate, `−0.2 pt` for churn (down is good there, so colour by meaning, not by sign).
  Plain text, not a filled pill, unless it is a status.
- Give the primary number a **shape**: a small sparkline beside it showing the period trend.
- Money columns: **tabular numerals, right-aligned on the decimal**, so `$1,240.00`, `$86.00`,
  `$2,310.50` line up in one column.
- Real, specific labels and periods everywhere; never placeholder-identical data across cards.

## Audit checklist (pass = every box checked or a written reason)

- [ ] No decorative gradient on chrome, buttons, or chart fills (01)
- [ ] Exactly one accent colour, flat, on the primary action and selection only (01)
- [ ] No colored icon tiles on metrics; colour means state only (02)
- [ ] One primary metric is visibly larger, with its breakdown; secondaries are compact (03)
- [ ] No two different-importance items share a type size and weight (03)
- [ ] Shadows exist only on menus, popovers, dialogs, toasts (04)
- [ ] Radius ladder 16 / 12 / 8 / 6 (or the project's own ladder), concentric when nested (04)
- [ ] Headings name the metric and period; no greeting, no emoji (05)
- [ ] Deltas use the right unit (%, pt) with comparison period; colour follows meaning (05)
- [ ] Amounts use tabular figures and align on the decimal (05)

## Output

- Audit mode: a table `tell | location | what it is | fix`, ordered by tell number.
- Restyle mode: the diff plus a before/after screenshot per tell, and the checklist with each box
  ticked or explained.
