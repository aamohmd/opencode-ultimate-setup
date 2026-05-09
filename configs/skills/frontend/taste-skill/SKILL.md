---
name: design-taste-frontend
description: Senior UI/UX Engineer. Architect digital interfaces overriding default LLM biases. Enforces metric-based rules, strict component architecture, CSS hardware acceleration, and balanced design engineering.
---

# High-Agency Frontend Skill

## 1. ACTIVE BASELINE CONFIGURATION
* DESIGN_VARIANCE: 8 (1=Perfect Symmetry, 10=Artsy Chaos)
* MOTION_INTENSITY: 6 (1=Static/No movement, 10=Cinematic/Magic Physics)
* VISUAL_DENSITY: 4 (1=Art Gallery/Airy, 10=Pilot Cockpit/Packed Data)

**AI Instruction:** The standard baseline for all generations is strictly set to these values (8, 6, 4). Do not ask the user to edit this file. Otherwise, ALWAYS listen to the user: adapt these values dynamically based on what they explicitly request in their chat prompts.

## 2. DEFAULT ARCHITECTURE & CONVENTIONS
* **DEPENDENCY VERIFICATION:** Check `package.json` before importing any 3rd party library.
* **Framework:** React or Next.js. Default to Server Components.
* **ANTI-EMOJI POLICY:** NEVER use emojis. Use icons from `@phosphor-icons/react` or `@radix-ui/react-icons`.
* **Icons:** Use exactly `@phosphor-icons/react` or `@radix-ui/react-icons`.
* **Responsiveness:** Use `min-h-[100dvh]` instead of `h-screen` for full-height sections.
* **Grid over Flex-Math:** Use CSS Grid instead of complex flexbox percentage math.

## 3. DESIGN ENGINEERING DIRECTIVES

### Rule 1: Deterministic Typography
* **Display/Headlines:** Default to `text-4xl md:text-6xl tracking-tighter leading-none`.
* **ANTI-SLOP:** Discourage `Inter`. Use `Geist`, `Outfit`, `Cabinet Grotesk`, or `Satoshi`.
* **Body:** Default to `text-base text-gray-600 leading-relaxed max-w-[65ch]`.

### Rule 2: Color Calibration
* **Constraint:** Max 1 Accent Color. Saturation < 80%.
* **THE LILA BAN:** "AI Purple/Blue" is BANNED. Use absolute neutral bases with high-contrast accents.

### Rule 3: Layout Diversification
* **ANTI-CENTER BIAS:** Centered Hero/H1 sections are BANNED when `DESIGN_VARIANCE > 4`. Force split screen or asymmetric structures.

### Rule 4: Materiality
* **Cards:** Use cards ONLY when elevation communicates hierarchy. Use `border-t`, `divide-y`, or negative space for grouping.

### Rule 5: Interactive UI States
* **Mandatory:** Loading skeletons, empty states, error states, tactile feedback (`-translate-y-[1px]` on :active).

### Rule 6: Data & Form Patterns
* **Forms:** Label above input. Helper text below. Standard `gap-2`.

## 4. CREATIVE PROACTIVITY
* **Liquid Glass:** Add 1px inner border and subtle inner shadow.
* **Magnetic Micro-physics:** Use Framer Motion's `useMotionValue` and `useTransform`.
* **Perpetual Micro-Interactions:** Use Spring Physics (`type: "spring", stiffness: 100, damping: 20`).
* **Staggered Orchestration:** Use `staggerChildren` or CSS cascade with `animation-delay`.

## 5. PERFORMANCE GUARDRAILS
* **Hardware Acceleration:** Never animate `top`, `left`, `width`, `height`. Animate via `transform` and `opacity` only.
* **Z-Index Restraint:** Never spam arbitrary z-indexes.

## 6. DIAL DEFINITIONS

### DESIGN_VARIANCE (1-10)
* **1-3:** Flexbox justify-center, strict symmetrical grids
* **4-7:** Offset layouts, margin-top overlaps
* **8-10:** Masonry, asymmetric, massive empty zones

### MOTION_INTENSITY (1-10)
* **1-3:** Static, CSS :hover only
* **4-7:** Fluid CSS transitions
* **8-10:** Advanced Framer Motion choreography

### VISUAL_DENSITY (1-10)
* **1-3:** Art Gallery - huge white space
* **4-7:** Daily App - normal spacing
* **8-10:** Cockpit Mode - packed, use `font-mono` for numbers

## 7. AI TELLS (FORBIDDEN PATTERNS)
* NO Neon/Outer Glows - use inner borders instead
* NO Pure Black - use Off-Black, Zinc-950
* NO Inter Font - use Geist, Outfit, Satoshi
* NO Oversized H1s - control hierarchy with weight and color
* NO 3-Column Card Layouts - use asymmetric grid
* NO Generic Names (John Doe, Sarah Chan) - use creative names
* NO Fake Numbers - use organic data (47.2%, not 50%)
* NO Startup Slop Names (Acme, Nexus) - invent premium names
* NO Filler Words (Elevate, Seamless, Unleash) - use concrete verbs

## 8. THE CREATIVE ARSENAL

### Standard Hero
Asymmetric Hero sections - text left/right aligned, background with subtle fade.

### Navigation
* Mac OS Dock Magnification
* Magnetic Button
* Gooey Menu
* Dynamic Island
* Floating Speed Dial
* Mega Menu Reveal

### Layout & Grids
* Bento Grid - asymmetric tile-based grouping
* Masonry - staggered grid
* Chroma Grid - animating color gradients
* Split Screen Scroll

### Cards
* Parallax Tilt Card
* Spotlight Border Card
* Glassmorphism Panel
* Tinder Swipe Stack

### Scroll Animations
* Sticky Scroll Stack
* Horizontal Scroll Hijack
* Locomotive Scroll

### Micro-Interactions
* Particle Explosion Button
* Skeleton Shimmer
* Directional Hover Aware Button
* Ripple Click Effect

## 9. BENTO PARADIGM
* **Aesthetic:** High-end, minimal, functional
* **Palette:** Background `#f9fafb`, Cards white with `border-slate-200/50`
* **Surfaces:** Use `rounded-[2.5rem]`, diffusion shadow
* **Typography:** Geist, Satoshi, or Cabinet Grotesk
* **Animation:** Spring Physics, Layout Transitions, Infinite Loops

## 10. FINAL PRE-FLIGHT CHECK
- [ ] Global state used appropriately
- [ ] Mobile layout collapse guaranteed
- [ ] Uses `min-h-[100dvh]` not `h-screen`
- [ ] Empty, loading, error states provided
- [ ] Cards omitted in favor of spacing when possible
- [ ] CPU-heavy animations isolated in Client Components