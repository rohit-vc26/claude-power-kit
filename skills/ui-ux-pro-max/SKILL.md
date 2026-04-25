---
name: ui-ux-pro-max
version: 2.0.0
description: "UI/UX design intelligence for web and mobile. Includes 50+ styles, 161 color palettes, 57 font pairings, 161 product types, 99 UX guidelines, and 25 chart types. Automatically reads project DESIGN.md to operate within established design system constraints. Use this skill whenever the user wants to: design new pages, create UI components, choose color schemes or typography, review UI code for UX/accessibility, implement navigation or animations, make product-level design decisions, or improve perceived quality of interfaces. Trigger for ANY request involving UI structure, visual design, interaction patterns, color palettes, font pairing, accessibility review, landing pages, dashboards, or 'make it look better' requests."
allowed-tools:
  - Read
  - Bash
  - Glob
---

## Preamble — Load Project Design System

```bash
# Check for project DESIGN.md (walk up from cwd, check gstack skill too)
_DESIGN=""
for _dir in "$(pwd)" "$(git rev-parse --show-toplevel 2>/dev/null)" "$HOME/.claude/skills/gstack"; do
  [ -f "$_dir/DESIGN.md" ] && _DESIGN="$_dir/DESIGN.md" && break
done

if [ -n "$_DESIGN" ]; then
  echo "DESIGN_SYSTEM: $_DESIGN"
  cat "$_DESIGN"
else
  echo "DESIGN_SYSTEM: none found — applying ui-ux-pro-max universal rules"
fi
```

> **If a DESIGN.md was found above:** you MUST treat it as the authoritative design system for this session.
> All color, typography, spacing, and motion decisions must follow that file FIRST, then apply the rules below as constraints.
> Do NOT override established design tokens with defaults from this skill.

---

# UI/UX Pro Max — Design Intelligence v2

Comprehensive design guide for web and mobile applications. Contains 50+ styles, 161 color palettes, 57 font pairings, 161 product types with reasoning rules, 99 UX guidelines, and 25 chart types across 10 technology stacks.

## When to Apply

### Must Use
- Designing new pages (Landing Page, Dashboard, Admin, SaaS, Mobile App)
- Creating or refactoring UI components (buttons, modals, forms, tables, charts)
- Choosing color schemes, typography systems, spacing standards, or layout systems
- Reviewing UI code for user experience, accessibility, or visual consistency
- Implementing navigation structures, animations, or responsive behavior
- Making product-level design decisions

### Recommended
- UI looks "not professional enough" but the reason is unclear
- Pre-launch UI quality optimization
- Building design systems or reusable component libraries

### Skip
- Pure backend logic, API/database design, DevOps, non-visual scripts

**Decision criteria**: If the task will change how a feature looks, feels, moves, or is interacted with, this Skill should be used.

**Iteration expectation**: First output is a draft, not a product. Always plan for at least 3 iterations — the first pass surfaces the layout, the second removes what's default, the third makes it deliberate.

## Pre-Session Design Constraints

Set these BEFORE generating any code or design. Acknowledge them and hold throughout the session:

- **Max 3 colors** total — 1 primary, 1 neutral, 1 accent. More than 3 = noise.
- **Max 2 font families** — 1 heading, 1 body. Never mix more.
- **Content max-width 1200px** on desktop — wider than this and lines become unreadable.
- **No purple, indigo, or violet** as primary or accent (AI-default palette — instant vibe-code signal).
- **No neon accents on dark backgrounds** — same issue.
- **No fake content** — no placeholder testimonials, fake stats, or unverifiable claims that could ship.
- **Animation cap: 2 types max** on the entire page — no exceptions.

## Rule Categories by Priority

