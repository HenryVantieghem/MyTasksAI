# 🌊 Liquid Glass Quick Reference

Quick reference for implementing Apple's native iOS 26 Liquid Glass in your Veloce app.

---

## 🎯 When to Use What

### Use GLASS for:
- ✅ Buttons and interactive controls
- ✅ Toolbars and navigation bars
- ✅ Tab bars and bottom sheets
- ✅ Floating action buttons
- ✅ Text fields and input controls
- ✅ Popovers and tooltips

### Use SOLID for:
- ✅ Content cards (tasks, notes, events)
- ✅ List items and rows
- ✅ Large text blocks
- ✅ Images and media
- ✅ Background surfaces

---

## 📦 Component Cheat Sheet

### Buttons
```swift
// Primary CTA - gradient with glass
LiquidGlassButton.primary("Continue", icon: "arrow.right") { }

// Secondary - pure native glass
LiquidGlassButton.secondary("Cancel") { }

// Success - green gradient with glass
LiquidGlassButton.success("Done", icon: "checkmark") { }

// Ghost - minimal, glass on press only
LiquidGlassButton.ghost("Skip", icon: "forward") { }

// Small pill button
LiquidGlassButtonSmall("Edit", icon: "pencil") { }

// Icon-only button
LiquidGlassIconButton(icon: "xmark", size: 44, tint: .red) { }
```

### Text Fields
```swift
// Basic text field
SimpleLiquidGlassTextField("Email", text: $email, icon: "envelope")

// Search bar with clear button
LiquidGlassSearchBar(text: $query, placeholder: "Search")
```

### Cards & Rows
```swift
// Toggle row
LiquidGlassToggleRow(
    title: "Notifications",
    subtitle: "Stay updated",
    icon: "bell.fill",
    color: .orange,
    isOn: $enabled
)

// Action row (tappable)
LiquidGlassActionRow(
    title: "Settings",
    subtitle: "Manage app",
    icon: "gear",
    color: .blue
) { }

// Content card (solid, not glass)
VStack {
    Text("Task Title")
}.liquidContentCard(tint: .purple)
```

### Badges & Pills
```swift
// Small badge
LiquidGlassBadge("Pro", color: .gold, icon: "crown.fill")

// Compact pill
LiquidGlassPill(text: "New", icon: "sparkles", color: .cyan)
```

### Progress & Loading
```swift
// Progress bar
LiquidGlassProgressBar(
    progress: 0.65,
    color: .green,
    showPercentage: true
)

// Loading spinner
LiquidGlassLoadingSpinner()
```

### Section Headers
```swift
LiquidGlassSectionHeader(
    "Tasks",
    icon: "checkmark.circle",
    color: .green
) {
    // Optional action
}
```

### Empty States
```swift
LiquidGlassEmptyState(
    icon: "tray",
    title: "No Tasks",
    message: "Add your first task to get started",
    actionTitle: "Add Task"
) {
    // Action
}
```

### Floating Action Button
```swift
LiquidGlassFloatingActionButton(icon: "plus") {
    // Main action
}
```

---

## 🔧 Modifier Reference

### Apply Glass Effects
```swift
// Interactive glass (buttons, controls)
view.liquidGlassInteractive(in: Capsule())

// Static glass card
view.liquidGlassCard(cornerRadius: 16)

// Prominent with tint
view.liquidGlassProminent(in: Circle(), tint: .purple)

// Text field
view.liquidGlassTextField()
```

### Content Cards (Solid, NOT Glass)
```swift
// Basic content card
view.liquidContentCard()

// With color tint
view.liquidContentCard(tint: .cyan)

// With custom radius
view.liquidContentCard(cornerRadius: 20)

// With border
view.liquidContentCard(tint: .purple, borderColor: .purple)

// Elevated with shadow
view.liquidElevatedCard(cornerRadius: 16)
```

### Glass Effects & Glows
```swift
// Static glow
view.liquidGlow(color: .purple, radius: 20, intensity: 0.4)

// Animated pulsing glow
view.liquidPulsingGlow(color: .cyan, baseIntensity: 0.3, pulseIntensity: 0.6)
```

---

## 🎨 Color Tints

