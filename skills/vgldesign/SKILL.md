---
name: vgldesign
description: Front-end design stack — eight measured, production-grade motion techniques (reverse-engineered from attorneyx.law) plus a three-curve easing system, wired to run on top of the design-md-library reference corpus and the ui-ux-pro-max, impeccable, and taste-skill design skills, and routing to img2threejs plus scrolljack-3d-transitions when a page needs a real 3D object. Use when building or polishing marketing sites, landing pages, portfolios, or any UI needing scroll reveals, hero choreography, parallax, marquees, mobile menu takeovers, custom scrollbars, 3D heroes, or a coherent motion language. Trigger with /vgldesign, "vgl design", "apply the vgl techniques", or when asked to make a site feel premium, editorial, or expensive.
---

# vgldesign — the house front-end design stack

## How to run this skill

vgldesign is the **motion and finish layer**. It does not replace design
judgement — it sits on top of it. Before applying anything below, load the
companion skills in this order and follow them:

0. **`design-md-library`** — *reference, not process.* Open two or three brands
   from the same category as what you are building and read their actual
   numbers. This is how you replace "make it feel premium" with a type scale you
   can cite. Costs one read and kills most of the arguing later. Skip only if
   the direction is already settled and specified.
1. **`ui-ux-pro-max:ui-ux-pro-max`** — first. Settles the structural decisions:
   product type, information architecture, layout system, color palette, font
   pairing, component selection, accessibility and UX rules for the stack in use.
2. **`taste-skill:taste-skill`** — second. Anti-slop pass. Kills templated
   defaults, forces a real design direction, and runs the audit-first flow on
   redesigns. On an existing codebase, prefer `taste-skill:redesign-skill`.
3. **`impeccable:impeccable`** — third, and again at the end. Visual hierarchy,
   cognitive load, spacing, alignment, edge and error states, live browser
   iteration. Run it once before implementing and once after, as the QA gate.
4. **This skill, last** — the motion language and the eight finish techniques.

Skip a companion only when the user has already made that layer's decisions.
Announce which ones you are loading and why.

**Division of labour, so the skills don't fight:**

| Layer | Owns | Never decides |
|---|---|---|
| design-md-library | evidence — what real systems actually specify | anything; it is a citation source, not a decision |
| vgldesign-watermelon | the Watermelon component kit — install commands, source, dependency cost, token remapping | motion timing; its own springs defer to the curves below |
| ui-ux-pro-max | IA, layout, palette, type pairing, components, a11y | easing curves, reveal distances |
| taste-skill | direction, anti-generic pass, audit | motion timing |
| impeccable | hierarchy, spacing, states, polish QA | brand palette |
| **vgldesign** | **easing curves, reveal choreography, scroll behaviour, finish details** | palette, IA |
| img2threejs | the 3D *asset* — geometry, materials, sculpt spec | where it sits on the page, how it moves on scroll |
| scrolljack-3d-transitions | scroll orchestration for a 3D object across sections | what the object is made of |

If two skills conflict on a concrete value, the more specific layer wins:
vgldesign for anything with a duration or an easing curve, ui-ux-pro-max for
anything with a color or a breakpoint, design-md-library for "what does a real
system use here" — and when the corpus and a decision conflict, the decision
wins. The corpus is evidence, not authority.

---

## When you are building from the Watermelon kit

If the project pulls components from `registry.watermelon.sh` — or anyone says
"watermelon", "morphing button", "fluid tabs", "footer-16" — load
**`vgldesign-watermelon`**. It carries the component index with install commands, the
captured Footer 16 source, the dependency map, and the token remapping that has to happen
before any of it belongs in a branded product.

Two things that skill will tell you, worth stating here because they are motion decisions
and therefore this skill's business:

- Those components ship **their own springs** (`spring, duration 1.1, bounce 0` and
  friends). Translate them onto the three curves below, or write down that a given
  component is a deliberate exception. Two motion systems running unacknowledged is how a
  codebase ends up with a dozen unrelated timings — which is the exact problem the curve
  system exists to prevent.
- Keep two things from their motion as-is: `bounce: 0` (bouncy springs read as playful and
  most products are not), and `active:scale-[0.96]` on presses. A press that acknowledges
  itself buys more perceived quality than most scroll animation.

They also have **no `prefers-reduced-motion` path at all**. Add one before shipping.

