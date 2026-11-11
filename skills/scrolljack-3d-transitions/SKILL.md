---
name: scrolljack-3d-transitions
description: Use when building premium, cinematic, scroll-driven web experiences — programmatic scroll-jack / section-snapping transitions, a single 3D (or motion) object that travels between sections on scroll, z-depth layering so an element sits behind text but above the background, and Lenis + GSAP + Framer Motion + React Three Fiber orchestration. Apply when the user wants "the asset to travel on scroll", "snap between sections", "3D behind the text", or transitions that feel editorial/award-winning rather than typical fade-up webtoon animations. Stack: Next.js/React + Tailwind + Lenis + GSAP + framer-motion + @react-three/fiber.
---

# Cinematic Scroll-Jack + Traveling 3D Transitions

A house standard for **scroll-driven storytelling**: programmatic snap transitions between
full-screen sections, a persistent object (3D mesh or motion element) that **travels**
across stops, and correct **z-depth layering**. This is the opposite of generic
"fade/slide-up on scroll" — it is choreographed, spatial, and continuous.

## When to use
- "Make the [3D/object] travel as I scroll", "move it to the next section".
- "Snap between sections", "scroll-jack", "one section per scroll".
- "Put the 3D behind the text but above the background."
- Any request for premium/editorial/awwwards-grade motion (not typical webtoon fade-ups).

## Non-negotiable rules (learned the hard way)

1. **NEVER apply CSS `rotateX`/`rotateY` (3D rotation) to a `<canvas>` wrapper.**
   Rotating a flat canvas in CSS 3D perspective-skews the *entire render* → the 3D object
   looks distorted/squashed on movement. **Rotate the mesh inside the scene** (R3F
   `useFrame`) driven by a scroll `MotionValue`. CSS `x`/`y`/`scale`/`opacity` on the
   wrapper are safe; CSS `rotate` (2D z) is safe; `rotateX`/`rotateY` are not.

2. **Lock user input at the event level — do NOT call `lenis.stop()`.**
   `lenis.stop()` freezes the engine so programmatic `lenis.scrollTo()` does nothing,
   permanently locking the page. Instead, `e.preventDefault()` wheel/touch/keys while a
   transition is active, and animate scroll programmatically.

3. **One render context per breakpoint.** Don't mount multiple WebGL canvases that
   compete on the main thread — it causes jank (e.g. a slow drawer/menu open) and
   `THREE.WebGLRenderer: Context Lost`. Gate heavy full-screen shaders to desktop; give
   mobile a lightweight CSS fallback. Mount-gate (`{isDesktop && ...}`), don't just
   `display:none` (a hidden canvas still runs its rAF).

4. **Respect `prefers-reduced-motion`** (return the static layout) and **never hijack
   touch scroll on mobile** (it fights system gestures; it's an accessibility
   anti-pattern). Snap-jack is a desktop/pointer affordance; mobile uses natural smooth
   scroll (Lenis `syncTouch`).

## 1. Expose Lenis globally (provider)

```ts
// smooth-scroll.tsx (inside the Lenis init effect)
const lenis = new Lenis({ duration: 1.1, smoothWheel: true, syncTouch: true });
(window as any).lenis = lenis;
lenis.on("scroll", ScrollTrigger.update);
const raf = (t: number) => lenis.raf(t * 1000);
gsap.ticker.add(raf); gsap.ticker.lagSmoothing(0);
// On route change: lenis.scrollTo(0, { immediate: true }) + setTimeout(ScrollTrigger.refresh, 250)
```

## 2. Section anchors + full-screen snap targets
Give each snap section a stable `id` and (on desktop) full height + centered content:
```
className="lg:min-h-screen lg:flex lg:flex-col lg:justify-center"
```
Measure stops as document offsets, re-measuring after late layout (images/fonts) and via
`ResizeObserver(document.body)` — stale stops are the #1 cause of an object "vanishing":
```ts
const measure = () => {
  const a = document.getElementById("industries");
  const b = document.getElementById("values-section");
  if (!a || !b) return;
  setStops({ b: a.getBoundingClientRect().top + scrollY, c: b.getBoundingClientRect().top + scrollY });
};
measure(); setTimeout(measure, 600); setTimeout(measure, 1500);
new ResizeObserver(measure).observe(document.body);
```

