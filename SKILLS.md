# SKILLS.md - Design & Development Mastery Guide

> Comprehensive knowledge base for building world-class iOS productivity apps
> Compiled from research on top designers, productivity experts, and best-in-class apps

---

## Table of Contents

1. [Design Philosophy Masters](#design-philosophy-masters)
2. [iOS 26 Liquid Glass Design System](#ios-26-liquid-glass-design-system)
3. [Claude/Anthropic Design Language](#claudeanthropic-design-language)
4. [Apple Notes UX Patterns](#apple-notes-ux-patterns)
5. [Best-in-Class Productivity Apps](#best-in-class-productivity-apps)
6. [Productivity Science & Deep Work](#productivity-science--deep-work)
7. [SwiftUI Best Practices](#swiftui-best-practices)
8. [Implementation Patterns](#implementation-patterns)
9. [Genius-Level Feature Ideas](#genius-level-feature-ideas)

---

## Design Philosophy Masters

### Dieter Rams - 10 Principles of Good Design

Dieter Rams, legendary Braun designer whose work inspired Apple's Jonathan Ive, developed these timeless principles:

| Principle | Description | Application to MyTasksAI |
|-----------|-------------|-------------------------|
| **Innovative** | Uses new technologies purposefully | AI-powered task analysis |
| **Useful** | Bought to be used, satisfies functional + psychological needs | Fast task capture, stress reduction |
| **Aesthetic** | Beautiful products we live with daily | Liquid Glass, warm colors |
| **Understandable** | Self-explanatory design | Clear visual hierarchy |
| **Honest** | Doesn't pretend to be more than it is | Transparent AI capabilities |
| **Unobtrusive** | Neutral, allows user self-expression | Minimal chrome, content-first |
| **Long-lasting** | Avoids fashion, timeless | System fonts, native materials |
| **Consistent** | Every detail matters | Unified spacing, typography |
| **Environmentally friendly** | Conserves resources | Efficient code, battery-aware |
| **As little design as possible** | Less, but better | Remove non-essentials |

**Key Quote:** *"Less, but better – because it concentrates on the essential aspects, and the products are not burdened with non-essentials. Back to purity, back to simplicity."*

### Don Norman - The Design of Everyday Things

Core principles from the father of user-centered design:

#### The 7 Fundamental Design Principles

1. **Discoverability** - Users can figure out what actions are possible
2. **Feedback** - Full and continuous information about results
3. **Conceptual Model** - Design projects understandable image of system
4. **Affordances** - Possible interactions between user and object
5. **Signifiers** - Indicators of where action should take place
6. **Mappings** - Relationship between controls and outcomes
7. **Constraints** - Limiting possible actions to prevent errors

#### Cognitive Load Reduction

- **Knowledge in the World vs. Head**: Design should not require memorization
- **Gulf of Execution**: Minimize mental effort to understand how to use
- **Gulf of Evaluation**: Make system state obvious at all times
- **Natural Mapping**: Controls should relate logically to outcomes

**Key Quote:** *"Make things visible on the execution side so users know what to do, and visible on the evaluation side so people can tell the effects of their actions."*

---

## iOS 26 Liquid Glass Design System

### Overview

Liquid Glass represents Apple's most significant visual evolution since iOS 7, introduced at WWDC 2025. It features translucent, dynamic materials that reflect and refract content.

### Core Characteristics

```swift
// Key Properties of Liquid Glass:
// - Real-time light bending (lensing)
// - Specular highlights responding to device motion
// - Adaptive shadows
// - Interactive behaviors
// - Continuous adaptation to background content
```

### SwiftUI Implementation

#### Basic Glass Effect

```swift
Text("Hello, Liquid Glass!")
    .padding()
    .glassEffect() // Default: .regular variant, .capsule shape

// With customization
Button("Action") { }
    .glassEffect(.regular.interactive, in: .capsule)
```

#### Glass Variants

| Variant | Use Case |
|---------|----------|
| `.regular` | Standard glass material |
| `.clear` | More transparent, subtle effect |
| `.identity` | Minimal glass treatment |
| `.interactive` | Responds to touch (buttons only) |

#### Button Styles

```swift
// Secondary actions
Button("Cancel") { }
    .buttonStyle(.glass)

// Primary actions
Button("Confirm") { }
    .buttonStyle(.glassProminent)
```

#### Glass Effect Container

```swift
// Group multiple glass elements with proper spacing
GlassEffectContainer(spacing: 16) {
    Button("Option A") { }.glassEffect()
    Button("Option B") { }.glassEffect()
    Button("Option C") { }.glassEffect()
}
```

### Design Rules

| DO | DON'T |
|----|-------|
| Use on navigation layer (bars, FABs, toolbars) | Apply to content layer (list rows, cards) |
| Let system handle backgrounds | Use .toolbarBackground() |
| Single glass layer | Stack multiple glass layers |
| Respect native sheet behaviors | Override sheet materials |

### Sheet Behavior

```swift
// iOS 26 sheets are automatically glass
.sheet(isPresented: $showSheet) {
    ContentView()
        .presentationDetents([.medium, .large])
    // Glass background applied automatically
}
```

---

## Claude/Anthropic Design Language

### Brand Colors

| Color Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| **Crail** (Primary) | `#C15F3C` | rgb(193, 95, 60) | Warm rust-orange, primary actions |
| **Cloudy** | `#B1ADA1` | rgb(177, 173, 161) | Neutral gray |
| **Pampas** | `#F4F3EE` | rgb(244, 243, 238) | Off-white background |
| **White** | `#FFFFFF` | rgb(255, 255, 255) | Pure white |

### Design Philosophy

- **Warm & Approachable**: Evokes calmness, professionalism, intellectual depth
- **Soft, Rounded Edges**: Suggests empathy and approachability
- **Pastel Tones**: Gentle, hand-drawn aesthetic
- **Friendly & Accessible**: Not cold or futuristic

### Typography

| Typeface | Usage |
|----------|-------|
| **Styrene** (Commercial Type) | Technical, refined |
| **Tiempos** (Klim) | Charmingly quirky |
| **Copernicus** | Logo/branding, custom serif |

### Visual Identity

- **Logo**: Clean, modern typeface with rounded, humanistic feel
- **Icon**: Abstract starburst/pinwheel suggesting ideas radiating outward
- **Slash**: Reference to underlying code, nod to the future

### Application to MyTasksAI

```swift
// Claude-inspired color palette
enum ClaudeColors {
    static let warmOrange = Color(hex: "C15F3C")  // Primary
    static let softGray = Color(hex: "B1ADA1")    // Secondary
    static let creamWhite = Color(hex: "F4F3EE")  // Background
    static let pureWhite = Color(hex: "FFFFFF")   // Cards
}
```

---

## Apple Notes UX Patterns

### Core Interaction Model

#### Tap-to-Expand Pattern

```
┌─────────────────────────────────────┐
│ Task line (collapsed)               │  ← Tap anywhere
└─────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────┐
│ ┌─────────────────────────────────┐ │
│ │                                 │ │
│ │    Task Detail Sheet            │ │  ← Slides up
│ │    (Expanded view)              │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### Checklist Behavior

- **Creation**: Tap checklist button → empty checkbox appears with cursor
- **Completion**: Tap checkbox → item dims, moves to bottom
- **Logical Constraint**: Empty checkbox on Return → auto-delete
- **Visual Feedback**: Checkmark icon + dimmed text + strikethrough

#### Collapsible Sections

```swift
// Collapse/expand pattern
struct CollapsibleSection<Content: View>: View {
    @State private var isExpanded = true
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                    Text(title)
                        .font(.headline)
                }
            }

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
```

### Text-First Design

- **Free-form input**: No rigid forms or modals
- **Natural language**: Type as you think
- **Inline editing**: Edit in place, no separate edit mode
- **Keyboard-first**: Optimized for typing flow

---

## Best-in-Class Productivity Apps

### Tiimo - iPhone App of the Year 2025

#### Design Philosophy

- **Scandinavian Minimalism**: Clean, warm, simple
- **Co-designed with Neurodivergent Users**: ADHD/autism-friendly
- **Non-Punishing UX**: No red warnings, no "overdue" guilt messages

#### Key Features

| Feature | Implementation |
|---------|---------------|
| **Visual Timeline** | Color-coded, combats time blindness |
| **Low Dopamine Design** | Avoids flashy, addictive elements |
| **Emotion-Safe Notifications** | Soft, neutral tones |
| **AI Task Breakdown** | Large tasks → actionable steps |
| **Focus Timer** | Calming countdown |

#### User Insight

*"Tiimo works best not as a productivity app, but as a 'gentle routine companion.' It doesn't make you faster; it makes you calmer and more consistent."*

### Things 3 - Apple Design Award Winner (2x)

#### Design Philosophy

- **German Engineering**: Designed to be perfectly functional
- **Intentional Minimalism**: Nothing without purpose
- **Balance**: Between Apple Notes simplicity and OmniFocus power

#### UI/UX Excellence

```
"This is the most beautiful Mac and iOS app that I have ever used—full stop.
The level of care and aesthetic sensitivity that's gone into every pixel is
staggering, and each interface gesture invokes subtle, deeply satisfying
animations."
```

#### Key Design Elements

- **Clean animations** with minimal visual weight
- **Keyboard shortcuts** that are second to none
- **Intuitive gestures** that feel natural
- **Minimal learning curve** with powerful features

### Todoist - 47 Million Users

#### 2025 Features

| Feature | Benefit |
|---------|---------|
| **Natural Language Input** | "Tomorrow at 3pm" parsed automatically |
| **AI Subtask Suggestions** | Breaks down complex tasks |
| **Smart Scheduling** | Learns patterns, suggests times |
| **Todoist Ramble** | Voice to structured tasks |
| **Multiple Views** | List, Board (Kanban), Calendar |

#### Productivity Insight

*"Users who master natural language input complete 34% more tasks on average—friction kills productivity."*

---

## Productivity Science & Deep Work

### Cal Newport - Deep Work Principles

#### Core Philosophy

*"Deep work is the ability to focus without distraction on a cognitively demanding task. It's a skill that allows you to quickly master complicated information and produce better results in less time."*

#### Time Blocking Method

```
┌──────────────────────────────────────┐
│ 8:00 - 9:30   │ Deep Work Block 1    │
│ 9:30 - 10:00  │ Email / Admin        │
│ 10:00 - 12:00 │ Deep Work Block 2    │
│ 12:00 - 1:00  │ Lunch                │
│ 1:00 - 3:00   │ Meetings             │
│ 3:00 - 5:00   │ Deep Work Block 3    │
└──────────────────────────────────────┘
```

#### Key Principles

1. **Deep vs. Shallow Work**: Distinguish cognitively demanding from admin tasks
2. **Schedule Every Minute**: Give every block a job
3. **Start Small**: Build focus stamina gradually (max 90 min initially)
4. **Activation Cost**: Every phone glance = 10 min focus loss
5. **Productive Meditation**: Use physical activity for mental problem-solving

**Key Quote:** *"A deep life is a good life."*

### Sam Altman - Productivity System

#### Three Pillars

1. **Do important things** - Direction > Speed
2. **Don't waste time on stupid things** - Ruthless prioritization
3. **Write lists** - Externalize cognition

#### List-Making Method

```swift
// Sam Altman's approach
struct ProductivitySystem {
    var yearlyGoals: [Goal]
    var monthlyGoals: [Goal]
    var dailyTasks: [Task]

    // Key insight: No complex categorization
    // Maximum: star next to really important items

    func prioritize() {
        // Re-transcribe lists frequently to think through priorities
        // Paper preferred: accessible, no tech friction
    }
}
```

#### Energy Management

| Time Block | Activity Type |
|------------|--------------|
| Morning (peak) | Focused, demanding work |
| Afternoon | Meetings, collaborative work |
| No external scheduling | Protected deep work time |

#### Key Insights

- *"It doesn't matter how fast you move if it's in a worthless direction."*
- *"The right goal is to allocate your year optimally, not your day."*
- *"Compound growth works in careers—a small productivity gain over 50 years is worth a lot."*

---

## SwiftUI Best Practices

### Modern Patterns (iOS 26 / Swift 6.2)

#### State Management

```swift
// Use @Observable (not ObservableObject)
@Observable
class TasksViewModel {
    var tasks: [TaskItem] = []
    var isLoading = false
    var selectedTask: TaskItem?

    @MainActor
    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        tasks = await fetchTasks()
    }
}

// In View
struct TasksView: View {
    @State private var viewModel = TasksViewModel()

    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .task {
            await viewModel.loadTasks()
        }
    }
}
```

#### Navigation

```swift
// Use NavigationStack (not NavigationView)
NavigationStack {
    List(tasks) { task in
        NavigationLink(value: task) {
            TaskRow(task: task)
        }
    }
    .navigationDestination(for: TaskItem.self) { task in
        TaskDetailView(task: task)
    }
}
```

#### Async Data Loading

```swift
// Use .task (not .onAppear { Task { } })
.task {
    await viewModel.loadData()  // Auto-cancels on disappear
}

// With ID for refresh
.task(id: refreshTrigger) {
    await viewModel.loadData()
}
```

### Animation Best Practices

```swift
// Spring animations for natural feel
withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
    isExpanded.toggle()
}

// Staggered entrance
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemView(item: item)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8)
                .delay(Double(index) * 0.05),
            value: appeared
        )
}

// Respect accessibility
@Environment(\.accessibilityReduceMotion) private var reduceMotion

if reduceMotion {
    // Instant state change
} else {
    withAnimation { /* animated change */ }
}
```

### Performance Patterns

```swift
// Lazy loading
LazyVStack(spacing: 12) {
    ForEach(tasks) { task in
        TaskRow(task: task)
    }
}

// Equatable for view diffing
struct TaskRow: View, Equatable {
    let task: TaskItem

    static func == (lhs: TaskRow, rhs: TaskRow) -> Bool {
        lhs.task.id == rhs.task.id &&
        lhs.task.title == rhs.task.title &&
        lhs.task.isCompleted == rhs.task.isCompleted
    }
}
```

---

## Implementation Patterns

### Apple Notes-Style Task Sheet

```swift
struct NotesStyleTaskSheet: View {
    @Binding var tasks: [TaskItem]
    @State private var expandedTaskId: UUID?
    @FocusState private var focusedTaskId: UUID?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach($tasks) { $task in
                    TaskLineView(
                        task: $task,
                        isExpanded: expandedTaskId == task.id,
                        isFocused: focusedTaskId == task.id,
                        onTap: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                expandedTaskId = expandedTaskId == task.id ? nil : task.id
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
```

### Expandable Task Line

```swift
struct TaskLineView: View {
    @Binding var task: TaskItem
    let isExpanded: Bool
    let isFocused: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed: Simple line
            HStack(spacing: 12) {
                // Checkbox
                TaskCheckbox(isCompleted: $task.isCompleted)

                // Title
                Text(task.title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)

                Spacer()

                // Calorie/metadata (like the reference app)
                if let metadata = task.metadata {
                    Text(metadata)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Expanded: Full detail card
            if isExpanded {
                TaskDetailCard(task: task)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            }

            // Divider
            if !isExpanded {
                Divider()
                    .padding(.leading, 44)
            }
        }
    }
}
```

### Claude-Inspired Theme

```swift
enum ClaudeTheme {
    enum Colors {
        // Primary - Warm Orange (Crail)
        static let primary = Color(red: 0.757, green: 0.373, blue: 0.235)

        // Neutrals
        static let background = Color(red: 0.957, green: 0.953, blue: 0.933)
        static let cardBackground = Color.white
        static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.15)
        static let textSecondary = Color(red: 0.45, green: 0.43, blue: 0.40)

        // AI Accent (keep existing iridescent for AI features)
        static let aiPurple = Color(red: 0.6, green: 0.3, blue: 1.0)
        static let aiBlue = Color(red: 0.3, green: 0.5, blue: 1.0)
    }

    enum Typography {
        // Rounded for friendliness (like Claude's Styrene)
        static let title = Font.system(.title, design: .rounded, weight: .semibold)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
    }
}
```

---

## Genius-Level Feature Ideas

### Inspired by Top Thinkers & Apps

#### 1. **"One Thing" Focus Mode** (Sam Altman)

```swift
// Surface the single most important task
struct OneFocusView: View {
    let topTask: TaskItem

    var body: some View {
        VStack(spacing: 32) {
            Text("Right now, focus on:")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(topTask.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Deep work timer
            DeepWorkTimer(suggestedMinutes: topTask.estimatedMinutes ?? 25)
        }
        .padding(40)
    }
}
```

#### 2. **Gentle Routine Companion** (Tiimo)

- No "overdue" warnings - tasks just roll forward
- Soft notification sounds
- Celebration on completion, no shame on miss
- Visual timeline showing day flow

#### 3. **Time Blindness Combat** (Tiimo + Cal Newport)

```swift
struct TimeBlockVisualizer: View {
    let tasks: [TaskItem]
    let currentTime: Date

    var body: some View {
        // Visual representation of day
        // Shows not just WHAT but WHEN and HOW LONG
        GeometryReader { geo in
            ZStack {
                // Time blocks as proportional bars
                ForEach(tasks) { task in
                    TaskTimeBlock(
                        task: task,
                        totalHeight: geo.size.height
                    )
                }

                // Current time indicator
                CurrentTimeLine(time: currentTime)
            }
        }
    }
}
```

#### 4. **AI Task Decomposition** (Todoist + Cal Newport)

```swift
struct SmartBreakdown: View {
    let complexTask: String
    @State private var subtasks: [SubTask] = []

    // AI breaks "Launch website" into:
    // 1. Finalize homepage copy (30m)
    // 2. Test contact form (15m)
    // 3. Check mobile responsiveness (20m)
    // 4. Set up analytics (15m)
    // 5. Deploy to production (10m)
    // 6. Announce on social media (10m)
}
```

#### 5. **Reflection & Learning Loop** (Growth Mindset)

```swift
struct PostTaskReflection: View {
    let completedTask: TaskItem

    var body: some View {
        VStack(spacing: 16) {
            Text("How did it go?")
                .font(.headline)

            // Quick feedback
            HStack(spacing: 24) {
                ReflectionButton(emoji: "😰", label: "Hard")
                ReflectionButton(emoji: "😐", label: "Normal")
                ReflectionButton(emoji: "🚀", label: "Easy")
            }

            // Time accuracy feedback
            if let estimated = completedTask.estimatedMinutes,
               let actual = completedTask.actualMinutes {
                TimeAccuracyFeedback(estimated: estimated, actual: actual)
            }
        }
    }
}
```

#### 6. **Context Switching Minimizer** (Cal Newport)

```swift
// Group similar tasks together
struct BatchedTasksView: View {
    let batches: [TaskBatch]

    // Batches like:
    // - "Quick Replies" (all 5-min tasks)
    // - "Deep Writing" (all content creation)
    // - "Admin & Planning" (all organizing tasks)
}
```

#### 7. **Energy-Aware Scheduling** (Sam Altman)

```swift
struct EnergyAwareScheduler {
    func suggestOptimalTime(for task: TaskItem, user: UserProfile) -> Date {
        // Consider:
        // - User's peak energy hours (from settings or learning)
        // - Task cognitive demand
        // - Current calendar gaps
        // - Historical completion patterns
    }
}
```

#### 8. **Natural Capture** (Apple Notes + Todoist)

```swift
struct NaturalCaptureView: View {
    @State private var freeformText = ""

    var body: some View {
        TextEditor(text: $freeformText)
            .onChange(of: freeformText) { _, newValue in
                // Parse for:
                // - Dates ("tomorrow", "next Monday")
                // - Times ("at 3pm", "morning")
                // - Priorities ("important", "urgent")
                // - Context ("@work", "@home")
            }
    }
}
```

### Implementation Priority

| Feature | Impact | Effort | Priority |
|---------|--------|--------|----------|
| Apple Notes-style sheet | High | Medium | 1 |
| Tap-to-expand tasks | High | Low | 1 |
| Claude warm color palette | Medium | Low | 2 |
| Time block visualization | High | High | 3 |
| AI task breakdown | High | Medium | 3 |
| Gentle notifications | Medium | Low | 4 |
| Energy-aware scheduling | Medium | High | 5 |

---

## Quick Reference Card

### Core Design Principles

1. **Less, but better** (Dieter Rams)
2. **Make things visible** (Don Norman)
3. **Direction > Speed** (Sam Altman)
4. **Deep work > busy work** (Cal Newport)
5. **Gentle, not punishing** (Tiimo)
6. **Delightfully minimal** (Things 3)

### Color Palette (Claude-Inspired)

```swift
// Primary
let warmOrange = Color(hex: "C15F3C")

// Backgrounds
let creamWhite = Color(hex: "F4F3EE")
let pureWhite = Color(hex: "FFFFFF")

// Text
let charcoal = Color(hex: "262626")
let warmGray = Color(hex: "737066")

// AI Accents (keep iridescent)
let aiPurple = Color(hex: "994DFF")
let aiBlue = Color(hex: "4D80FF")
```

### Animation Standards

```swift
// Interactions
let tapResponse = Animation.spring(response: 0.35, dampingFraction: 0.85)
let expandCollapse = Animation.spring(response: 0.4, dampingFraction: 0.8)
let sheetPresent = Animation.spring(response: 0.5, dampingFraction: 0.85)

// Continuous
let aiPulse = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
let gentleFloat = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
```

---

## Sources & References

### Design Masters
- [Dieter Rams 10 Principles](https://designmuseum.org/discover-design/all-stories/what-is-good-design-a-quick-look-at-dieter-rams-ten-principles)
- [Don Norman - Design of Everyday Things](https://www.nngroup.com/books/the-design-of-everyday-things/)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### iOS 26 Liquid Glass
- [Apple WWDC 2025 - Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Liquid Glass Reference (GitHub)](https://github.com/conorluddy/LiquidGlassReference)
- [Apple Newsroom - New Software Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)

### Claude/Anthropic
- [Claude Brand Color Palette](https://mobbin.com/colors/brand/claude)
- [Anthropic Brand by Geist](https://geist.co/work/anthropic)

### Productivity Apps
- [Tiimo - Visual Planner](https://www.tiimoapp.com/)
- [Things 3 Features](https://culturedcode.com/things/features/)
- [Todoist Review 2025](https://www.joshdolin.com/mindscapes-blog/todoist-review-2025)

### Productivity Science
- [Cal Newport - Deep Work](https://calnewport.com/deep-work-rules-for-focused-success-in-a-distracted-world/)
- [Sam Altman - Productivity](https://blog.samaltman.com/productivity)
- [Time Block Planner](https://www.timeblockplanner.com/)

### SwiftUI Resources
- [Apple SwiftUI](https://developer.apple.com/swiftui/)
- [Design+Code SwiftUI Course](https://designcode.io/swiftui/)
- [A Designer's Guide to SwiftUI](https://swiftui.design/guide)

---

*Last updated: December 2025*
*Compiled for MyTasksAI Apple Notes Redesign*
