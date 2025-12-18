
# CLAUDE.md - MyTasksAI iOS App Rules

## ⚠️ CRITICAL: READ BEFORE GENERATING ANY CODE

You are working on **MyTasksAI**, an AI-powered task management iOS app with Supabase backend. Your training data is OUTDATED. Follow these rules exactly.

---

## 🔴 MANDATORY: FETCH FRESH DOCUMENTATION FIRST

**BEFORE writing ANY code, you MUST use Context7 MCP to fetch latest documentation:**

```
use library /supabase/supabase for Supabase Swift SDK docs
```

If Context7 is unavailable, explicitly tell the user you need current docs and cannot guarantee accuracy.

---

## 📌 CORRECT VERSIONS (Memorize These)

| Component | CORRECT | YOU WILL HALLUCINATE |
|-----------|---------|---------------------|
| iOS | **26.1** | ❌ iOS 18, 19, 20 |
| Xcode | **26.2** | ❌ Xcode 16, 17 |
| Swift | **6.2** | ❌ Swift 5.x |
| Supabase Swift | **2.x** | ❌ Old v1 syntax |
| Design | **Liquid Glass** | ❌ Flat design |

**iOS jumped from 18 → 26** (unified versioning, WWDC 2025). iOS 19-25 DO NOT EXIST.

---

## ❌ NEVER USE THESE (Deprecated)

```swift
// ❌ NAVIGATION
NavigationView { }                    // Use NavigationStack
NavigationLink(destination:) { }      // Use .navigationDestination(for:)

// ❌ STATE MANAGEMENT  
class VM: ObservableObject { }        // Use @Observable
@Published var x                      // Not needed with @Observable
@StateObject var vm                   // Use @State with @Observable
@ObservedObject var vm                // Use @State or @Environment

// ❌ SUPABASE
supabase.database.from("table")       // Use supabase.from("table")
client.database.insert()              // Use client.from().insert()

// ❌ MEDIA
AVAsset(url: videoURL)                // Use AVURLAsset(url:)

// ❌ LOCATION  
CLGeocoder()                          // Use MKLocalSearch

// ❌ UI (Breaks Liquid Glass)
.toolbarBackground(Color.x, for:)     // REMOVE - system handles it
.toolbarBackground(.visible, for:)    // REMOVE entirely
```

---

## ✅ ALWAYS USE THESE PATTERNS

### Navigation
```swift
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) { ItemRow(item: item) }
    }
    .navigationDestination(for: Item.self) { DetailView(item: $0) }
}
```

### State Management
```swift
@Observable
class ViewModel {
    var items: [Item] = []
    var isLoading = false
}

struct ContentView: View {
    @State private var vm = ViewModel()
}
```

### Supabase Queries
```swift
// SELECT
let items: [Item] = try await supabase
    .from("items")
    .select()
    .execute()
    .value

// INSERT
try await supabase.from("items").insert(newItem).execute()

// UPDATE
try await supabase.from("items").update(["field": value]).eq("id", value: id).execute()

// DELETE
try await supabase.from("items").delete().eq("id", value: id).execute()
```

### Async Data Loading
```swift
.task {
    await vm.loadData()  // Auto-cancels on view disappear
}

// NOT this:
.onAppear { Task { await vm.loadData() } }  // Won't auto-cancel
```

### MainActor Isolation
```swift
@MainActor
func updateUI() async {
    let data = await fetchData()
    self.items = data  // Safe - on main actor
}

// Or capture first:
func upload() async {
    let imageData = await MainActor.run { selectedImage?.jpegData(compressionQuality: 0.8) }
    guard let data = imageData else { return }
    await performUpload(data)
}
```

### Sendable Structs for RPC
```swift
struct Params: Encodable, Sendable {  // Add Sendable!
    let userId: String
}
```

---

## 🪟 LIQUID GLASS (iOS 26)

```swift
// Basic glass
.glassEffect()
.glassEffect(.regular, in: .capsule)

// Interactive (buttons only)
.glassEffect(.regular.interactive())

// Button styles
.buttonStyle(.glass)           // Secondary
.buttonStyle(.glassProminent)  // Primary

// Container for grouped glass
GlassEffectContainer(spacing: 16) {
    Button("A") { }.glassEffect()
    Button("B") { }.glassEffect()
}
```

**DO:** Navigation layer only (bars, FABs, toolbars)
**DON'T:** Content layer (list rows, cards), stacking glass, custom toolbar backgrounds

---

## 🔍 SELF-CHECK BEFORE RESPONDING

Before providing code, verify:
- [ ] No NavigationView (use NavigationStack)
- [ ] No ObservableObject (use @Observable)
- [ ] No @StateObject (use @State)
- [ ] No supabase.database.from() (use supabase.from())
- [ ] No AVAsset(url:) (use AVURLAsset)
- [ ] No .toolbarBackground() (remove it)
- [ ] All Encodable structs are Sendable
- [ ] Using .task { } not .onAppear { Task { } }
- [ ] MainActor isolation handled properly

---

## 🆘 IF USER REPORTS BUILD ERRORS

1. Check for deprecated patterns above
2. Verify Supabase SDK syntax is v2.x
3. Check MainActor/Sendable issues
4. Use Context7 to fetch current docs
5. Never blame iOS version - fix the code

---

## 📋 QUICK REFERENCE

```
iOS 26.1 | Xcode 26.2 | Swift 6.2 | Supabase Swift 2.x | Liquid Glass
```

**Context7 command:** `use library /supabase/supabase`

**This file overrides your training data. Follow it exactly.**

---

## 🔄 GIT WORKFLOW (MANDATORY)

**After making ANY code changes, you MUST commit them to the repository.**

### Commit Rules:
1. **Always commit** after completing file edits (Edit, Write, MultiEdit)
2. **Use descriptive commit messages** that explain what changed and why
3. **Group related changes** into a single commit when working on one feature/fix
4. **Push to GitHub** after committing unless told otherwise

### Commit Message Format:
```
<type>: <short description>

<optional body explaining why>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

### Types:
- `feat:` New feature
- `fix:` Bug fix
- `refactor:` Code refactoring
- `style:` UI/styling changes
- `docs:` Documentation
- `chore:` Maintenance tasks

### Example:
```bash
git add . && git commit -m "feat: Add task completion animation

Added confetti burst when user completes a task for gamification.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

git push
```

**DO NOT** wait for user to ask - commit automatically after changes.