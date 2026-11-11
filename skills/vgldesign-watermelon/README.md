# Watermelon Kit — design system template

The Watermelon component registry (`registry.watermelon.sh`) documented as a reusable
system: what exists, what it costs to install, and what has to change before any of it
belongs in a branded product.

## Files

| File | What it is |
|---|---|
| `references/registry.md` | Every component with its install command, props, and usage |
| `references/design-system.md` | **Start here.** Token mapping, motion resolution, composition rules, adoption order |
| `references/dependencies.md` | What each component drags in, and the icon-system decision |
| `references/footer-16.md` | Full captured source of Footer 16, plus its known defects |

## Install

```bash
npx shadcn@latest add https://registry.watermelon.sh/r/<component>.json
```

Components land as editable source, not as a dependency — so everything below is
changeable, and most of it needs changing.

## The one thing to know

**These components hardcode a zinc/neutral dark palette.** Footer 16 alone carries
`bg-zinc-950`, `text-zinc-300/78`, `border-white/10`, and the gradient stops
`#52525b → #18181b`. Installed unchanged into a branded product, the result looks like a
different site bolted onto the end of yours.

Map the palette to your tokens **once, in the theme layer**, before shipping any of it.
`design-system.md` has the mapping table.

## Adoption order

1. Audit whether this kit suits the product at all
2. Map the palette
3. Install the base layer — and skip anything stock shadcn/ui already gives you
4. Normalise type scale, weight range, and radius
5. Translate the components' springs onto your own motion curves
6. Add animated components one at a time, when a screen needs one
7. QA: reduced motion, 44px targets, no surviving literal colours

## Known gaps, stated plainly

- **12 base components were listed without registry URLs** (Button, Tabs, Pagination,
  Card, Dialog, Dropdown Menu, Form, Input OTP, Sheet, Sonner, Table). `registry.md`
  guesses slugs from the registry's naming convention but they are **unverified**.
- **`command-search` was recorded without the `/r/` path segment** that every other
  component uses. The corrected form is in `registry.md`.
- **No component ships a `prefers-reduced-motion` path.** Add one.
- **Three icon libraries across one kit** — `react-icons` (six families), `lucide-react`,
  and `@hugeicons`. Pick one before adopting broadly.
- Only Footer 16's source was captured. The other components are documented by install
  command, props, and usage rather than by source.
