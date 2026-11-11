---
name: elegant-design-with-3d
description: Build a premium, editorial marketing or landing site in the "atelier" style first shipped on the Drezivo landing page. One live WebGL hero scene (three.js, scroll-driven), Lenis smooth scroll + GSAP ScrollTrigger reveals, a first-visit preloader with a real readiness counter, a mosaic page transition with a generated glitter ground, a Didone + geometric-sans type pair on a fluid scale, hand-drawn SVG art instead of stock photos, coded product mockups that load like the real app, bento grids, marquee, before/after storytelling, light paper and dark night sections. Use when the user asks for a landing page, marketing site, hero, "make it elegant / premium / luxury / editorial", "replicate the landing page", preloader, page transitions, scroll animation, or 3D on a public site. For dashboards and internal apps use elegant-design-for-system instead.
---

# Elegant design with 3D (atelier landing system)

The reference implementation is the Drezivo landing page. Its source is copied into
`references/` next to this file so every number below can be checked. Replicate the system and
the discipline, then change the subject matter (the 3D object, the art, the copy) to fit the new
brand. Never copy another company's brand assets.

Load order when the design is not settled yet: `design-md-library` (two or three real systems for
calibration) → `ui-ux-pro-max` (IA, palette, type) → `taste-skill` (anti-generic pass) → this
skill → `impeccable` as the QA gate. `vgldesign` owns any curve not listed here.

## 1. Design tokens: one source of truth

All tokens live in the Tailwind v4 `@theme` block in `globals.css`
(`references/globals-tokens.css`). Components never hardcode a hex or a px size.

**Palette: two grounds, one voltage.** Warm espresso night and ivory paper, with champagne as
the only accent. Every pair is measured; write the ratio in a comment beside the token.

| Token | Hex | Use | Measured |
|---|---|---|---|
| night / night-2 / night-3 | #120e0b / #1b1511 / #261d17 | dark sections, raised dark surfaces | |
| night-line | #3a2e25 | hairlines on night | |
| mist | #b9ada0 | body text on night | 8.7:1 |
| paper / paper-2 | #f5efe6 / #fbf8f3 | light sections | |
| paper-line | #e2d7c8 | hairlines on paper | |
| ink | #1f1712 | text on paper | 15:1 |
| muted | #6b5e53 | secondary text on paper | 5.5:1 |
| champagne | #d4b483 | accent on night, fills | 9.8:1 on night |
| gold | #a07a46 | display type and ornament only | 3.4:1 on paper: never body text |
| gold-ink | #7a5830 | accent text on paper | 5.6:1 |
| champagne-glow / -light | #e2cea9 / #eae3d8 | transition ground | |

**Type pair.** A Didone with an optical-size axis for display (`Bodoni_Moda`, `axes: ['opsz']`,
normal and italic), a geometric sans for reading (`Jost` 400/500), and a handwriting face only
inside "before" artifacts (`Caveat`). Load with `next/font/google` on the layout element and map
them to `--font-atelier-display` / `--font-atelier-body` there (not at `:root`, because next/font
sets its variables on the element that carries the class).

**Fluid scale.** Every size is a `clamp()` from 360px to 1440px, so type and spacing shrink with
the screen with no breakpoint jumps:

```css
--text-at-micro:   clamp(0.6875rem, 0.6696rem + 0.0893vw, 0.75rem);
--text-at-small:   clamp(0.8125rem, 0.7857rem + 0.1339vw, 0.9062rem);
--text-at-body:    clamp(0.9375rem, 0.9196rem + 0.0893vw, 1rem);      /* lh 1.75 */
--text-at-lead:    clamp(1rem, 0.9732rem + 0.1339vw, 1.0938rem);
--text-at-title:   clamp(1.25rem, 1.1071rem + 0.7143vw, 1.75rem);     /* lh 1.2  */
--text-at-subhead: clamp(1.5rem, 1.2143rem + 1.4286vw, 2.5rem);       /* -0.01em */
--text-at-display: clamp(2.0402rem, 1.4464rem + 3.3929vw, 4.5rem);   /* lh 1.02, -0.02em */
--text-at-hero:    clamp(2.125rem, 1.25rem + 5vw, 5.75rem);           /* lh 0.98 */
--spacing-at-section: clamp(5rem, 3.5714rem + 7.1429vw, 10rem);
--spacing-at-stack:   clamp(3rem, 2.1429rem + 4.2857vw, 6rem);
--spacing-at-gutter:  clamp(1.125rem, 0.5893rem + 2.6786vw, 3rem);
```

Coded mockups get their own root size (`--text-at-mock`) and size everything inside in `em`, so
a whole mockup scales as one object.

**Labels.** Uppercase micro labels: `letter-spacing: 0.3em`, weight 500, `--text-at-micro`.
Nothing else is uppercase.

