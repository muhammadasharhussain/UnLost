---
name: uiux-pro-max
description: >-
  Professional Flutter UI/UX design skill for the Lost & Found app.
  Activate this skill when the user asks to design, create, or refactor any
  Flutter screen, widget, component, or design system. It enforces premium
  design standards including glassmorphism, bento grids, 150+ curated colour
  palettes, 50+ font pairings, Material Design 3 best practices, and 100+
  UX guidelines — elevating every UI output from tutorial-grade to
  production-grade.
---

# UI/UX Pro Max — Flutter Design Skill

This skill governs all UI/UX decisions made for the **Lost & Found** Flutter app.
Activate it for any task that involves: screens, widgets, themes, animations,
typography, spacing, colour systems, or design tokens.

---

## Core Design Philosophy

1. **Premium First** — Every UI output must feel production-grade, not tutorial-grade.
2. **Consistency** — All components must use tokens from the app's `ThemeData`.
3. **Motion is Meaning** — Prefer subtle micro-animations over static screens.
4. **Accessible by Default** — Meet WCAG AA contrast; support semantic labels.
5. **Mobile-First, Responsive Always** — Use `LayoutBuilder` / `MediaQuery` for
   adaptive layouts.

---

## Design Vocabulary

### Styles (choose the one that best fits the screen's mood)
| Style | When to use |
|---|---|
| **Glassmorphism** | Hero/splash screens, overlays, cards |
| **Bento Grid** | Dashboard or category overview |
| **Neumorphism** | Settings, toggle controls |
| **Flat Minimal** | Lists, detail views |
| **Dark Gradient** | AI/Groq-powered feature screens |

### Colour Palettes
Always derive from HSL — never use raw web colour names.

Recommended palettes for this app:
- `Deep Indigo + Amber Accent` — authority + urgency (report-lost flow)
- `Teal + Off-white` — trust + clarity (found-item browsing)
- `Slate + Electric Blue` — tech feel (AI-assisted search/Groq screens)
- `Warm Charcoal Dark mode` — default app shell

### Typography Pairings
| Role | Font | Weight |
|---|---|---|
| Display / Hero | `Outfit` | 700 |
| Headings | `Inter` | 600 |
| Body | `Inter` | 400 |
| Monospace / AI output | `JetBrains Mono` | 400 |

Add fonts via `pubspec.yaml` assets or `google_fonts` package when needed.

### Spacing & Sizing System
Use a base-8 grid: `4, 8, 12, 16, 24, 32, 48, 64`.
Define spacing as constants (e.g., `AppSpacing.md = 16.0`) — never magic numbers.

---

## UX Guidelines (key rules)

- **Empty states**: Always design a friendly, illustrative empty state — never a
  blank screen.
- **Loading states**: Use shimmer skeletons, not `CircularProgressIndicator` alone.
- **Error states**: Show inline error messages with a clear recovery action.
- **Touch targets**: Minimum 48×48 dp for all interactive elements.
- **Hierarchy**: One primary CTA per screen; use size + colour + weight to
  establish visual hierarchy.
- **Feedback**: Every tap/action must give immediate visual feedback (ripple,
  scale, or colour shift).

---

## Flutter Implementation Rules

1. Extract every reusable element into its own `StatelessWidget` or
   `StatefulWidget` — no giant `build()` methods.
2. Define all colours, fonts, and radii in `ThemeData` — never inline.
3. Use `AnimatedContainer`, `AnimatedOpacity`, or `TweenAnimationBuilder`
   for micro-animations; avoid third-party animation libraries unless
   truly necessary.
4. Use `BoxDecoration` + `BoxShadow` + `BorderRadius` to replicate CSS
   effects (shadows, gradients, glass blur via `BackdropFilter`).
5. Check Uiverse.io (see `uiverse` rule) for visual inspiration before
   designing; translate CSS concepts to Flutter equivalents.

---

## How to Use This Skill

When asked to build a UI:
1. Identify the screen's purpose and choose an appropriate style from the
   vocabulary above.
2. Select a matching palette and font pair.
3. Draft the widget tree structure before writing code.
4. Apply spacing constants and theme tokens throughout.
5. Add at least one micro-animation per interactive element.
6. Verify: empty state, loading state, error state are all handled.
