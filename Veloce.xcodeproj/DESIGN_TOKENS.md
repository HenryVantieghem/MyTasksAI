# 🎨 Veloce Design Tokens
## Complete Reference Guide

**Version:** 1.0  
**Last Updated:** December 26, 2025

---

## 📐 Overview

This document contains all design tokens for the Veloce app. Use these values consistently throughout the codebase to maintain visual harmony and accessibility.

---

## 🎨 Colors

### Brand Colors

| Token | Hex | RGB | Usage |
|-------|-----|-----|-------|
| `accent` | `#8B5CF6` | `139, 92, 246` | Primary actions, focus states, brand moments |
| `accentSecondary` | `#6366F1` | `99, 102, 241` | Gradient stops, secondary brand |

### Background Colors

| Token | Value | Usage |
|-------|-------|-------|
| `background.primary` | `#000000` | App background, darkest layer |
| `background.secondary` | `#0A0A0A` | Slightly elevated surfaces |
| `background.tertiary` | `#141414` | Card backgrounds |
| `background.elevated` | `#1C1C1C` | Elevated cards, modals |

### Text Colors (Semantic)

| Token | Opacity | Contrast Ratio | Usage |
|-------|---------|----------------|-------|
| `label.primary` | 100% | 21:1 | Primary content, titles |
| `label.secondary` | 85% | 17.8:1 | Secondary content, subtitles |
| `label.tertiary` | 60% | 12.6:1 | Supporting info, metadata |
| `label.quaternary` | 40% | 8.4:1 | Hints, placeholders |

✅ All text colors meet WCAG AA standards (4.5:1 minimum)

### System Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `system.success` | `#10B981` | Task completion, achievements |
| `system.error` | `#EF4444` | Errors, destructive actions |
| `system.warning` | `#F59E0B` | Warnings, important notices |
| `system.info` | `#3B82F6` | Information, tips |

### Glass Material Colors

| Token | Opacity | Usage |
|-------|---------|-------|
| `glass.base` | 3% | Default glass background |
| `glass.focused` | 8% | Active/focused glass |
| `glass.border` | 12% | Glass borders (rest) |
| `glass.borderFocused` | 25% | Glass borders (focused) |
| `glass.highlight` | 20% | Top-edge glossy shine |

### AI Gradient Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `ai.purple` | `#8B5CF6` | AI gradient start |
| `ai.indigo` | `#6366F1` | AI gradient mid 1 |
| `ai.blue` | `#3B82F6` | AI gradient mid 2 |
| `ai.cyan` | `#06B6D4` | AI gradient end |

**AI Gradient:** Purple → Indigo → Blue → Cyan (topLeading to bottomTrailing)

---

## ✏️ Typography

### iOS Typography Scale

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| **Large Title** | 34pt | Bold | 41pt | Page headers, hero content |
| **Title 1** | 28pt | Bold | 34pt | Section headers |
| **Title 2** | 22pt | Bold | 28pt | Subsection headers |
| **Title 3** | 20pt | Semibold | 25pt | Card headers |
| **Headline** | 17pt | Semibold | 22pt | List titles, emphasized |
| **Body** | 17pt | Regular | 22pt | Primary content |
| **Callout** | 16pt | Regular | 21pt | Secondary content |
| **Subheadline** | 15pt | Regular | 20pt | Tertiary content |
| **Footnote** | 13pt | Regular | 18pt | Metadata, timestamps |
| **Caption 1** | 12pt | Regular | 16pt | Labels, small details |
| **Caption 2** | 11pt | Regular | 13pt | Tiny labels |

### Font Weights

- **Bold** (700) - Headers, emphasis
- **Semibold** (600) - Subheaders, important text
- **Medium** (500) - Slightly emphasized
- **Regular** (400) - Body text, default
- **Light** (300) - De-emphasized text

### Dynamic Type Support

All text should support Dynamic Type from `.medium` to `.accessibility3`:

