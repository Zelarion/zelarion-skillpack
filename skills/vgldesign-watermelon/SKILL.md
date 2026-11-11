---
name: vgldesign-watermelon
description: The Watermelon component registry (registry.watermelon.sh) as a usable design system — install commands, source, dependency map, and the token remapping needed before any of it belongs in a branded product. Use when adding a Watermelon component, when building a UI from this kit, when someone says "watermelon", "morphing button", "fluid tabs", "footer-16", or when a shadcn registry URL points at watermelon.sh. Pairs with vgldesign for motion and taste-skill for direction.
---

# Watermelon registry — component kit and design system

Source: `https://registry.watermelon.sh`. Installs through the standard shadcn CLI, so
components land in your project as editable source, not as a dependency.

```bash
npx shadcn@latest add https://registry.watermelon.sh/r/<component>.json
```

`references/registry.md` is the full component index with every install command.
`references/footer-16.md` holds the one component whose source was captured verbatim.

## Read this before installing anything

**These components are built for a zinc/neutral dark palette and they hardcode it.**
Footer-16 alone contains `bg-zinc-950`, `text-zinc-100`, `text-zinc-300/78`,
`border-white/10`, `#52525b`, `#18181b`. Dropped into a branded product unchanged, it
looks like a different site bolted onto the end of yours.

That is the actual work in adopting this kit: **remap the palette to your tokens before
the component ships, not after.** `references/design-system.md` gives the mapping table
and the three decisions that make the set cohere.

**They also pull dependencies your project may not have.** `motion/react`, `react-icons`
(four separate icon families), `@hugeicons/react`. Check `references/dependencies.md`
before you install — one component can add three packages, and `react-icons` in
particular is large if you are already on `lucide-react`.

## How this fits with the other skills

| Layer | Owns |
|---|---|
| `taste-skill:redesign-skill` | whether this kit suits the product at all — audit first |
| `design-md-library` | what real systems specify, for calibrating the palette you map to |
| **this skill** | **the components, their install commands, their dependency cost** |
| `vgldesign` | motion — and it overrules any easing these components ship with |
| `impeccable` | the QA gate, before and after |

**Motion conflicts are resolved in vgldesign's favour.** Watermelon components carry their
own springs (`type: 'spring', duration: 1.1, bounce: 0`) and durations. vgldesign runs a
three-curve system precisely so a codebase does not accumulate a dozen unrelated timings.
Either translate the component's motion onto a named vgldesign curve, or write down that
this component is a deliberate exception and why. Do not leave both systems running
unacknowledged.

## Two things in the source that will bite

1. **`command-search`'s URL is missing its `/r/` segment.** Every other component is
   `registry.watermelon.sh/r/<name>.json`; that one was recorded as
   `registry.watermelon.sh/command-search.json`. Try the `/r/` form first.
2. **Footer-16 loads a remote background** from `assets.watermelon.sh`. That is someone
   else's CDN in your critical render path, and it will not survive a strict CSP. Download
   the asset and serve it yourself, or replace it.

## Using it as a template

The intended flow is: install the base layer (navigation, footer, button, card, dialog,
form, table), remap tokens once in your theme layer, then add animated components
individually as a screen actually needs them. Installing the whole animated set upfront
gives you a components directory full of things nobody imported.

`references/design-system.md` covers the token contract, the composition rules, and what
to check before calling a screen done.