| Priority | Category | Impact | Key Checks | Anti-Patterns |
|----------|----------|--------|------------|---------------|
| 1 | Accessibility | CRITICAL | Contrast 4.5:1, Alt text, Keyboard nav, Aria-labels | Removing focus rings, Icon-only buttons without labels |
| 2 | Touch & Interaction | CRITICAL | Min size 44x44px, 8px+ spacing, Loading feedback | Reliance on hover only, Instant state changes |
| 3 | Performance | HIGH | WebP/AVIF, Lazy loading, CLS < 0.1 | Layout thrashing, CLS |
| 4 | Style Selection | HIGH | Match product type, Consistency, SVG icons | Mixing styles randomly, Emoji as icons |
| 5 | Layout & Responsive | HIGH | Mobile-first, Viewport meta, No horizontal scroll | Fixed px widths, Disable zoom |
| 6 | Typography & Color | MEDIUM | Base 16px, Line-height 1.5, Semantic color tokens | Text < 12px, Gray-on-gray, Raw hex |
| 7 | Animation | MEDIUM | Duration 150-300ms, Motion conveys meaning | Decorative-only animation, No reduced-motion |
| 8 | Forms & Feedback | MEDIUM | Visible labels, Error near field, Progressive disclosure | Placeholder-only label, Errors only at top |
| 9 | Navigation Patterns | HIGH | Predictable back, Bottom nav ≤5, Deep linking | Overloaded nav, Broken back behavior |
| 10 | Charts & Data | LOW | Legends, Tooltips, Accessible colors | Color-only meaning |

## Quick Reference

### 1. Accessibility (CRITICAL)
- `color-contrast` - Minimum 4.5:1 ratio for normal text (large text 3:1)
- `focus-states` - Visible focus rings on interactive elements (2-4px)
- `alt-text` - Descriptive alt text for meaningful images
- `aria-labels` - aria-label for icon-only buttons
- `keyboard-nav` - Tab order matches visual order; full keyboard support
- `form-labels` - Use label with for attribute
- `skip-links` - Skip to main content for keyboard users
- `heading-hierarchy` - Sequential h1→h6, no level skip
- `color-not-only` - Don't convey info by color alone (add icon/text)
- `dynamic-type` - Support system text scaling
- `reduced-motion` - Respect prefers-reduced-motion
- `voiceover-sr` - Meaningful accessibilityLabel; logical reading order

### 2. Touch & Interaction (CRITICAL)
- `touch-target-size` - Min 44x44pt (Apple) / 48x48dp (Material)
- `touch-spacing` - Minimum 8px gap between touch targets
- `hover-vs-tap` - Use click/tap for primary interactions; don't rely on hover alone
- `loading-buttons` - Disable button during async operations; show spinner
- `error-feedback` - Clear error messages near problem
- `cursor-pointer` - Add cursor-pointer to clickable elements
- `gesture-conflicts` - Avoid horizontal swipe on main content
- `haptic-feedback` - Use haptic for confirmations; avoid overuse
- `safe-area-awareness` - Keep targets away from notch, Dynamic Island, gesture bar

### 3. Performance (HIGH)
- `image-optimization` - Use WebP/AVIF, responsive images, lazy load
- `image-dimension` - Declare width/height to prevent layout shift
- `font-loading` - Use font-display: swap/optional
- `critical-css` - Prioritize above-the-fold CSS
- `lazy-loading` - Lazy load non-hero components via dynamic import
- `bundle-splitting` - Split code by route/feature
- `virtualize-lists` - Virtualize lists with 50+ items
- `progressive-loading` - Skeleton screens instead of spinners for >1s operations
- `debounce-throttle` - Use for high-frequency events (scroll, resize, input)

### 4. Style Selection (HIGH)
- `style-match` - Match style to product type
- `consistency` - Use same style across all pages
- `no-emoji-icons` - Use SVG icons (Heroicons, Lucide), not emojis
- `platform-adaptive` - Respect platform idioms (iOS HIG vs Material)
- `state-clarity` - Make hover/pressed/disabled states visually distinct
- `elevation-consistent` - Consistent elevation/shadow scale
- `dark-mode-pairing` - Design light/dark variants together
- `primary-action` - Each screen: only one primary CTA