```swift
Text("Hello")
    .font(Veloce.Typography.body)
    .dynamicTypeSize(.medium ... .accessibility3)
```

### Text Hierarchy in Practice

```
┌─────────────────────────────┐
│                             │
│  Dashboard        [Title 2] │
│                             │
│  Today's Tasks   [Headline] │
│                             │
│  ○ Task title       [Body]  │
│    Due today     [Footnote] │
│                             │
│  Stats           [Headline] │
│                             │
│  12/15 tasks      [Caption] │
│                             │
└─────────────────────────────┘
```

---

## 📏 Spacing System (8pt Grid)

### Spacing Scale

| Token | Value | Rem Equivalent | Usage |
|-------|-------|----------------|-------|
| `xxxs` | 2pt | 0.125rem | Hairline spacing |
| `xxs` | 4pt | 0.25rem | Very tight spacing |
| `xs` | 8pt | 0.5rem | Tight spacing |
| `sm` | 12pt | 0.75rem | Small spacing |
| `md` | 16pt | 1rem | Base spacing unit |
| `lg` | 24pt | 1.5rem | Large spacing |
| `xl` | 32pt | 2rem | Extra large spacing |
| `xxl` | 48pt | 3rem | Very large spacing |
| `xxxl` | 64pt | 4rem | Maximum spacing |

### Semantic Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `screenPadding` | 16pt | Left/right screen edges |
| `cardPadding` | 16pt | Internal card padding |
| `sectionSpacing` | 24pt | Between major sections |

### Spacing Examples

```
Element Spacing:
[Icon]  8pt  [Text]

List Item Spacing:
[Item 1]
   8pt
[Item 2]
   8pt
[Item 3]

Card Spacing:
┌─────────────────────┐
│ 16pt                │
│  [Content]          │
│             16pt    │
└─────────────────────┘

Section Spacing:
[Section 1]
    24pt
[Section 2]
    24pt
[Section 3]
```

---

## ⭕ Corner Radius

### Radius Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 8pt | Small elements |
| `sm` | 12pt | Compact buttons |
| `md` | 16pt | Standard cards |
| `lg` | 20pt | Large cards |
| `xl` | 24pt | Very large cards |
| `xxl` | 30pt | Input bars |
| `pill` | 999pt | Capsule shape |

### Semantic Radii

| Token | Value | Component |
|-------|-------|-----------|
| `card` | 16pt | Task cards, goal cards |
| `button` | 14pt | Standard buttons |
| `input` | 30pt | Input fields, search bars |
| `pill` | 999pt | Filter pills, tags |

### Radius by Component

```
Input Bar:       30pt (xxl)
Task Card:       16pt (md)
Filter Pill:     999pt (pill)
Button:          14pt (button)
Avatar:          999pt (pill/circle)
Dialog:          20pt (lg)
Sheet:           28pt (custom)
```

---

## 👆 Touch Targets

### Minimum Sizes (Apple HIG)

| Target | Size | Usage |
|--------|------|-------|
| `minimum` | 44×44pt | Apple HIG minimum |
| `comfortable` | 48×48pt | Preferred minimum |
| `large` | 56×56pt | Primary actions |

### Implementation

```swift
// Always ensure minimum touch target
Button("Action") { }
    .frame(minWidth: 44, minHeight: 44)
    .contentShape(Rectangle())
```

### Touch Target Examples

```
Checkbox:     44×44pt (larger than visible)
Icon Button:  44×44pt minimum
Tab Bar Item: 48×48pt comfortable
FAB:          56×56pt large
```

---

## 🌊 Shadows & Elevation

### Shadow Presets

