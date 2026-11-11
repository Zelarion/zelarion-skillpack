# Stitching Watermelon into a design system

The registry is a set of well-made components that do not yet agree with each other. This
is the work of turning them into a system.

## 1. The palette contract

Every component hardcodes a zinc/neutral dark scale. Footer 16 alone contains
`bg-zinc-950`, `text-zinc-100`, `text-zinc-300/78`, `text-zinc-400/76`, `border-white/10`,
`border-white/11`, and the SVG gradient stops `#52525b` → `#18181b`.

Do not restyle these per-component. Map once, in your theme layer, then keep components
free of literal colours.

| Watermelon literal | Role | Map to |
|---|---|---|
| `bg-zinc-950` | page/section ground | `--background` |
| `bg-black/1`, `backdrop-blur-xs` | translucent panel | your glass surface token |
| `text-zinc-50`, `text-zinc-100` | primary text | `--foreground` |
| `text-zinc-300/78`, `text-zinc-300/80` | secondary text | `--muted-foreground` |
| `text-zinc-400/76` | tertiary / legal | `--muted-foreground` at lower alpha |
| `border-white/10`, `border-white/11` | hairline | your border/hairline token |
| `#52525b → #18181b` | wordmark gradient | brand ramp, top to bottom |
| `bg-[#AD46FF]`, `bg-[#00B8DB]`, `bg-[#2B7FFF]` (carousel) | categorical accents | your accent set — do **not** keep these |

`border-white/10` and `border-white/11` in the same component are not a decision, they are
a typo someone shipped. Collapse to one hairline token.

**Rule:** after mapping, grep the installed components for `zinc-`, `#`, and `white/`. Any
hit is either a token you missed or a deliberate exception you should write down.

## 2. Motion

Watermelon ships four spring variants in Footer 16 alone:

```
wordmark  spring, duration 1.1,  bounce 0
rise      spring, duration 0.65, bounce 0
link      spring, duration 0.42, bounce 0
stagger   0.1 children / 0.045 list children
```

Plus `duration-200 ease-out` on hovers and `active:scale-[0.96]` on presses.

That is coherent *within* the component and unrelated to whatever your product already
uses. `vgldesign` exists to prevent exactly this accumulation: three named curves, every
animation names one.

**Resolution:** translate Watermelon's springs onto your named curves. The shapes worth
keeping are the *relationships*, not the numbers — big element slow, small element fast,
list children staggered at roughly a tenth of the parent's duration. The `bounce: 0`
choice is right and should survive: bouncy springs read as playful, and this kit is not.

Keep `active:scale-[0.96]` — a press that acknowledges itself is worth more than most
scroll animation.

## 3. Composition rules

**One component per job.** The kit ships two tab components (Continuous, Fluid), and
several base components that duplicate stock shadcn/ui. Two ways to do the same thing is
how a component library becomes a junk drawer. Choose per job, delete the loser.

**Density is inconsistent.** Footer 16 uses `text-sm`/`text-md` with `font-light` and
`font-normal`; Edit Profile uses `text-[22px]`/`text-[26px]` with `font-extrabold` and
rounded-[40px] cards. Those are two different products. Pick your density and typographic
weight range, then bring each component to it — this is the single biggest source of
"looks bolted on".

**Radius.** Edit Profile uses `rounded-[40px]` and `rounded-full`; other components use
standard scale values. Set one radius scale and apply it.

## 4. Accessibility, already partly handled

Credit where due — the kit does several things right, and you should not undo them:

- Real `aria-label` on icon-only controls and social links
- `aria-hidden` on decorative layers (background, ghost wordmark)
- `min-h-10` / `min-h-5` on tap targets — though `min-h-5` (20px) is **well under the
  44px minimum**. Raise it.
- Semantic `<nav aria-label="Footer navigation">`, `<footer>`, `<ul>` for link lists

What it does **not** handle: `prefers-reduced-motion`. Every `motion` animation runs
regardless. Add a reduced-motion path before shipping — animation someone cannot turn off
is an accessibility failure, not a flourish.

## 5. Adoption order

1. **Audit first** (`taste-skill:redesign-skill`) — does this kit suit the product?
2. **Map the palette** in your theme layer. Nothing else until this is done.
3. **Install the base layer** — navigation, footer, and only the base components you do
   not already have from stock shadcn/ui.
4. **Normalise** type scale, weight range, and radius across what you installed.
5. **Translate motion** onto your named curves; record deliberate exceptions.
6. **Add animated components one at a time**, when a screen needs one. Never install the
   set speculatively.
7. **QA** (`impeccable`) — and specifically check reduced motion, 44px targets, and that
   no literal `zinc-` survived.

## 6. Done means

- No literal colour outside the theme layer
- One tab component, one button, one icon system
- Every animation names a curve from your motion language
- `prefers-reduced-motion` respected everywhere
- Every interactive target ≥44px
- No third-party CDN in the render path