---

## When the page needs a 3D object

Reach for 3D only when a flat image genuinely cannot carry the idea — a product
that must be rotated, a form that must be understood in the round. A 3D hero
that exists to prove the site can do 3D is the most expensive kind of slop.

When it is warranted, the pipeline splits cleanly in two and the split matters:

1. **`img2threejs`** builds the *thing*. Give it a reference image; it returns a
   code-only procedural Three.js model — geometry, materials, a sculpt spec —
   gated by a staged pipeline with a vision self-correction loop. Reconstruction
   by code, not photogrammetry or a downloaded asset pack, so the output is
   diffable, animatable, and small enough to ship.
2. **`scrolljack-3d-transitions`** choreographs it. Section snapping, the object
   travelling between sections, z-depth layering so it sits behind text but
   above the background, Lenis + GSAP orchestration.
3. **This skill** still owns the easing. A 3D object that moves on a curve
   nobody chose reads as a tech demo, not as design — use the three curves
   below for its transitions exactly as you would for a DOM element.

Budget honestly before starting: a procedural model is cheap to ship but not
free to build, and the mobile cost is real. If the object cannot justify the
frame budget on a mid-range Android, ship the flat image.

---

# The eight techniques that make a site feel expensive

Every number below was **measured** from live production sites with Playwright
(computed styles, stylesheet rules, and grepped JS bundles), not estimated.
Primary source: `attorneyx.law` (WordPress, `esqx-theme`). Cross-checked against
two React codebases using Lenis + GSAP + Framer Motion.

The headline finding: that site runs **no GSAP, no Lenis, no Framer Motion, no
Locomotive**. It uses `IntersectionObserver`, Tailwind transition utilities,
native `@keyframes`, and the Web Animations API. Craft came from discipline, not
from libraries. Reach for the library only when a technique genuinely needs it.

---

## The curve system — adopt this first

Three curves. Every animation names one. More than three curves in a codebase
means nobody decided anything.

```ts
export const EASE_UI     = [0.4, 0, 0.2, 1]    as const; // hovers, buttons, small state changes
export const EASE_REVEAL = [0.22, 1, 0.36, 1]  as const; // scroll entrances
export const EASE_DRAMA  = [0.77, 0, 0.175, 1] as const; // hero + curtain only, sparingly
```

`EASE_UI` is Tailwind's stock `ease-in-out`. The reference site applies it to
*every* hover and button transition site-wide and reserves the punchier
`EASE_DRAMA` for the hero alone. Consistency reads as intent; novelty reads as noise.

---

## 1. Attribute-driven scroll reveal

One observer, one class, declarative per-element config. No per-component wiring.

```js
const observer = new IntersectionObserver((entries) =>
  entries.forEach((e) => e.isIntersecting && e.target.classList.add("is-inviewport"))
);
document.querySelectorAll("[data-inviewport]").forEach((el) => observer.observe(el));
```

```html
<div data-inviewport="fadein-slideup" class="transition-all duration-700">…</div>
```

**Measured pre-trigger state** (elements below the fold, before scroll):

| Variant | opacity | transform |
|---|---|---|
| `fadein-slideup` | `0` | `translateY(48px)` |
| `fadein-slideright` | `0` | `translateX(-28px)` |

**48px is the number.** Bigger reads as jumpy; smaller reads as broken. Durations
observed: 150/300/500/700/1000ms depending on element size — bigger element, longer
duration. Stagger children at **80ms**.

Framer Motion equivalent:

```tsx
<motion.div
  initial={{ opacity: 0, y: 48 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, margin: "-80px" }}
  transition={{ duration: 0.7, ease: EASE_REVEAL }}
/>
```

## 2. Hero load choreography

The hero does **not** use the scroll system — it fires on load, on its own timeline.

```css
@keyframes revealText { 0% { transform: translate(0, 100%) } 100% { transform: translate(0, 0) } }
@keyframes slideRight { 0% { transform: translate(-128px, 0); opacity: 0 } 100% { transform: translate(0, 0); opacity: 1 } }

.hero__headline-line { animation: revealText 1.5s cubic-bezier(.77,0,.175,1) forwards; }  /* nth-child staggers the delay */
.hero__eyebrow       { animation: slideRight 1s cubic-bezier(.77,0,.175,1) .5s forwards; }
.hero__cta           { animation: slideRight 1s cubic-bezier(.77,0,.175,1) 1.3s forwards; }
```