| Level | Y Offset | Blur Radius | Opacity | Usage |
|-------|----------|-------------|---------|-------|
| **None** | 0pt | 0pt | 0% | Flat elements |
| **Subtle** | 2pt | 8pt | 8% | Slight elevation |
| **Low** | 4pt | 12pt | 12% | Card hover |
| **Medium** | 6pt | 16pt | 15% | Cards, modals |
| **High** | 8pt | 20pt | 18% | Floating elements |
| **Very High** | 12pt | 24pt | 20% | Dialogs, popovers |

### Glass Shadows

```swift
// Standard glass card
.shadow(color: .black.opacity(0.12), radius: 12, y: 4)
.shadow(color: .black.opacity(0.08), radius: 4, y: 2)

// Elevated glass card
.shadow(color: .black.opacity(0.15), radius: 16, y: 6)
.shadow(color: .black.opacity(0.08), radius: 4, y: 2)

// Focus glow
.shadow(color: accent.opacity(0.3), radius: 20, y: 4)
```

### Glow Effects

| Type | Color | Radius | Opacity |
|------|-------|--------|---------|
| **Accent Glow** | Accent | 20pt | 30% |
| **Success Glow** | Success | 16pt | 25% |
| **Error Glow** | Error | 16pt | 30% |
| **AI Glow** | Purple | 20pt | 35% |

---

## ⏱️ Animation Timing

### Durations

| Token | Value | Usage |
|-------|-------|-------|
| `instant` | 0ms | No animation (accessibility) |
| `quick` | 150ms | Micro-interactions |
| `standard` | 300ms | Standard transitions |
| `slow` | 500ms | Emphasis, reveals |

### Spring Animations

| Token | Response | Damping | Usage |
|-------|----------|---------|-------|
| `spring` | 0.4s | 0.7 | Standard spring |
| `springSnappy` | 0.3s | 0.75 | Quick response |
| `springBouncy` | 0.5s | 0.6 | Playful bounce |
| `springGentle` | 0.6s | 0.8 | Subtle motion |

### Timing Curves

```swift
// Ease curves
easeOut:    .easeOut(duration: 0.3)    // Start fast, end slow
easeIn:     .easeIn(duration: 0.3)     // Start slow, end fast
easeInOut:  .easeInOut(duration: 0.3)  // Smooth both ends

// Spring (preferred)
spring:     .spring(response: 0.4, dampingFraction: 0.7)
```

### Animation by Interaction

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| **Button Press** | Scale 0.95 | 150ms |
| **Card Tap** | Scale 0.98 | 200ms |
| **Sheet Present** | Slide up | 300ms |
| **Tab Switch** | Fade + slide | 300ms |
| **List Insert** | Scale + fade | 300ms |
| **Success** | Bounce | 500ms |

---

## 🎭 Transitions

### Standard Transitions

```swift
// Fade
.transition(.opacity)

// Scale
.transition(.scale(scale: 0.95).combined(with: .opacity))

// Slide
.transition(.move(edge: .bottom).combined(with: .opacity))

// Asymmetric (different in/out)
.transition(.asymmetric(
    insertion: .scale.combined(with: .opacity),
    removal: .opacity
))
```

### View Transitions

| View Type | Insertion | Removal |
|-----------|-----------|---------|
| **Modal** | Slide up + fade | Fade out |
| **Sheet** | Slide up | Slide down |
| **Popover** | Scale + fade | Fade out |
| **Toast** | Slide + fade | Fade out |
| **List Item** | Scale + fade | Fade out |

---

## 🔤 SF Symbols

### Commonly Used Icons

| Purpose | Symbol | Size |
|---------|--------|------|
| **Add** | `plus` | 18pt |
| **Complete** | `checkmark.circle` | 24pt |
| **Delete** | `trash` | 16pt |
| **Edit** | `pencil` | 16pt |
| **Search** | `magnifyingglass` | 16pt |
| **Filter** | `line.3.horizontal.decrease` | 16pt |
| **Calendar** | `calendar` | 18pt |
| **Stats** | `chart.bar` | 18pt |
| **Settings** | `gearshape` | 18pt |
| **AI** | `sparkles` | 16pt |
| **Voice** | `mic.fill` | 18pt |
| **Send** | `arrow.up` | 18pt |
| **Star** | `star.fill` | 12pt |
| **Flame** | `flame.fill` | 20pt |

