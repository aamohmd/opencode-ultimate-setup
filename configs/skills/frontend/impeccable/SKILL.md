---
name: impeccable
description: Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill, harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. Covers websites, landing pages, dashboards, product UI, app shells, components, forms, settings, onboarding, and empty states. Handles UX review, visual hierarchy, information architecture, cognitive load, accessibility, performance, responsive behavior, theming, anti-patterns, typography, fonts, spacing, layout, alignment, color, motion, micro-interactions, UX copy, error states, edge cases, i18n, and reusable design systems or tokens. Also use for bland designs that need to become bolder or more delightful, loud designs that should become quieter, live browser iteration on UI elements, or ambitious visual effects that should feel technically extraordinary. Not for backend-only or non-UI tasks.
version: 3.0.6
user-invocable: true
argument-hint: "[craft|shape · audit|critique · animate|bolder|colorize|delight|layout|overdrive|quieter|typeset · adapt|clarify|distill · harden|onboard|optimize|polish · teach|document|extract|live] [target]"
license: Apache 2.0. Based on Anthropic's frontend-design skill. See NOTICE.md for attribution.
allowed-tools:
  - Bash(npx impeccable *)
---

Designs and iterates production-grade frontend interfaces. Real working code, committed design choices, exceptional craft.

## Setup (non-optional)

Before any design work or file edits, pass these gates. Skipping them produces generic output that ignores the project.

| Gate | Required check | If fail |
|---|---|---|
| Context | The PRODUCT.md / DESIGN.md loader result is known from `node .claude/skills/impeccable/scripts/load-context.mjs`. | Run the loader before continuing. |
| Product | PRODUCT.md exists and is not empty or placeholder (`[TODO]` markers, <200 chars). | Run `/impeccable teach`, refresh context, then resume. Never synthesize PRODUCT.md from the user's original prompt alone. |
| Command | The matching command reference is loaded when a sub-command is used. | Load the reference before continuing. |
| Craft | `/impeccable craft` has a user-confirmed shape brief for this task. `teach` / PRODUCT.md never counts as shape. | Run `/impeccable shape` and wait for explicit brief confirmation. |
| Image | Required visual probes / mocks are generated or skipped with a reason. | Resolve the image-generation gate in `shape.md` or `craft.md` before code. |
| Mutation | All active gates above pass. | Do not edit project files yet. |

## Shared design laws

Apply to every design, both registers. Match implementation complexity to the aesthetic vision — maximalism needs elaborate code, minimalism needs precision.

### Color

- Use OKLCH. Reduce chroma as lightness approaches 0 or 100 — high chroma at extremes looks garish.
- Never use `#000` or `#fff`. Tint every neutral toward the brand hue.
- Pick a **color strategy**: Restrained, Committed, Full palette, or Drenched.

### Typography

- Cap body line length at 65–75ch.
- Hierarchy through scale + weight contrast (≥1.25 ratio between steps). Avoid flat scales.

### Layout

- Vary spacing for rhythm. Same padding everywhere is monotony.
- Cards are the lazy answer. Use them only when they're truly the best affordance. Nested cards are always wrong.

### Motion

- Don't animate CSS layout properties.
- Ease out with exponential curves (ease-out-quart / quint / expo). No bounce, no elastic.

### Absolute bans

- Side-stripe borders.
- Gradient text.
- Glassmorphism as default.
- The hero-metric template.
- Identical card grids.
- Modal as first thought.

### The AI slop test

If someone could look at this interface and say "AI made that" without doubt, it's failed.

## Commands

| Command | Category | Description |
|---|---|---|
| `craft [feature]` | Build | Shape, then build a feature end-to-end |
| `shape [feature]` | Build | Plan UX/UI before writing code |
| `teach` | Build | Set up PRODUCT.md and DESIGN.md context |
| `critique [target]` | Evaluate | UX design review with heuristic scoring |
| `audit [target]` | Evaluate | Technical quality checks (a11y, perf, responsive) |
| `polish [target]` | Refine | Final quality pass before shipping |
| `bolder [target]` | Refine | Amplify safe or bland designs |
| `quieter [target]` | Refine | Tone down aggressive or overstimulating designs |
| `distill [target]` | Refine | Strip to essence, remove complexity |
| `harden [target]` | Refine | Production-ready: errors, i18n, edge cases |
| `onboard [target]` | Refine | Design first-run flows, empty states |
| `animate [target]` | Enhance | Add purposeful animations and motion |
| `colorize [target]` | Enhance | Add strategic color to monochromatic UIs |
| `typeset [target]` | Enhance | Improve typography hierarchy and fonts |
| `layout [target]` | Enhance | Fix spacing, rhythm, and visual hierarchy |
| `delight [target]` | Enhance | Add personality and memorable touches |
| `overdrive [target]` | Enhance | Push past conventional limits |
| `clarify [target]` | Fix | Improve UX copy, labels, and error messages |
| `adapt [target]` | Fix | Adapt for different devices and screen sizes |
| `optimize [target]` | Fix | Diagnose and fix UI performance |
| `live` | Iterate | Visual variant mode |