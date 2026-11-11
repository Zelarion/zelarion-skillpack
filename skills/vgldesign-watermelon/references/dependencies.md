# Dependency map — check before installing

Watermelon components are editable source, but their imports are not. Installing one
component can add three packages. Below is what the captured demos actually import.

## Packages

| Package | Pulled in by | Notes |
|---|---|---|
| `motion` (imported as `motion/react`) | Footer 16, and most animated components | This is Motion, the successor to Framer Motion. The import path is `motion/react`, **not** `framer-motion`. If your project already has `framer-motion`, you now have two animation libraries — pick one. |
| `react-icons` | Footer 16 (`fa6`), Minimal Carousel (`vsc`, `bs`, `fa`), Pin Item (`io5`, `fa6`), Filter Disclosure (`fa`, `io5`, `bs`, `ri`), Fluid Tabs (`bi`, `fa`) | Six icon families across the kit. Tree-shakes per-icon, but it is a second icon system if you are already on `lucide-react`. |
| `lucide-react` | Morphing Button demo, Command Search, Edit Profile | Already standard in shadcn projects. |
| `@hugeicons/react` + `@hugeicons/core-free-icons` | Inline Disclosure Menu | A **third** icon system, for one component. Consider swapping its four icons for `lucide-react` equivalents rather than adding the package. |

## Local imports the components expect

| Import | Component | What to do |
|---|---|---|
| `@/assets/logo-icon` | Footer 16 | Provide your own `LogoIcon` component at that path, or edit the import. It is rendered at `size-8` with a `-translate-y-2` nudge. |

## Remote assets

| URL | Component | Risk |
|---|---|---|
| `https://assets.watermelon.sh/footer-16-bg.avif` | Footer 16 background | Third-party CDN in your render path. Blocked outright by a strict CSP. Download it and serve locally, or substitute your own. AVIF has good but not universal support — check your browser floor. |

## Icon-system decision

Three icon libraries across one kit is not a design system, it is an accident of whoever
wrote each demo. Before adopting broadly, pick **one** and rewrite the imports:

- Already on `lucide-react`? Keep it. Most Watermelon icons have direct equivalents.
- Want the brand marks (`FaFacebookF`, `FaXTwitter`, `FaLinkedinIn`)? `react-icons/fa6`
  earns its place for social icons specifically — `lucide` covers fewer brands.

A defensible split is `lucide-react` for UI glyphs and `react-icons/fa6` for brand marks
only. Drop `@hugeicons` unless you are using far more of it than one menu.

## Before you install

1. Do you already have this component in stock shadcn/ui? Prefer what you have.
2. Does it add a package you do not have? Is one component worth it?
3. Does it hardcode colours? (It does — see `design-system.md`.)
4. Does it ship its own motion timings that conflict with your motion language?
