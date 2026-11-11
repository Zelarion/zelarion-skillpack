---
name: screenshot-to-code
description: Rebuild a UI to pixel and animation fidelity against a reference — a live URL, a screenshot folder, or both. Use when the task is "make it look exactly like X", "1:1 with the design", "match the reference", cloning a deployed site, or closing visual/animation gaps in an existing build. Measures the reference instead of eyeballing it.
---

# Reference-driven UI fidelity

For rebuilding an interface to match a reference exactly. Named after
`abi/screenshot-to-code`, but this is a different tool for a different job:
that project is a FastAPI + React web app that turns a screenshot into fresh
standalone HTML. This skill edits an **existing** codebase, uses its **existing**
tokens and components, and verifies by **measuring** the reference.

## The rule that makes this work

**A screenshot cannot tell you a transition curve, a scroll threshold, or a
z-index.** If the reference is reachable as a URL, drive it and read
`getComputedStyle`. Pixels are for layout and copy; the DOM is for behaviour.

Guessing `transition: all 0.3s ease` when the reference says
`0.6s cubic-bezier(0.4, 0, 0.2, 1)` produces something that looks approximately
right and feels wrong. Users notice the feel.

## Order of evidence

1. **The live reference, driven with Playwright** — computed styles across state
   changes. Exact, and the only source for motion.
2. **The shipped bundle** — for a deployed site, `curl` the HTML, pull the CSS
   and JS, grep for custom properties and route literals. Gives the complete
   token set in three requests.
3. **Screenshots** — layout, copy, empty states, and anything behind auth that
   you cannot reach.
4. **Memory.** Never. If a value is not in 1–3, go and get it.

## Measuring a state change

```js
const PROPS = ["position","top","transform","backgroundColor","backdropFilter",
  "borderRadius","boxShadow","borderColor","borderWidth","transition","opacity",
  "padding","height","zIndex"];

async function snap(page) {
  return page.evaluate((props) => {
    // match on text, then WALK UP — see the trap below
    const inner = [...document.querySelectorAll("div,header,nav")]
      .filter(e => /YOUR ANCHOR TEXT/.test(e.innerText || "") && (e.innerText||"").length < 600)
      .pop();
    const out = []; let el = inner;
    for (let i = 0; i < 6 && el; i++) {
      const cs = getComputedStyle(el), r = el.getBoundingClientRect();
      const o = { lvl: i, tag: el.tagName, cls: String(el.className).slice(0, 70),
                  rect: { y: +r.y.toFixed(1), w: +r.width.toFixed(1), h: +r.height.toFixed(1) } };
      for (const k of props) o[k] = cs[k];
      out.push(o); el = el.parentElement;
    }
    return out;
  }, PROPS);
}

const before = await snap(page);
await page.evaluate(() => window.scrollTo(0, 700));
await page.waitForTimeout(1600);          // longer than the transition
const after = await snap(page);
// print ONLY the properties that differ, per level
```

### The ancestor trap

Matching an element by its text almost always lands on an inner flex row with
`position: static`, no background and no radius. The element carrying the
treatment is typically **two or three levels up**.

Always walk the chain and print every level. A first measurement that reports
"nothing changes on scroll" is nearly always this mistake, not a static design.

### Waiting

Wait longer than the transition you are measuring, or you capture a midpoint and
record an interpolated value as if it were the final state. If you want the
midpoint deliberately — to detect an entrance animation — sample at ~100ms and
again after it settles, and say which is which.

## Applying what you measured

- **Copy the exact values.** `blur(28px) saturate(1.6)`, not "a blur".
- **Multi-layer shadows are load-bearing.** Inset layers create a lit top edge
  and a grounded bottom edge. Collapsing four layers into one flattens the shape.
- **Transparent + backdrop-filter is not the same as a tinted background.**
  Faking glass with a solid tint is the most common way a clone reads as cheap.
- **Respect the host project's tokens.** Map a measured colour onto an existing
  custom property. If none matches, say so rather than pasting a raw hex — an
  unexplained hex is how a design system rots.
- **Never invent copy.** Transcribe it, including the source's typos and
  capitalisation. If the reference misspells a word, the clone misspells it.

## Verifying

Re-measure. The same script that produced the delta is the test.

```
FAIL  borderRadius   ref 22px      ours 9999px
FAIL  backdropFilter ref blur(28px) saturate(1.6)   ours none
ok    zIndex         100000
```

Then **open the screenshot and look at it.** Both checks are required and
neither substitutes for the other: computed styles pass while the layout is
visibly broken, and a screenshot looks fine while the easing is wrong.

Reporting a layout fixed without opening the image is the single most common
failure in this work.

## Watch for build-time interference

A declaration present in source is not necessarily present in the browser.
Bundlers prune. Lightning CSS, which Tailwind v4 and several frameworks run,
silently drops `backdrop-filter` and other declarations it judges unsupported by
its targets — the rule still ships, minus those lines.

When a style is in the source but computes to `none`, read the **served** rule
before assuming a selector or specificity problem:

```js
for (const sh of document.styleSheets) {
  for (const rule of sh.cssRules) {
    if (/\.your-class\b/.test(rule.selectorText || "")) console.log(rule.cssText);
  }
}
```

If the declaration is missing from `cssText`, the build removed it. Wrapping it
in `@supports` is usually the fix, and is exactly how Tailwind protects its own
backdrop utilities.

## Scope discipline

Fidelity work is not redesign work. Do not improve the reference — match it.
When something in the reference looks like a mistake, reproduce it and note it;
the decision to deviate belongs to whoever owns the design, not to the person
cloning it.