### 5. Layout & Responsive (HIGH)
- `viewport-meta` - width=device-width initial-scale=1 (never disable zoom)
- `mobile-first` - Design mobile-first, then scale up
- `breakpoint-consistency` - Systematic breakpoints (375 / 768 / 1024 / 1440)
- `readable-font-size` - Minimum 16px body text on mobile
- `line-length-control` - Mobile 35-60 chars; desktop 60-75 chars
- `horizontal-scroll` - No horizontal scroll on mobile
- `spacing-scale` - Use 4pt/8dp incremental spacing system
- `section-spacing` - Minimum 60-80px vertical gap between major page sections — below this, sections blur together
- `z-index-management` - Define layered z-index scale
- `viewport-units` - Prefer min-h-dvh over 100vh on mobile

### 6. Typography & Color (MEDIUM)
- `line-height` - Use 1.5-1.75 for body text
- `font-pairing` - Match heading/body font personalities
- `font-scale` - Consistent type scale (12 14 16 18 24 32)
- `color-semantic` - Define semantic color tokens not raw hex
- `color-dark-mode` - Dark mode uses desaturated/lighter tonal variants
- `color-accessible-pairs` - Pairs must meet 4.5:1 (AA) or 7:1 (AAA)
- `number-tabular` - Use tabular figures for data columns, prices, timers
- `no-ai-default-palette` - Never use purple/indigo/violet as primary or accent — this is the single most recognizable AI-default palette. It signals "vibe-coded" instantly to any experienced user.
- `no-neon-dark` - No neon/saturated accent colors on dark backgrounds — the other half of the AI-default visual signature
- `palette-specificity` - Choose a palette based on the industry/audience and document why. "It looked good" is not a reason.

### 7. Animation (MEDIUM)
- `duration-timing` - 150-300ms for micro-interactions; ≤400ms complex; avoid >500ms
- `transform-performance` - Use transform/opacity only; avoid animating width/height
- `loading-states` - Skeleton or progress indicator when loading >300ms
- `easing` - ease-out for entering, ease-in for exiting
- `motion-meaning` - Every animation must express cause-effect, not decoration
- `spring-physics` - Prefer spring/physics-based curves for natural feel
- `interruptible` - Animations must be interruptible by user
- `stagger-sequence` - Stagger list items by 30-50ms per item
- `banned-animations` - NEVER use: bounce, slide-from-side, scale-up entrance, floating/levitating elements, particle effects, background motion, looping decorative animations
- `no-above-fold-delay` - Hero content loads instantly — zero animation delay on above-the-fold elements. User should never wait to see what the page is.
- `animation-purpose-test` - Before adding any animation, ask: "does this communicate something or just entertain?" If entertain, remove it.

### 8. Forms & Feedback (MEDIUM)
- `input-labels` - Visible label per input (not placeholder-only)
- `error-placement` - Show error below the related field
- `submit-feedback` - Loading then success/error state on submit
- `empty-states` - Helpful message and action when no content
- `toast-dismiss` - Auto-dismiss toasts in 3-5s
- `confirmation-dialogs` - Confirm before destructive actions
- `progressive-disclosure` - Reveal complex options progressively
- `inline-validation` - Validate on blur, not keystroke
- `undo-support` - Allow undo for destructive actions
- `error-recovery` - Error messages must include recovery path

### 9. Navigation Patterns (HIGH)
- `bottom-nav-limit` - Max 5 items; use labels with icons
- `back-behavior` - Predictable and consistent; preserve scroll/state
- `deep-linking` - All key screens reachable via deep link/URL
- `nav-label-icon` - Both icon and text label; icon-only harms discoverability
- `nav-state-active` - Current location visually highlighted
- `modal-escape` - Modals must offer clear close/dismiss affordance
- `state-preservation` - Back navigation restores scroll position, filter state
- `adaptive-navigation` - Large screens prefer sidebar; small use bottom/top nav