Each headline line sits in an `overflow: hidden` wrapper and translates up from
`translateY(100%)` — a **mask reveal**, not a fade. Lines stagger ~0.5s apart, then
the eyebrow enters at 0.5s and the CTA at 1.3s. The long CTA delay is deliberate:
the eye finishes the headline before the button asks for a click.

Use the mask reveal on the hero headline only. Applied to every heading, it stops
meaning anything.

## 3. One interaction curve, everywhere

`cubic-bezier(0.4, 0, 0.2, 1)` on every hover, button, card, and nav transition,
at 150–300ms. No per-component easing decisions. This is the single highest
ratio of perceived-quality to effort in the whole list.

## 4. Observer-gated parallax

Parallax that stops computing when off-screen — the listener is attached on enter
and detached on exit, so scroll cost is bounded no matter how many parallax
sections exist.

```js
const onScroll = () => { el.style.transform = `translateY(${window.scrollY * 0.4}px)`; };
new IntersectionObserver(([e]) => {
  e.isIntersecting ? window.addEventListener("scroll", onScroll, { passive: true })
                   : window.removeEventListener("scroll", onScroll);
}).observe(section);
```

`0.4` is the measured multiplier. Pair the drift with a one-shot zoom-out entrance
on the same image — `scale(1.12 → 1)` over 1200ms — so the image both settles and
drifts. Always `{ passive: true }`.

## 5. The 0.3em uppercase token

Every uppercase micro-label carries `letter-spacing: 0.3em` regardless of font
size — measured at 5.4px/18px and 4.8px/16px, both exactly `0.3em`.

```css
.eyebrow { font-size: .75rem; text-transform: uppercase; letter-spacing: .3em; font-weight: 500 }
```

Applies to section eyebrows, nav meta, badges, and nothing else. Uppercase without
generous tracking looks cheap; this one declaration fixes it globally.

## 6. Marquee via the Web Animations API

Duration computed at runtime from content width, so scroll speed stays constant
regardless of how much content is in the track — the thing CSS keyframes cannot do.

```js
track.animate(
  [{ transform: "translateX(0)" }, { transform: "translateX(-50%)" }],
  { duration: track.scrollWidth * 8, iterations: Infinity, easing: "linear" }
);
```

Duplicate the content exactly once and travel `-50%` for a seamless loop.
`easing: "linear"` — any other easing makes a marquee visibly lurch.

## 7. Mobile menu takeover

Full-viewport takeover, items cascading at **exactly 0.05s per item**, and the
hamburger morphs to an X by **animating SVG path `d` values** — not by rotating
two divs. The path morph is what separates it from a bootstrap template.

```tsx
{items.map((item, i) => (
  <motion.li key={item.href}
    initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }}
    transition={{ delay: i * 0.05, duration: 0.4, ease: EASE_REVEAL }} />
))}
```

## 8. The three route transitions

Most sites animate *within* a page and then hard-cut between pages, which throws
away the user's sense of place. These three named transitions fix that. Pick by
asking **what is the relationship between the two views?**

| Transition | Relationship | What the user should feel |
|---|---|---|
| **Continuity** | The same object exists in both views | "That thing moved with me" |
| **Drill** | The new view is *inside* the old one | "I went deeper" |
| **Context** | The new view is a peer or an overlay | "I stayed where I was" |

### Implementation: the native API, no library

**Check your versions before reaching for framework support.** As of Next 16.3
there is no `experimental.viewTransition` config flag, and React 19.2 does not
export `unstable_ViewTransition` — both fail typecheck. Verify with:

```bash
grep -i "viewTransition" node_modules/next/dist/server/config-shared.d.ts
node -e "console.log(typeof require('react').unstable_ViewTransition)"
```

When they aren't there, drive the browser API directly. It needs no framework
support at all:

```tsx
"use client";
import { useRouter } from "next/navigation";

export function useViewTransitionRouter() {
  const router = useRouter();
  return (href: string) => {
    // Progressive enhancement: unsupported browsers just navigate.
    if (!document.startViewTransition || matchMedia("(prefers-reduced-motion: reduce)").matches) {
      router.push(href);
      return;
    }
    document.startViewTransition(() => router.push(href));
  };
}
```