**Buttons.** Pills (`border-radius: 9999px`), `min-height: 3rem`, press `scale(0.97)`, light
button on night, dark button on paper, ghost outline that turns champagne on hover.

## 2. Motion: three curves, declared once

`references/motion-tokens.ts`:

- `EASE_UI = 'power1.inOut'` (CSS `cubic-bezier(0.4,0,0.2,1)`) for hovers and small state changes, 150–300ms.
- `EASE_REVEAL = 'expo.out'` for scroll entrances.
- `EASE_DRAMA = 'power4.inOut'` for the hero, preloader and page transitions only.

Rules: 48px reveal distance, 80ms stagger, 0.3em label tracking. A fourth curve means nobody decided.

### Lenis + GSAP (one ticker)

`references/marketing-motion.tsx`. One Lenis instance (`lerp: 0.085`, `autoRaf: false`,
`anchors: true`, `prevent` dialogs and `[data-lenis-prevent]`), driven by `gsap.ticker`, with
`lenis.on('scroll', ScrollTrigger.update)` and `lagSmoothing(0)`. Keep the instance in a module
variable (`setLenis`) so transitions can stop it, resize it and jump without smoothing.

Lessons that cost real bugs:
- Do **not** pass a Lenis `offset` when sections have `scroll-margin-top`: Lenis already subtracts
  it, and both together land anchors under the header.
- After a client navigation call `lenis.resize()` before `scrollTo`, or the old page's height
  clamps the jump short.
- Re-run `ScrollTrigger.refresh()` about 400ms after binding: fonts, images and the canvas move
  trigger positions.

### Declarative reveals (pages stay server components)

Bind from data attributes, never per-component wiring:

| Attribute | Effect |
|---|---|
| `data-at-reveal="up"` | fade in from 48px below, `ScrollTrigger.batch`, start `top 88%` |
| `data-at-reveal="blur"` | out of a 12px blur and `scale(0.98)` (images, mockups) |
| `data-at-reveal="lines"` + `[data-at-line]` | each line rises out of an overflow mask, `EASE_DRAMA`, 1.3s, 0.12 stagger |
| `data-at-stagger` > `data-at-item` | children 80ms apart |

Hidden start states exist only under `html.at-motion`, which an inline script adds **before
first paint** when reduced motion is not requested. No JavaScript or reduced motion means
everything is simply visible. Mark bound elements `data-at-bound` and give unbound ones a CSS
fallback so nothing can stay hidden forever.

## 3. First-visit preloader

`references/preloader.tsx`, `PRELOAD_SCRIPT` in `references/page-transition.tsx`.

- Shown once per tab (`sessionStorage` flag). The inline script decides `at-preload` versus
  `at-hero-go` before paint, so there is no flash.
- The counter follows **real readiness**, not a timer: fonts → 35, window load → 70, the 3D
  scene's first frame → 100. `MIN_SHOW_MS = 1200`, `MAX_WAIT_MS = 2800`: decoration never
  blocks a page.
- Intro: the brand mark rises from the hem with `clip-path: inset(100% 0 0 0)` → `inset(0)` and
  a `brightness(1.7)` catch-light, letters of the wordmark rise 0.045s apart, meta fades in.
- Exit hands over to the mosaic reveal, then fires `at:revealed` so the hero choreography starts.
- Scroll is locked while it shows (`lenis.stop()`; plain `overflow:hidden` without Lenis).

## 4. Page transition: the mosaic

`references/page-transition.tsx` + `.at-mosaic` in `references/atelier.css`.

- A fixed grid of blocks sized by CSS breakpoints (5×11 phone, 8×9 tablet, 12×8 desktop) so the
  server renders the right grid and nothing re-grids (re-gridding counted as layout shift).