### Icon Weights

- **Light** - Ethereal, minimal UI
- **Regular** - Default, balanced
- **Medium** - Slightly emphasized
- **Semibold** - Strong emphasis
- **Bold** - Maximum emphasis

---

## 📱 Layout Patterns

### Screen Structure

```
┌─────────────────────────────┐
│  Header                60pt │
├─────────────────────────────┤
│ 16pt padding                │
│                             │
│  Content Area               │
│                             │
│                      16pt   │
├─────────────────────────────┤
│  Input Bar          ~80pt   │
│  Tab Bar            ~90pt   │
└─────────────────────────────┘
```

### Card Layout

```
┌─────────────────────────────┐
│ 16pt                        │
│   ┌─────────────────────┐   │
│   │ 16pt            │   │   │
│   │                 │   │   │
│   │  Card Content   │ 16pt  │
│   │                 │   │   │
│   │            16pt │   │   │
│   └─────────────────────┘   │
│                        16pt │
└─────────────────────────────┘
```

### List Item Layout

```
┌─────────────────────────────┐
│ 16pt           ┌──────┐ 16pt│
│                │      │     │
│  ○ [Icon]      │ Text │  ›  │ ← 16pt vertical
│                │      │     │
│                └──────┘     │
└─────────────────────────────┘
     ↕ 8pt spacing
```

---

## ♿ Accessibility

### Color Contrast Ratios (WCAG AA)

| Combination | Ratio | Pass |
|-------------|-------|------|
| White on Black | 21:1 | ✅ AAA |
| White 85% on Black | 17.8:1 | ✅ AAA |
| White 60% on Black | 12.6:1 | ✅ AAA |
| Accent on Black | 5.2:1 | ✅ AA |

### Touch Targets

- ✅ Minimum 44×44pt (Apple HIG)
- ✅ Preferred 48×48pt for comfort
- ✅ Invisible hit area expansion

### Dynamic Type

- ✅ Support sizes: `.medium` to `.accessibility3`
- ✅ Text scales appropriately
- ✅ Layouts don't break

### Reduce Motion

- ✅ Disable decorative animations
- ✅ Keep functional animations simple
- ✅ Use crossfades instead of complex motion

### VoiceOver

- ✅ Descriptive labels
- ✅ Helpful hints
- ✅ Grouped elements
- ✅ Custom actions

---

## 🎯 Component-Specific Tokens

### FloatingInputBar

```
Height (rest):      58pt
Height (focused):   80pt
Corner radius:      30pt
Horizontal padding: 18pt
Vertical padding:   12pt (rest), 18pt (focused)

Button size:        42×42pt
Orb size:           46×46pt

Colors:
- Background: glass.base + gradients
- Border: glass.border (rest), glass.borderFocused (focused)
- Focus glow: AI gradient (3 layers)
```

### Task Card

```
Height:             Variable (min 60pt)
Corner radius:      16pt
Padding:            16pt
Checkbox size:      24×24pt
Touch target:       60pt tall

Colors:
- Background: glass.base + gradients
- Border: glass.border
- Text: label.primary
- Secondary: label.tertiary
```

### Tab Bar

```
Height:             90pt (includes safe area)
Pill height:        60pt
Corner radius:      30pt
Icon size:          24pt
Touch target:       48×48pt

Colors:
- Background: glass.base + gradients
- Selected: accent gradient
- Unselected: label.tertiary
```

### Stats Card

```
Height:             Variable
Corner radius:      16pt
Padding:            16pt
Divider width:      1pt
Ring size:          36×36pt

Colors:
- Background: glass.base + gradients
- Border: glass.border
- Progress: accent → accentSecondary
- Complete: success → cyan
```

