# Watermelon registry — component index

All installs use the shadcn CLI. Components arrive as editable source in your project.

```bash
npx shadcn@latest add https://registry.watermelon.sh/r/<name>.json
```

---

## Base layer

Install these first. They set structure; the animated set decorates it.

| Component | Install | Status |
|---|---|---|
| **Navigation** | `npx shadcn@latest add https://registry.watermelon.sh/r/navigation-2.json` | confirmed |
| **Footer 16** | `npx shadcn@latest add https://registry.watermelon.sh/r/footer-16.json` | confirmed — source in `footer-16.md` |
| Button | `.../r/button.json` *(name unverified)* | **URL not captured** |
| Tabs | `.../r/tabs.json` *(name unverified)* | **URL not captured** |
| Pagination | `.../r/pagination.json` *(name unverified)* | **URL not captured** |
| Card | `.../r/card.json` *(name unverified)* | **URL not captured** |
| Dialog | `.../r/dialog.json` *(name unverified)* | **URL not captured** |
| Dropdown Menu | `.../r/dropdown-menu.json` *(name unverified)* | **URL not captured** |
| Form | `.../r/form.json` *(name unverified)* | **URL not captured** |
| Input OTP | `.../r/input-otp.json` *(name unverified)* | **URL not captured** |
| Sheet | `.../r/sheet.json` *(name unverified)* | **URL not captured** |
| Sonner | `.../r/sonner.json` *(name unverified)* | **URL not captured** |
| Table | `.../r/table.json` *(name unverified)* | **URL not captured** |

> The base components were listed by name without registry URLs. The guessed slugs above
> follow the registry's own convention but are **not verified** — check
> `registry.watermelon.sh` before relying on them. Several of these (Button, Card, Dialog,
> Form, Sheet, Sonner, Table) also exist in stock shadcn/ui; if your project already has
> them, prefer the ones you have rather than introducing a second Button.

---

## Animated layer

Add individually, when a screen needs one.

### Actions

| Component | Install |
|---|---|
| **Morphing Button** — collapses a CTA into an inline email capture | `npx shadcn@latest add https://registry.watermelon.sh/r/morphing-button.json` |
| **Timed Undo Action** — destructive action with a countdown and cancel | `npx shadcn@latest add https://registry.watermelon.sh/r/time-undo-action.json` |

```tsx
// Morphing Button
<MorphingButton buttonText="Notify Me" onSubmit={(email) => {/* ... */}} />

// Timed Undo — pairs naturally with a real delete endpoint
<TimedUndoAction initialSeconds={10} deleteLabel="Delete Account" undoLabel="Cancel Deletion" />
```

The undo pattern is worth more than it looks: it converts an irreversible action into a
reversible one for the window that matters, which is a better UX answer than a confirm
dialog. Make sure the server honours the delay — a countdown that has already fired the
delete is theatre.

### Content

| Component | Install |
|---|---|
| **Minimal Carousel** — card stack, per-card colour and icon | `npx shadcn@latest add https://registry.watermelon.sh/r/minimal-carousel.json` |
| **Pin Item** — pinnable list rows | `npx shadcn@latest add https://registry.watermelon.sh/r/pin-item.json` |
| **Tags** — selectable tag cloud | `npx shadcn@latest add https://registry.watermelon.sh/r/tags.json` |

```tsx
<MinimalCarousel cards={CARDS} onCopyClick={fn} onCustomizeClick={fn} />
// CarouselCard: { id, title, value, color: "bg-[#AD46FF]", icon: IconComponent }

<PinItemComponent items={items} />
// item: { id, name, type, status, icon, pinned }

<Tags tags={[{ id: "typescript", label: "Typescript" }]} />
```

### Disclosure

| Component | Install |
|---|---|
| **Task Widget** — progress, subtasks, assignees | `npx shadcn@latest add https://registry.watermelon.sh/r/task-widget-disclosure.json` |
| **Inline Disclosure Menu** — expanding action row | `npx shadcn@latest add https://registry.watermelon.sh/r/inline-disclosure-menu.json` |
| **Filter Disclosure** — expanding filter chips | `npx shadcn@latest add https://registry.watermelon.sh/r/filter-disclosure.json` |

```tsx
<TaskWidget data={{ title, progress, completedCount, totalCount, priority, status, subtasks, assignees }} />
<InlineDisclosureMenu menuItems={items} showDelete onDelete={fn} />
<FilterDisclosure items={[{ id, label, icon }]} />
```

### Input

| Component | Install |
|---|---|
| **Floating Input** — floating-label field | `npx shadcn@latest add https://registry.watermelon.sh/r/floating-input.json` |
| **Inline Edit** — edit-in-place card | `npx shadcn@latest add https://registry.watermelon.sh/r/inline-edit.json` |
| **Edit Profile** — full profile modal | `npx shadcn@latest add https://registry.watermelon.sh/r/edit-profile.json` |
| **Schedule Date** — date-range picker | `npx shadcn@latest add https://registry.watermelon.sh/r/schedule-date.json` |
| **Adaptive Slider** — range with adaptive step | `npx shadcn@latest add https://registry.watermelon.sh/r/adaptive-slider.json` |
| **Command Search** — ⌘K palette | `npx shadcn@latest add https://registry.watermelon.sh/r/command-search.json` ⚠️ |

⚠️ Command Search was recorded as `registry.watermelon.sh/command-search.json`, without
the `/r/` segment every other entry uses. The `/r/` form above is the likely correct one.

```tsx
<FloatingInput label="Email Address" type="email" />
<InlineEditCard title="Event Details" data={data} onDataChange={setData} />
<EditProfile isOpen={open} onClose={fn} initialData={profile} onSave={fn} />
<ScheduleDate onApply={(range) => {}} onCancel={fn} />
<AdaptiveSlider min={100} max={800} step={50} defaultValue={300} />
<CommandSearch items={commandItems} />   // { id, title, section, icon, shortcut?, action }
```

### Navigation

| Component | Install |
|---|---|
| **Continuous Tabs** — text tabs, sliding indicator | `npx shadcn@latest add https://registry.watermelon.sh/r/continuous-tabs.json` |
| **Fluid Tabs** — icon + label, fluid indicator | `npx shadcn@latest add https://registry.watermelon.sh/r/fluid-tabs.json` |

```tsx
<ContinuousTabs tabs={[{ id: "home", label: "Home" }]} />
<FluidTabs tabs={[{ id: "accounts", label: "Accounts", icon: <FaLandmark size={22} /> }]} />
```

Two tab components is one too many for most products. Pick the one that matches your
information density — Fluid where icons aid scanning, Continuous where they would be
decoration — and delete the other rather than leaving both installed.