Wrap it in a `Link` that calls `preventDefault()` and delegates — keeping the
real `href` so middle-click, right-click and crawlers still work.

For same-page morphing (a card expanding into a modal), Framer Motion's
`layoutId` remains the better tool. Use both: `layoutId` within a page,
`view-transition-name` across routes.

### 8a. Continuity transition — the shared element

The signature move. A portrait in a grid becomes the hero portrait on the detail
page: the browser interpolates position, size and border-radius between them.

```tsx
// grid card — the name must be UNIQUE per element on screen
<img style={{ viewTransitionName: `portrait-${member.slug}` }} … />

// detail page hero — the SAME name
<img style={{ viewTransitionName: `portrait-${member.slug}` }} … />
```

```css
::view-transition-group(*)      { animation-duration: 520ms; animation-timing-function: cubic-bezier(0.22,1,0.36,1) }
::view-transition-old(root)     { animation: fade-out 180ms ease both }
::view-transition-new(root)     { animation: fade-in  260ms 120ms ease both }
```

**Rules that make or break it:**
- The name must be **unique on the page**. Two elements sharing one name kills
  the whole transition silently. Scope it with an id or slug, never a constant.
- Only ONE element may hold a given name at a time. If a grid and a modal are
  both mounted, remove the name from the one that isn't the visual source.
- Match the aspect ratio and `object-fit` on both ends, or the image visibly
  squashes mid-flight.
- Don't name a container *and* its child — the group animates as a unit; naming
  both fights itself.

### 8b. Drill transition — going a level deeper

The outgoing view recedes slightly and fades; the incoming view rises from
underneath it. Reversed on back-navigation, so the hierarchy stays legible.

```css
::view-transition-old(root) { animation: drill-out 300ms cubic-bezier(0.4,0,1,1) both }
::view-transition-new(root) { animation: drill-in  420ms cubic-bezier(0.22,1,0.36,1) both }

@keyframes drill-out { to   { transform: scale(0.96); opacity: 0 } }
@keyframes drill-in  { from { transform: translateY(24px); opacity: 0 } }
```

Detect direction and swap the keyframes on "back" — a drill that plays forward
in both directions feels wrong without the user being able to say why.

### 8c. Context transition — staying in place

For peers (tab to tab, filter change, overlay open). Nothing travels; the
content cross-fades with a very small vertical offset. **Keep it short — 220ms.**
Anything longer on a peer navigation reads as lag, because the user did not
expect to move.

```css
::view-transition-old(root) { animation: fade-out 140ms ease both }
::view-transition-new(root) { animation: ctx-in   220ms cubic-bezier(0.22,1,0.36,1) both }
@keyframes ctx-in { from { transform: translateY(8px); opacity: 0 } }
```

### Non-negotiable for all three

```css
@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*),
  ::view-transition-old(*),
  ::view-transition-new(*) { animation: none !important }
}
```

And they are **progressive enhancement only**. In a browser without the API the
navigation must still work as an ordinary instant page change — never gate
rendering or routing on the transition resolving.

## 9. Scrollbar and selection

Two declarations nobody expects you to have bothered with:

```css
::-webkit-scrollbar { width: 6px; height: 4px }
::-webkit-scrollbar-track { background: transparent }
::-webkit-scrollbar-thumb { background: var(--brand); border-radius: 9999px }
::selection { background: var(--brand-tint); color: var(--brand-ink) }
```

Cheap, disproportionate craft signal. Add `scrollbar-width: thin` and
`scrollbar-color` for Firefox.

---

## Porting from a dark reference to a light build

Three techniques from the source do **not** survive the canvas change:

1. **Permanently transparent fixed header.** Works on an all-black site; on light
   it becomes white-on-white and the nav disappears. Solidify the header to the
   page ground with a bottom hairline after ~80px of scroll.
2. **Black vignette over photography** for text legibility. On light, use a
   directional scrim — `linear-gradient(to top, rgb(0 0 0 / .65), transparent 60%)`
   — behind the text only, not a full-image darken.
3. **Neon glow numerals / accent glows.** They read as cheap on light. Replace with
   a hairline rule plus a tinted background block.

## Non-negotiable

Every one of these degrades to a 200ms opacity fade under
`prefers-reduced-motion: reduce`. Smooth-scroll libraries must not initialise at
all. Parallax, mask reveals, and preloaders are skipped entirely — not merely
shortened.