Use semantic colors for glass tints:

```swift
// Success (green)
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.Semantic.success)

// Error (red)
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.Semantic.error)

// Warning (orange)
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.Semantic.warning)

// Info (blue)
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.Semantic.info)

// Vibrant accents
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.VibrantAccents.electricCyan)
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.VibrantAccents.plasmaPurple)
.liquidGlassProminent(in: shape, tint: LiquidGlassDesignSystem.VibrantAccents.auroraGreen)
```

---

## 🏗️ Container Optimization

When you have multiple glass elements near each other:

```swift
LiquidGlassContainer(spacing: 40) {
    // All your glass elements
    ForEach(items) { item in
        ItemView(item)
            .liquidGlassInteractive(in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Benefits:**
- Optimizes rendering performance
- Enables morphing between elements
- Elements blend together when close

---

## 🎯 Common Patterns

### Button Stack
```swift
VStack(spacing: 16) {
    LiquidGlassButton.primary("Continue") { }
    LiquidGlassButton.secondary("Cancel") { }
}
.padding(.horizontal, 24)
```

### Form with Glass Fields
```swift
VStack(spacing: 16) {
    SimpleLiquidGlassTextField("Name", text: $name, icon: "person")
    SimpleLiquidGlassTextField("Email", text: $email, icon: "envelope")
    SimpleLiquidGlassTextField("Phone", text: $phone, icon: "phone")
}
```

### Settings List
```swift
VStack(spacing: 12) {
    LiquidGlassToggleRow(
        title: "Notifications",
        subtitle: "Push alerts",
        icon: "bell.fill",
        color: .orange,
        isOn: $notifications
    )
    
    LiquidGlassActionRow(
        title: "Privacy",
        subtitle: "Data & security",
        icon: "lock.fill",
        color: .blue
    ) {
        // Navigate to privacy
    }
}
```

### Tab Bar (Custom)
```swift
HStack(spacing: 0) {
    SimpleLiquidGlassTabItem(
        icon: "house.fill",
        title: "Home",
        isSelected: selectedTab == .home
    ) {
        selectedTab = .home
    }
    
    SimpleLiquidGlassTabItem(
        icon: "calendar",
        title: "Plan",
        isSelected: selectedTab == .plan
    ) {
        selectedTab = .plan
    }
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
.background {
    // Glass background for tab bar
    if #available(iOS 26.0, *) {
        Color.clear.glassEffect(.regular, in: Capsule())
    } else {
        Capsule().fill(.ultraThinMaterial)
    }
}
```

---

## ⚡ Performance Tips

### DO ✅
```swift
// Group multiple glass elements
LiquidGlassContainer(spacing: 40) {
    GlassButton1()
    GlassButton2()
}

// Use content cards for non-interactive content
TaskCard().liquidContentCard()

// Respect accessibility
@Environment(\.accessibilityReduceMotion) var reduceMotion
if !reduceMotion {
    // Animate
}
```

### DON'T ❌
```swift
// Don't nest glass over glass
VStack {
    Text("Bad")
        .liquidGlassCard()
}
.liquidGlassCard() // ❌ Double glass

// Don't use glass for large text blocks
Text(longArticle)
    .liquidGlassCard() // ❌ Hard to read

// Don't ignore reduced motion
withAnimation(.linear(duration: 10).repeatForever()) {
    // ❌ Always check reduceMotion first
}
```

---

## 🎨 Design Tokens

### Spacing
```swift
LiquidGlassDesignSystem.Spacing.xs    // 4pt
LiquidGlassDesignSystem.Spacing.sm    // 8pt
LiquidGlassDesignSystem.Spacing.md    // 12pt
LiquidGlassDesignSystem.Spacing.lg    // 16pt
LiquidGlassDesignSystem.Spacing.xl    // 24pt
LiquidGlassDesignSystem.Spacing.xxl   // 32pt
LiquidGlassDesignSystem.Spacing.xxxl  // 48pt
```

### Corner Radius
```swift
LiquidGlassDesignSystem.Radius.xs     // 4pt
LiquidGlassDesignSystem.Radius.sm     // 8pt
LiquidGlassDesignSystem.Radius.md     // 12pt
LiquidGlassDesignSystem.Radius.lg     // 16pt
LiquidGlassDesignSystem.Radius.xl     // 20pt
LiquidGlassDesignSystem.Radius.xxl    // 24pt
LiquidGlassDesignSystem.Radius.full   // 9999pt
```

### Typography
```swift
LiquidGlassDesignSystem.Typography.displayHero
LiquidGlassDesignSystem.Typography.title1
LiquidGlassDesignSystem.Typography.body
LiquidGlassDesignSystem.Typography.caption
```

### Colors
```swift
LiquidGlassDesignSystem.VibrantAccents.electricCyan
LiquidGlassDesignSystem.VibrantAccents.plasmaPurple
LiquidGlassDesignSystem.VibrantAccents.auroraGreen
LiquidGlassDesignSystem.VibrantAccents.solarGold

