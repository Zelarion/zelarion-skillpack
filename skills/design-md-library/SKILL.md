---
name: design-md-library
description: A corpus of 74 real production design systems (Apple, Stripe, Linear, Cursor, Figma, Vercel, Ferrari, Nike, Notion, Claude…) transcribed as structured DESIGN.md files with exact colour tokens, type scales, spacing, radii and motion values. Use when you need a concrete reference for how a real product specifies its design system, when choosing a direction ("make it feel like Linear, not like Bootstrap"), when calibrating a type scale or palette against something that actually shipped, or when you want to see how a category's leaders solve a layout. Trigger with /design-md-library, "show me how X does it", "reference design systems", or any request to ground a design decision in a real example instead of a guess.
---

# design-md-library — 74 shipped design systems, transcribed

Source: [VoltAgent/awesome-design-md](https://github.com/VoltAgent/awesome-design-md).

Each brand lives at `design-md/<brand>/DESIGN.md` with YAML frontmatter carrying
real values — not adjectives. A typical file specifies exact hex tokens, a full
type scale with `fontSize` / `lineHeight` / `letterSpacing` per step, spacing,
radii, shadows and motion.

## Why this exists

Most design guidance is adjectives — "clean", "modern", "premium". Adjectives
do not resolve an argument about whether a heading should be 48px or 56px.
This corpus is the opposite: it is what shipped, written down. Use it to replace
a guess with a citation.

The highest-value use is **calibration**. When a type scale feels wrong but you
cannot say why, open two or three files from the same category and compare the
actual numbers. The gap is usually obvious once it is written as `letterSpacing:
-1.5px` instead of "tighter".

## The 74

**AI / dev tools** — claude · cursor · cohere · composio · elevenlabs · lovable ·
minimax · mistral.ai · nvidia · ollama · opencode.ai · replicate · runwayml ·
together.ai · warp · x.ai · voltagent

**SaaS / infra** — airtable · cal · clickhouse · hashicorp · intercom · linear.app ·
mintlify · miro · mongodb · notion · posthog · raycast · resend · sanity ·
sentry · supabase · superhuman · vercel · webflow · zapier · expo · figma ·
framer · slack

**Commerce / fintech** — binance · coinbase · kraken · mastercard · revolut ·
shopify · stripe · wise

**Consumer** — airbnb · meta · pinterest · spotify · starbucks · uber · nike ·
nintendo-2001 · playstation · theverge · wired

**Automotive / industrial** — bmw · bmw-m · bugatti · ferrari · lamborghini ·
renault · tesla · spacex

**Legacy / archival** — apple · dell-1996 · hp · ibm · clay · vodafone

The archival entries (`dell-1996`, `nintendo-2001`) are genuinely useful — they
show a period aesthetic precisely enough to reproduce deliberately rather than
by vague pastiche.

## How to use it

1. **Pick by problem, not by fame.** Building a dense data product? Read
   `linear.app`, `posthog`, `sentry`. Building a marketing page for a physical
   product? Read `ferrari`, `nike`, `tesla`. Fame is not fit.
2. **Read two or three, never one.** One file invites copying. Three files show
   you the range of valid answers and force an actual decision.
3. **Steal the *structure*, not the *values*.** The useful transferable thing is
   usually the ratio between scale steps, the number of surface levels, or how
   little colour a system uses — not the specific hex.
4. **Quote the file when you make a claim.** "Linear runs a 1.2 modular scale
   with -0.02em tracking above 32px" is checkable. "Linear feels tight" is not.

## The line not to cross

These are real companies' trademarks and brand identities. Reading them to
calibrate your own system is ordinary design practice. Reproducing a brand's
palette, wordmark and type treatment wholesale onto a product that then reads as
that company's is trademark infringement, and building a page that *presents
itself* as one of these companies is off the table regardless of intent.

Use them the way you would use a competitor's shipped site: as evidence about
what works, not as assets to lift.

## Relationship to the other design skills

This is a **reference corpus, not a process**. It decides nothing on its own.

- `ui-ux-pro-max` decides IA, layout, palette, type pairing — cite this corpus
  as evidence while it does.
- `taste-skill` runs the anti-generic pass — this corpus is where you go to
  prove a direction is real rather than templated.
- `impeccable` runs the polish QA — this corpus supplies the target numbers.
- `vgldesign` owns motion and finish — this corpus rarely covers easing in
  depth, so vgldesign's measured curves win on anything with a duration.
