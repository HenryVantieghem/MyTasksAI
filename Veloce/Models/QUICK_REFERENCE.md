# 🎨 Liquid Glass Quick Reference

## Copy-Paste This Into Any View!

### 1. Glass Card
```swift
VStack {
    // Your content
}
.glassCard(color: .blue)
```

### 2. Glass Button
```swift
Button("Action") { }
    .glassButton(colors: [.blue, .purple])
```

### 3. Gradient Text
```swift
Text("Title")
    .font(.system(size: 34, weight: .heavy, design: .rounded))
    .gradientText()
```

### 4. Progress Ring
```swift
AnimatedProgressRing(
    progress: 0.67,
    color: .blue,
    lineWidth: 12
)
.frame(width: 150, height: 150)
```

### 5. Progress Bar
```swift
GradientProgressBar(
    progress: 0.67,
    height: 12,
    colors: [.blue, .cyan]
)
```

### 6. Stat Card
```swift
GlassStatCard(
    icon: "star",
    value: "42",
    label: "Count",
    color: .blue
)
```

### 7. Section Header
```swift
GlassSectionHeader(
    "Title",
    subtitle: "Info",
    icon: "star",
    color: .blue
)
```

### 8. Badge
```swift
HStack {
    Image(systemName: "star")
    Text("Premium")
}
.glassBadge(color: .orange)
```

### 9. Pill/Tag
```swift
Text("Active")
    .glassPill(color: .blue, isSelected: true)
```

### 10. Glass Group
```swift
GlassGroup {
    HStack {
        StatCard(...)
        StatCard(...)
    }
}
```

## Typography

```swift
// Title
.font(.system(size: 34, weight: .heavy, design: .rounded))

// Header
.font(.system(size: 24, weight: .bold, design: .rounded))

// Body
.font(.system(size: 17, weight: .semibold, design: .rounded))

// Label
.font(.system(size: 15, weight: .bold, design: .rounded))

// Caption
.font(.system(size: 13, weight: .semibold, design: .rounded))
```

## Gradients

```swift
// Vibrant 3-color
LinearGradient.vibrant(base: .blue)

// Smooth 2-color
LinearGradient.smooth(base: .blue)

// For category
LinearGradient.forCategory(.career)

// For timeframe
LinearGradient.forTimeframe(.horizon)
```

## Animations

```swift
// Spring bounce
.animation(.spring(duration: 0.8, bounce: 0.3), value: state)

// Button press
withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
    isPressed = true
}

// Smooth ease
.animation(.easeInOut(duration: 0.3), value: state)
```

## Colors

```swift
Theme.Colors.aiPurple       // Purple
Theme.Colors.aiBlue         // Blue
Theme.Colors.aiCyan         // Cyan
Theme.Colors.success        // Green
Theme.Colors.warning        // Orange
Theme.Colors.error          // Red
```

## Spacing

```swift
.padding(16)                // Standard
.padding(.horizontal, 20)   // Card horizontal
.padding(.vertical, 24)     // Section vertical
```

## Corner Radius

```swift
cornerRadius: 20  // Cards
cornerRadius: 16  // Buttons
cornerRadius: 12  // Pills
cornerRadius: 8   // Badges
```

## Shadows

```swift
// Standard
.shadow(color: color.opacity(0.4), radius: 12, y: 6)

// Enhanced
.shadow(color: color.opacity(0.5), radius: 16, y: 8)

// Subtle
.shadow(color: color.opacity(0.3), radius: 8, y: 4)
```

## Complete Example

```swift
struct MyView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("My View")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .gradientText()
                
                // Stats
                GlassGroup {
                    HStack(spacing: 12) {
                        GlassStatCard(
                            icon: "star",
                            value: "42",
                            label: "Items",
                            color: .blue
                        )
                        
                        GlassStatCard(
                            icon: "flame",
                            value: "7",
                            label: "Streak",
                            color: .orange
                        )
                    }
                }
                
                // Content
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                        
                        GradientProgressBar(
                            progress: item.progress,
                            height: 12,
                            colors: [item.color, item.color.opacity(0.7)]
                        )
                    }
                    .glassCard(color: item.color)
                }
                
                // Action
                GlassActionButton(
                    "Create New",
                    icon: "plus",
                    colors: [.blue, .purple]
                ) {
                    // Action
                }
            }
            .padding()
        }
        .background(Color.black)
    }
}
```

## That's It!

Everything you need on one page 🎉
