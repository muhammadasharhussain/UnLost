# Uiverse Design Reference

> **Uiverse.io** is a community-driven CSS/HTML component gallery used in this
> project as a **visual inspiration and design-translation reference** for the
> Flutter UI. Do not copy its code verbatim — translate its visual concepts
> into Flutter widgets.

---

## How to Use Uiverse in This Project

1. **Browse for inspiration**: Visit [https://uiverse.io](https://uiverse.io) to
   find buttons, cards, loaders, toggles, and other UI patterns.
2. **Identify the visual concept**: Look at the CSS properties being used
   (shadow, gradient, border-radius, animation keyframes, etc.).
3. **Translate to Flutter** using the mapping table below.
4. **Apply UI/UX Pro Max rules** (see `.agents/skills/uiux-pro-max/SKILL.md`)
   to any widget derived from a Uiverse inspiration.

---

## CSS → Flutter Translation Reference

| CSS Concept | Flutter Equivalent |
|---|---|
| `box-shadow` | `BoxDecoration(boxShadow: [BoxShadow(...)])` |
| `border-radius` | `BorderRadius.circular(x)` |
| `background: linear-gradient(...)` | `LinearGradient` in `BoxDecoration` |
| `backdrop-filter: blur(x)` | `BackdropFilter(filter: ImageFilter.blur(...))` |
| `@keyframes` animation | `AnimationController` + `Tween` |
| `transition: all 0.3s ease` | `AnimatedContainer` / `AnimatedOpacity` |
| `opacity` | `Opacity` widget or `AnimatedOpacity` |
| `transform: scale(x)` | `Transform.scale(scale: x)` |
| `overflow: hidden` | `ClipRRect` / `ClipOval` |
| `:hover` state | `InkWell` + `onHover` / `MouseRegion` |

---

## Design Categories to Watch on Uiverse

Focus on these categories that are relevant to the Lost & Found app:

- **Buttons** — CTA, submit, danger/alert actions
- **Cards** — item listings, found/lost post cards
- **Inputs** — search bars, text fields, tags
- **Loaders** — skeleton screens, spinners for API calls
- **Badges** — status indicators (Claimed, Unclaimed, Expired)
- **Modals / Overlays** — confirmation dialogs, image previews

---

## Rules

- Uiverse is a **reference only** — never import web/CSS code directly.
- Always check if a similar Flutter package already exists before
  hand-translating a complex animation.
- Document the Uiverse source URL in a comment above any widget directly
  inspired by it (e.g., `// Inspired by: https://uiverse.io/...`).