- Click capture on internal links (capture phase, before Next's `Link`), skip modified clicks,
  other origins, `target`, `download` and same-page anchors.
- Cover: blocks appear in random order (`stagger: { amount: 0.42, from: 'random' }`). Push the
  route, wait for two frames after the new pathname renders, `resetScroll(hash)`, then reveal:
  blocks clear randomly while `main` sharpens out of `blur(10px)` (`html.at-entering/at-entered`).
- **Ground must contrast with every section.** Night holds the preloader; navigations use a
  glittering champagne sheet generated as inline SVG data URIs (fine specks + coarse four-point
  glints), `background-attachment: fixed` so all blocks are windows onto one sheet, a sweeping
  sheen and an `at-glimmer` keyframe. A hairline inset keeps the block grid visible on paper.
  No image files, nothing to license.
- Reduced motion: links navigate instantly.

## 5. The 3D hero (one canvas, scroll-driven)

`references/atelier-hero.tsx`, `references/scene/*`.

- **One** WebGL renderer and canvas. The backdrop (a domain-warped satin height field with film
  grain, `silk-shader.ts`) is a full-screen triangle drawn first in the same scene, so no second
  context fights for the GPU.
- The subject is the brand mark rebuilt procedurally (lathe/ribbon geometry, `MeshPhysicalMaterial`
  satin, `RoomEnvironment` through `PMREMGenerator`, ACES tone mapping, sRGB output). No
  downloaded models.
- The story is driven by scroll: the section is 200vh with a sticky inner frame; ScrollTrigger
  progress goes into one uniform (`uProgress`) that moves ribbons, particles (all motion in the
  vertex shader, no per-frame CPU work) and the backdrop light. Copy changes between act one and
  act two.
- Pause rendering when the canvas is off screen (IntersectionObserver) or the tab is hidden.
  Reduced motion renders one settled frame. No WebGL: a CSS poster (`.at-hero-poster`) with
  layered radial gradients. Fade the canvas in when its first frame is ready.
- Rotate meshes inside the scene, never CSS `rotateX/Y` on the canvas (it skews the render).
- Use `img2threejs` to build a new subject and `scrolljack-3d-transitions` for multi-section travel.

## 6. Pictures without stock photos

- Hand-drawn SVG art that inherits `currentColor` (`references/art/pattern-draft.tsx`: a tailor's
  pattern draft with cutting lines, dashed stitch lines, darts, notches, grain arrows on dotted
  paper; `tape-measure.tsx`). Give each SVG `id`s a unique suffix when it can appear twice.
- Product truth: **coded mockups** of the real app (`references/sections/product-bento.tsx`) in the
  app's own theme with illustrative data. They show a shimmer skeleton first and fill in as they
  enter the viewport, the way the real app loads.
- "Before" artifacts drawn in code: ruled notebook paper with handwriting font, a crumpled
  receipt, a yellow sticky note at 2°, missed-call and inquiry chat bubbles
  (`before-after-art.tsx`). "After" panels are the coded app.
- Section backgrounds are never one flat colour across the whole page: alternate paper and
  night, and lay drawn art, grain or a radial glow into a few chosen sections.

## 7. Section patterns

- **Hero**: eyebrow slides in from -48px, headline lines mask-reveal (1.5s drama, 0.5s apart),
  CTA arrives last (about 1.3s) so the eye finishes the headline first; scroll cue line.
- **Marquee**: Web Animations API, duration from `scrollWidth`, content duplicated once,
  `translateX(-50%)`, linear easing (`references/sections/marquee.tsx`).
- **Before → after**: the offer is the hero of the page; give the showcase mockups a larger root
  size (`--text-at-mock-showcase`) and generous space. Don't economise on the product.
- **Bento**: `sm:col-span-2` wide cards mixed with single cards, each a working mockup.
- **How it works**: numbered steps with Didone numerals (`--text-at-numeral`).
- **Plans**: one big Didone price (`--text-at-price`).
- **FAQ**: `<details>` with a drawn plus/minus icon (`.at-faq`), grouped with in-page anchors.
- **Footer**: night ground; make `html`/`body` night too on these pages so overscroll never shows gray.

## 8. Header

Fixed, transparent over the hero, solid after scrolling with a hairline; `data-ground` switches
ink between light and dark sections; nav links underline from left on hover
(`::after` `scaleX`). Anchors use one offset: `scroll-margin-top: 6rem`.

## 9. Responsive

- Fluid tokens do the shrinking; layout changes at 40rem (640px) and 64rem (1024px).
- On phones: CTA rows stack full width, paired cards become a snap carousel
  (`.at-snap-pair`, 86% width, hidden scrollbar), bento collapses to one column, mosaic grid 5 wide.
- Never hijack touch scrolling; Lenis `syncTouch` off on phones.

## 10. Accessibility and performance gates

- Every text pair at least 4.5:1 (3:1 for 24px+). Gold is ornament only on paper.
- `prefers-reduced-motion`: no Lenis, no preloader, no mosaic, no reveals; the 3D renders one frame.
- Visible `:focus-visible` (2px champagne, offset 3px). Thin gold scrollbar and champagne `::selection`.
- One heavy canvas; pause off screen; never block first paint on decoration.
- Verify with Playwright at 390, 768, 1024, 1440 wide: screenshots, console errors, axe, no
  horizontal overflow, anchors landing below the header, the transition on every internal link.

## Checklist

- [ ] Tokens in `@theme` with measured contrast comments; no raw hex in components
- [ ] Display + body fonts via next/font on the layout element
- [ ] Fluid `clamp()` scale for type and spacing
- [ ] Three easing curves only
- [ ] Lenis on the GSAP ticker, no double offset, resize before jumps
- [ ] Declarative reveals with pre-paint hidden states and fallbacks
- [ ] Preloader driven by real readiness, capped, once per tab
- [ ] Mosaic transition on a ground that contrasts with every section
- [ ] One WebGL canvas, paused off screen, CSS poster fallback
- [ ] Art drawn in SVG or code; no stock or hotlinked images
- [ ] Reduced-motion path tested
