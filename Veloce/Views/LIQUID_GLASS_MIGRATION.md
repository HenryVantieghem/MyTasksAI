# Liquid Glass Migration Guide

Quick reference for updating components from basic glass to Apple Liquid Glass.

---

## 🔄 Before & After Examples

### Example 1: Tab Bar

#### ❌ Before (Basic Glass)
```swift
HStack(spacing: 2) {
    ForEach(tabs) { tab in
        TabItem(tab: tab)
    }
}
.padding(.horizontal, 8)
.padding(.vertical, 10)
.glassEffect(.regular, in: Capsule())
.shadow(color: .black.opacity(0.3), radius: 16, y: 8)
```

#### ✅ After (Liquid Glass)
```swift
HStack(spacing: 0) {
    ForEach(tabs) { tab in
        TabItem(tab: tab)
    }
}
.padding(.horizontal, 4)
.padding(.vertical, 8)
.background {
    ZStack {
        Capsule()
            .fill(.ultraThinMaterial)
        
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .frame(height: 20)
            .offset(y: -15)
        
        Capsule()
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}
.shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
```

---

### Example 2: Card Component

#### ❌ Before (Solid Background)
```swift
VStack {
    Text("Task Title")
    Text("Description")
}
.padding()
.background(Color.blue.opacity(0.2))
.cornerRadius(16)
```

#### ✅ After (Liquid Glass)
```swift
VStack {
    Text("Task Title")
    Text("Description")
}
.padding()
.background {
    ZStack {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
        
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.02),
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .padding(.bottom, 30)
        
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
    }
}
.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
.shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
```

---

### Example 3: Using the Helper

#### ✨ Easy Way (Using LiquidGlassHelper.swift)
```swift
VStack {
    Text("Task Title")
    Text("Description")
}
.padding()
.liquidGlass(.standard, cornerRadius: 16)
```

---

## 🎨 Quick Reference: Style Presets

### Subtle (Low Emphasis)
- **Use for:** Small badges, pills, secondary buttons
- **Depth gradient:** 0.06 → 0.02 → 0.03
- **Highlight:** 0.10
- **Border:** 0.12 → 0.05 → 0.08
- **Shadow:** radius 6, y: 2

### Standard (Medium Emphasis)
- **Use for:** Cards, rows, most components
- **Depth gradient:** 0.08 → 0.02 → 0.04
- **Highlight:** 0.12
- **Border:** 0.15 → 0.05 → 0.10
- **Shadow:** radius 10, y: 3

### Prominent (High Emphasis)
- **Use for:** Focused states, key UI, modals
- **Depth gradient:** 0.10 → 0.03 → 0.05
- **Highlight:** 0.15
- **Border:** 0.25 → 0.08 → 0.15
- **Shadow:** radius 16, y: 5

### Floating (Navigation)
- **Use for:** Tab bars, nav bars, floating controls
- **Depth gradient:** 0.08 → 0.02 → 0.04
- **Highlight:** 0.15
- **Border:** 0.20 → 0.05 → 0.10
- **Shadow:** radius 20, y: 10

---

## 🔧 Migration Checklist

When updating a component:

- [ ] Replace `.glassEffect()` or solid backgrounds with liquid glass
- [ ] Use `.ultraThinMaterial` as base
- [ ] Add 3-color depth gradient (top, middle, bottom)
- [ ] Add top highlight gradient (white → clear)
- [ ] Add border gradient with 3 stops
- [ ] Use `.continuous` corner style
- [ ] Add dual shadow system (ambient + contact)
- [ ] Test with dark content behind to see transparency
- [ ] Verify accessibility (motion, contrast)

---

## 🎯 Common Patterns

### Pattern 1: Pill/Capsule
```swift
HStack {
    Image(systemName: "star")
    Text("Label")
}
.padding(.horizontal, 12)
.padding(.vertical, 8)
.liquidGlassCapsule(.standard)
```

### Pattern 2: Card
```swift
VStack(alignment: .leading) {
    Text("Title")
    Text("Body")
}
.padding()
.liquidGlass(.standard, cornerRadius: 16)
```

### Pattern 3: Floating Bar
```swift
HStack {
    // Navigation items
}
.padding()
.liquidGlassCapsule(.floating)
.padding(.horizontal, 16)
```