LiquidGlassDesignSystem.Semantic.success
LiquidGlassDesignSystem.Semantic.error
LiquidGlassDesignSystem.Semantic.warning
```

### Animations
```swift
LiquidGlassDesignSystem.Springs.ui       // 250ms - buttons
LiquidGlassDesignSystem.Springs.sheet    // 400ms - modals
LiquidGlassDesignSystem.Springs.focus    // 500ms - morphing
LiquidGlassDesignSystem.Springs.bouncy   // 350ms - celebrations
LiquidGlassDesignSystem.Springs.quick    // 150ms - immediate
```

---

## 🔍 Debugging

### Check iOS Version Support
```swift
if #available(iOS 26.0, *) {
    print("✅ Native Liquid Glass available")
} else {
    print("⚠️ Using material fallback")
}
```

### Verify Glass Rendering
```swift
// Add colored tint to see glass boundaries
view.liquidGlassCard(cornerRadius: 16)
    .overlay {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.red, lineWidth: 1)
    }
```

### Profile Performance
```swift
// Use Instruments > Core Animation
// Check for:
// - Offscreen-Rendered Yellow (should be minimal)
// - Color Misaligned Images (should be none)
// - Flash Updated Regions (should be small on interaction)
```

---

## 📱 Platform Differences

### iOS 26+
- Native `.glassEffect()` API
- Real-time touch response
- Morphing transitions
- Optimized compositor

### iOS 17-25
- `.ultraThinMaterial` fallback
- Gradient borders
- Same animations
- Same layout

**Result:** Looks nearly identical across all versions! ✨

---

## 🎓 Pro Tips

1. **Less is More** - Don't overuse glass, it's premium
2. **Semantic Colors** - Use tints to convey meaning
3. **Group Elements** - Use `LiquidGlassContainer` for performance
4. **Respect Motion** - Check `accessibilityReduceMotion`
5. **Test on Device** - Glass looks better on real hardware
6. **Solid for Content** - Glass for navigation only
7. **Haptics Matter** - Add tactile feedback to glass interactions
8. **Animate Smoothly** - Use design system springs
9. **Profile Often** - Keep 60fps during animations
10. **Document Patterns** - Create reusable components

---

## 🚀 Quick Start Template

```swift
import SwiftUI

struct MyView: View {
    @State private var text = ""
    @State private var isEnabled = false
    
    var body: some View {
        ZStack {
            // Deep void background
            LiquidGlassDesignSystem.Void.cosmos
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Content card (solid)
                VStack(alignment: .leading, spacing: 12) {
                    Text("My Content")
                        .font(.title2.bold())
                    Text("Description here")
                        .foregroundStyle(.secondary)
                }
                .liquidContentCard()
                
                // Glass text field
                SimpleLiquidGlassTextField(
                    "Input",
                    text: $text,
                    icon: "text.cursor"
                )
                
                // Glass toggle
                LiquidGlassToggleRow(
                    title: "Feature",
                    subtitle: "Enable this",
                    icon: "star.fill",
                    color: .cyan,
                    isOn: $isEnabled
                )
                
                // Glass button
                LiquidGlassButton.primary("Continue") {
                    print("Tapped!")
                }
            }
            .padding()
        }
    }
}
```

---

**Happy Glassing! 🌊✨**