### 10. Charts & Data (LOW)
- `chart-type` - Match chart to data type (trend→line, comparison→bar, proportion→pie)
- `color-guidance` - Accessible palettes; avoid red/green only pairs
- `legend-visible` - Always show legend near chart
- `tooltip-on-interact` - Tooltips on hover/tap showing exact values
- `responsive-chart` - Charts must reflow on small screens
- `empty-data-state` - Meaningful empty state, not blank chart

## Common Rules for Professional UI

### Icons & Visual Elements
- No Emoji as Structural Icons — Use vector-based icons (Lucide, Heroicons)
- Vector-Only Assets — SVG or platform vector icons that scale cleanly
- Correct Brand Logos — Use official brand assets
- Consistent Icon Sizing — Define as design tokens (icon-sm, icon-md=24pt, icon-lg)
- Touch Target Minimum — 44x44pt interactive area
- Real Screenshots Over AI Illustrations — Use actual product screenshots (even rough ones) over AI-generated or stock-style hero illustrations. Real images build more trust and look less vibe-coded.

### Copy Anti-Patterns
- No generic hero headlines — "Transform your workflow", "The future of X", "Revolutionize how you Y" are immediate vibe-code tells. State exactly what the product does in 8 words or less.
- No vague benefit claims — Every claim should be specific and provable ("saves 2 hours" not "saves time")
- No buzzword stacking — "AI-powered", "next-generation", "seamless" combined in one sentence = instant trust loss

### Content Integrity
- No fake testimonials — Never generate attributed quotes from fictional users. If no real testimonials exist, use alternatives (see below).
- No unverifiable stats — "10,000+ users", "99.9% uptime", "50% faster" with no source = credibility killer. Flag these for the user to verify or remove.
- No placeholder content shipped — Any [PLACEHOLDER], Lorem Ipsum, or "coming soon" content must be caught in pre-delivery review.
- Trust alternatives when social proof is absent:
  - Founder/builder story (2-3 sentences on why it was built)
  - Specific technical claims with evidence (open-source repo, security certifications)
  - "Be one of the first 100" framing instead of fake user counts
  - Process transparency ("Built with X, hosted on Y, data never leaves Z")

### Light/Dark Mode Contrast
- Surface readability: cards clearly separated from background
- Text contrast >=4.5:1 in both themes
- Borders/dividers visible in both themes
- Token-driven theming with semantic color tokens

### Layout & Spacing
- Safe-area compliance for fixed headers, tab bars, CTA bars
- 8dp spacing rhythm for padding/gaps
- Readable text measure (avoid edge-to-edge on tablets)
- Scroll and fixed element coexistence (proper insets)

## Pre-Delivery Checklist

Before delivering UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] cursor-pointer on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] prefers-reduced-motion respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile
- [ ] Both light and dark themes tested
- [ ] Touch targets >= 44pt
- [ ] Safe areas respected

### Vibe-Code Audit (run before any delivery)
- [ ] **Color** — No purple, indigo, or violet as primary/accent. No neon on dark background.
- [ ] **Animations** — Count animation types used. If more than 2, remove the extras. No bounce, no slide-from-side, no looping decorative motion, no above-fold delays.
- [ ] **Content** — Zero fake testimonials, zero unverifiable stats, zero placeholder text in live copy.
- [ ] **Copy** — Hero headline states what the product does in plain words. No "Transform your workflow" or equivalent.
- [ ] **Squint test** — Blur your eyes looking at the page. Can you identify distinct sections? If everything blurs together, spacing or contrast is the problem.
- [ ] **Screenshots** — If the page uses an illustration in the hero, ask: is there a real product screenshot that could replace it?
- [ ] **Iteration check** — Is this the first output? If yes, it's a draft. Iterate at least once more before calling it done.