## 3. Programmatic snap transition (GSAP + Lenis sync)

```ts
const isTransitioning = useRef(false);
const startTransition = (targetScroll: number, lenis: any) => {
  isTransitioning.current = true;
  const o = { y: window.scrollY };
  gsap.to(o, {
    y: targetScroll, duration: 1.2, ease: "power2.inOut",
    onUpdate: () => { window.scrollTo(0, o.y); lenis.scrollTo(o.y, { immediate: true }); },
    onComplete: () => { isTransitioning.current = false; },
  });
};

// wheel/keydown listeners ({ passive: false }):
const onWheel = (e: WheelEvent) => {
  const lenis = (window as any).lenis; if (!lenis) return;
  if (isTransitioning.current) { e.preventDefault(); return; }
  // determine active section from window.scrollY vs stops (with a ~120px threshold)
  // if inside a snap zone: e.preventDefault(); startTransition(nextStop, lenis);
};
```
Guard: if offsets aren't measured yet (`<= 0`), **don't hijack** — let native scroll run.

## 4. Traveling object (fixed canvas, scroll-driven transforms)

```tsx
const { scrollY } = useScroll();
const x       = useTransform(scrollY, [0, stops.b, stops.c], ["27vw", "-30vw", "0vw"]);
const scale   = useTransform(scrollY, [0, stops.b, stops.c], [1, 1, 1.15]);
const opacity = useTransform(scrollY, [0, stops.b, stops.c, stops.c + 900], [1, 1, 0.5, 0]);
// rotation driven IN 3D (not CSS):
const spin = useTransform(scrollY, [0, stops.c], [0, Math.PI * 2]);

function ScrollSpin({ spin, children }: { spin: MotionValue<number>; children: React.ReactNode }) {
  const ref = useRef<Group>(null);
  useFrame(() => { if (ref.current) ref.current.rotation.y = spin.get(); });
  return <group ref={ref}>{children}</group>;
}

return (
  <div className="pointer-events-none fixed inset-0 z-[5] flex items-center justify-center">
    <motion.div style={{ x, scale, opacity }} className="h-[540px] w-[540px] will-change-transform">
      <Canvas camera={{ position: [0,0,6.5], fov: 42 }} dpr={[1,1.7]} gl={{ alpha: true }}>
        <ambientLight intensity={0.6} />
        <directionalLight position={[5,5,5]} intensity={1.6} />
        <ScrollSpin spin={spin}>{/* meshes */}</ScrollSpin>
      </Canvas>
    </motion.div>
  </div>
);
```
To "make room" at a stop, shift that section's content (e.g. `lg:pl-[30%]`) so the object
isn't covering text.

## 5. Z-depth layering ("behind text, above background")

Target order: **background (z-0) < traveling object (z-[5]) < text/cards (z-10)**.

- Fixed object wrapper: `fixed inset-0 z-[5] pointer-events-none`.
- Section content wrapper: `relative z-10`.
- Section background fill: `absolute inset-0 z-0`.
- **Stacking-context caveat:** a `z-10` child only sits above the `z-[5]` fixed canvas if
  its ancestor chain doesn't trap it in a lower stacking context. Sections that use
  `transform`, `filter`, or `opacity<1` create a new context — if the object must show
  *through*, keep those sections free of transforms, or lift the object's z accordingly.
  Marquees/bands that should pass *in front* of the traveling object get `relative z-10`.

## 6. Performance & a11y checklist
- [ ] Rotation is done in `useFrame`, never CSS `rotateX/rotateY` on the canvas.
- [ ] One WebGL/heavy canvas per breakpoint; mobile uses a CSS fallback; hidden canvases are unmounted, not just `display:none`.
- [ ] `prefers-reduced-motion` returns the static layout (no jack, no travel).
- [ ] Touch scroll is **not** hijacked on mobile.
- [ ] Stops re-measured after load + on resize (object never prematurely fades/vanishes).
- [ ] Transition duration 1.0–1.6s, `power2.inOut`; input locked only while transitioning.
- [ ] Radix Dialog/Sheet has a `Title` + `Description` (or `aria-describedby`).