### Pattern 4: Button with Glass
```swift
LiquidGlassButton(style: .standard, action: {}) {
    HStack {
        Image(systemName: "plus")
        Text("Add")
    }
}
```

### Pattern 5: Custom Shape
```swift
LiquidGlassShape(
    shape: Circle(),
    style: .standard
)
.frame(width: 60, height: 60)
```

---

## 🚨 Common Mistakes to Avoid

### ❌ Don't: Stack too many glass layers
```swift
// BAD - Too many translucent layers
VStack {
    Text("Content")
        .liquidGlass()
}
.liquidGlass() // Second layer makes it muddy
```

### ✅ Do: Apply glass to container only
```swift
// GOOD - Single glass layer
VStack {
    Text("Content")
}
.liquidGlass()
```

---

### ❌ Don't: Forget continuous corners
```swift
// BAD - Regular corners look dated
RoundedRectangle(cornerRadius: 16)
```

### ✅ Do: Use continuous style
```swift
// GOOD - Smoother, more modern
RoundedRectangle(cornerRadius: 16, style: .continuous)
```

---

### ❌ Don't: Use only one shadow
```swift
// BAD - Flat appearance
.shadow(color: .black.opacity(0.2), radius: 10, y: 5)
```

### ✅ Do: Use dual shadows
```swift
// GOOD - Realistic depth
.shadow(color: .black.opacity(0.08), radius: 12, y: 4)
.shadow(color: .black.opacity(0.04), radius: 2, y: 1)
```

---

### ❌ Don't: Ignore background content
```swift
// BAD - No background to show transparency
ZStack {
    Color.black // Solid black
    GlassComponent()
}
```

### ✅ Do: Use rich backgrounds
```swift
// GOOD - Shows glass effect
ZStack {
    VoidBackground() // Stars, gradients, etc.
    GlassComponent()
}
```

---

## 📱 Testing Checklist

After applying liquid glass:

1. **Visual Test**
   - [ ] Can you see content behind the glass?
   - [ ] Are highlights visible on top edge?
   - [ ] Do borders define edges without being heavy?
   - [ ] Do shadows create proper elevation?

2. **Interactive Test**
   - [ ] Do animations feel fluid (spring-based)?
   - [ ] Does tapping feel responsive?
   - [ ] Do selection states transition smoothly?

3. **Accessibility Test**
   - [ ] Does it respect `reduceMotion`?
   - [ ] Is text still readable on glass?
   - [ ] Do VoiceOver labels still work?

4. **Performance Test**
   - [ ] Does scrolling feel smooth?
   - [ ] Are there any frame drops?
   - [ ] Is memory usage reasonable?

---

## 🎨 Color Recommendations

Glass works best with these background types:

✅ **Good backgrounds for glass:**
- Gradients with multiple colors
- Blurred images
- Particle effects (stars, confetti)
- Animated backgrounds
- Rich dark colors with variation

❌ **Bad backgrounds for glass:**
- Solid black (#000000)
- Pure white (#FFFFFF)
- Single-color flat backgrounds
- Very low contrast scenes

---

## 🚀 Performance Tips

1. **Reuse glass components** - Don't recreate complex backgrounds repeatedly
2. **Use `.continuous` corners** - GPU-optimized rendering
3. **Limit animation complexity** - Spring animations are efficient
4. **Avoid unnecessary blur** - `.ultraThinMaterial` is optimized
5. **Test on real devices** - Simulator may not show performance issues

---

## 🎓 Learn More

Explore these files for examples:
- `LiquidGlassTabBar.swift` - Tab bar implementation
- `FloatingInputBar.swift` - Input with focus states
- `CirclesPill.swift` - Small pill component
- `MainContainerView.swift` - Various card examples
- `LiquidGlassHelper.swift` - Reusable utilities

---

## 📞 Quick Help

**Q: My glass looks too opaque**
A: Increase transparency in depth gradient (lower opacity values)

**Q: I can't see the borders**
A: Increase border opacity or test with richer background

**Q: Animations feel sluggish**
A: Use `.spring(response: 0.35, dampingFraction: 0.86)`

**Q: Glass is too subtle**
A: Switch from `.subtle` to `.standard` or `.prominent`

**Q: Want to customize?**
A: Use `LiquidGlassShape` directly for full control

---

*Happy coding! ✨*