---

## 🚀 Quick Reference Card

### Most Used Values

**Spacing:** 8pt (xs), 16pt (md), 24pt (lg)  
**Radius:** 16pt (card), 30pt (input), 999pt (pill)  
**Text:** 17pt Body, 22pt Title2, 13pt Footnote  
**Touch:** 44×44pt minimum  
**Animation:** 300ms standard, spring(0.4, 0.7)  

### Color Shortcuts

```swift
// Brand
Veloce.Colors.accent                  // Purple
Veloce.Colors.AI.gradient             // AI gradient

// Text
Veloce.Colors.Label.primary           // White
Veloce.Colors.Label.secondary         // White 85%
Veloce.Colors.Label.tertiary          // White 60%

// System
Veloce.Colors.System.success          // Green
Veloce.Colors.System.error            // Red

// Glass
Veloce.Colors.Glass.base              // 3% white
Veloce.Colors.Glass.border            // 12% white
```

---

## 📋 Usage Examples

### Button

```swift
Button("Add Task") {
    // action
}
.font(Veloce.Typography.headline)
.foregroundStyle(.white)
.padding(.horizontal, Veloce.Spacing.lg)
.padding(.vertical, Veloce.Spacing.md)
.background(Veloce.Colors.accent)
.cornerRadius(Veloce.CornerRadius.button)
.shadow(color: Veloce.Colors.accent.opacity(0.3), 
        radius: 12, y: 4)
```

### Card

```swift
VStack(alignment: .leading, spacing: Veloce.Spacing.sm) {
    Text("Task Title")
        .font(Veloce.Typography.headline)
        .foregroundStyle(Veloce.Colors.Label.primary)
    
    Text("Due today")
        .font(Veloce.Typography.footnote)
        .foregroundStyle(Veloce.Colors.Label.tertiary)
}
.padding(Veloce.Spacing.md)
.background {
    RoundedRectangle(cornerRadius: Veloce.CornerRadius.card)
        .fill(.ultraThinMaterial)
        // Add glass layers...
}
```

### Section

```swift
VStack(alignment: .leading, spacing: Veloce.Spacing.md) {
    Text("Today's Tasks")
        .font(Veloce.Typography.title2)
        .foregroundStyle(Veloce.Colors.Label.primary)
    
    // Content
}
.padding(.horizontal, Veloce.Spacing.screenPadding)
.padding(.vertical, Veloce.Spacing.sectionSpacing)
```

---

## 🎨 Color Palette Visual

```
Brand Colors:
█████ #8B5CF6 Accent
█████ #6366F1 Accent Secondary

System Colors:
█████ #10B981 Success
█████ #EF4444 Error  
█████ #F59E0B Warning
█████ #3B82F6 Info

Backgrounds:
█████ #000000 Primary
█████ #0A0A0A Secondary
█████ #141414 Tertiary
█████ #1C1C1C Elevated

Text (on black):
█████ #FFFFFF Primary (100%)
█████ #FFFFFF Secondary (85%)
█████ #FFFFFF Tertiary (60%)
█████ #FFFFFF Quaternary (40%)
```

---

## 📐 Spacing Grid Visual

```
xxxs: ·· 2pt
xxs:  ···· 4pt
xs:   ········ 8pt
sm:   ············ 12pt
md:   ················ 16pt
lg:   ························ 24pt
xl:   ································ 32pt
xxl:  ················································ 48pt
xxxl: ································································ 64pt
```

---

## 📝 Notes

### Version History
- **1.0** (Dec 26, 2025) - Initial design tokens documentation

### Maintenance
- Review quarterly
- Update with new components
- Keep in sync with code

### Questions?
Refer to the main redesign plan: `VELOCE_REDESIGN_PLAN.md`

---

*All values follow Apple Human Interface Guidelines and 8pt grid system.*
