# Comprehensive Build Error Fixes

## ✅ Fixed Issues

### 1. LiquidGlassButton.swift (Line 168)
- **Error**: `Type 'LiquidGlassDesignSystem.GlassTints' has no member 'primary'`
- **Fix**: Changed to `LiquidGlassDesignSystem.GlassTints.interactive`

### 2. LiquidGlassButton.swift (Line 230)
- **Error**: `Cannot call value of non-function type 'AngularGradient'`
- **Fix**: Replaced `LiquidGlassDesignSystem.Gradients.prismaticBorder(rotation: borderRotation)` with inline AngularGradient using startAngle/endAngle

### 3. LiquidGlassTextField.swift (Line 311)
- **Error**: `Cannot call value of non-function type 'AngularGradient'`
- **Fix**: Same as above - replaced with inline AngularGradient

### 4. Theme.swift - Added Missing Colors
- **Added**: `Theme.Colors.streakGold` and `Theme.Colors.completionMint`

### 5. CosmicWidgetDesignSystem.swift - Added Missing Properties
- **Added**: `CosmicWidget.Widget.violetSecondary`
- **Added**: `CosmicWidget.Widget.electricCyanGradient`
- **Added**: `CosmicWidget.Widget.violetGradient`
- **Added**: `CosmicWidget.Radius.large`
- **Added**: `CosmicWidget.Typography.meta`
- **Added**: `CosmicWidget.Spacing.relaxed`, `formField`, `comfortable`

---

## 🔧 Remaining Fixes Needed

### StatsBottomSheet.swift

#### Line 155: Extra argument 'iconColor' in call
**Problem**: The `StatCard` component is being called with `iconColor:` parameter but expects `color:` instead.

**Fix**:
```swift
// Find line 155 and change:
StatCard(icon: "...", value: "...", label: "...", iconColor: someColor)
// To:
StatCard(icon: "...", value: "...", label: "...", color: someColor)
```

#### Line 304: Invalid redeclaration of 'StatCard'
**Problem**: `StatCard` is declared twice in the file.

**Fix**: Remove the duplicate declaration of `StatCard`. Keep only one definition.

---

### Achievement.swift

#### Line 330: Type 'Theme.Colors' has no member 'completionMint'
**Status**: ✅ Already fixed by adding the color to Theme.swift

---

### GoalCardView.swift

#### Lines 89 & 97: Missing import of 'AppIntents'
**Problem**: Using Button initializer that requires AppIntents framework.

**Fix**: Add import at the top of the file:
```swift
import SwiftUI
import AppIntents  // Add this line
```

---

### GoalColorfulComponents.swift

#### Line 240: Invalid redeclaration of 'MilestoneBadge'
**Problem**: `MilestoneBadge` is declared twice in the file.

**Fix**: Remove the duplicate declaration of `MilestoneBadge`. Keep only one definition.

#### Preview Errors (Generated code)
**Problem**: Preview macro is calling an initializer with wrong parameters.

**Fix**: Update the Preview to match the correct initializer signature for the component being previewed.

---

### GoalIntents.swift

#### Line 16: Extra argument 'systemImage' in call
**Problem**: Using `systemImage:` parameter where it should be `systemName:` or just `image:`.

**Fix**:
```swift
// Find line 16 and change:
Image(systemImage: "...")
// To:
Image(systemName: "...")
```

---

### GoalWidget.swift

#### Line 463: 'main' attribute can only apply to one type in a module
**Problem**: Multiple `@main` attributes in the project.

**Fix**: Remove the `@main` attribute from GoalWidget.swift. Only VeloceApp.swift should have `@main`.

---

### LiquidGlassAuthViews.swift

#### Lines 49 & 290: Extra argument 'isFocused' in call
**Problem**: The `LiquidGlassTextField` component doesn't accept `isFocused` as a direct parameter.

**Fix**: Remove the `isFocused:` parameter from the call. The component manages focus internally.
```swift
// Change:
LiquidGlassTextField("Email", text: $email, isFocused: $focusedField == .email)
// To:
LiquidGlassTextField("Email", text: $email)
```

#### Lines 240 & 533: Value of type 'HapticsService' has no member 'errorFeedback'
**Problem**: Method is named `error()` not `errorFeedback()`.

**Fix**:
```swift
// Change:
HapticsService.shared.errorFeedback()
// To:
HapticsService.shared.error()
```

---

### LiquidGlassTaskComponents.swift

#### Lines 62 & 63: Cannot convert value of type 'TaskType' to expected argument type 'String'
**Problem**: Passing `TaskType` enum where String is expected.

**Fix**: Convert to string:
```swift
// Change:
someFunction(taskType)
// To:
someFunction(taskType.rawValue)
// Or if TaskType has a string representation method:
someFunction(taskType.description)
```

---

### GamificationService.swift

#### Line 611: Switch must be exhaustive
**Problem**: Switch statement doesn't handle all cases of an enum.

**Fix**: Add missing cases or add a `default` case:
```swift
switch achievementType {
case .firstTask:
    // handle
case .tenTasks:
    // handle
// ... other cases
@unknown default:
    break
}
```

---

### LiquidGlassAuthView.swift

#### Lines 208, 226, 236: Missing CosmicWidget.Spacing properties
**Status**: ✅ Already fixed by adding the spacing properties to CosmicWidgetDesignSystem.swift

---

### GoalDetailSheet.swift

#### Line 268: Incorrect argument label (have 'label:', expected 'title:')
**Fix**:
```swift
// Change:
GoalQuickActionButton(icon: "...", label: "...", color: ...)
// To:
GoalQuickActionButton(icon: "...", title: "...", color: ...)
```

#### Line 534: Invalid redeclaration of 'GoalQuickActionButton'
**Fix**: Remove duplicate declaration of `GoalQuickActionButton`.

---

### GoalsContentView.swift

#### Line 170: Incorrect argument label (have 'color:', expected 'iconColor:')
**Fix**:
```swift
// Change:
GoalStatCard(icon: "...", value: "...", label: "...", color: someColor)
// To:
GoalStatCard(icon: "...", value: "...", label: "...", iconColor: someColor)
```

#### Line 484: Invalid redeclaration of 'GoalStatCard'
**Fix**: Remove duplicate declaration of `GoalStatCard`.

---

### ProfileSheetView.swift

#### Lines 144, 476: Generic parameter 'Content' could not be inferred
**Problem**: Likely a malformed view builder or missing generic constraint.

**Context needed**: Need to see the actual code to provide specific fix.

#### Line 146, 478: Missing argument for parameter 'content' in call
**Fix**: Add the missing `content` parameter with a closure:
```swift
SomeView(title: "...", icon: "...") {
    // content closure here
    Text("Content")
}
```

#### Line 441: Incorrect argument label (have 'iconColor:', expected 'color:')
**Fix**:
```swift
// Change:
SettingsRow(title: "...", subtitle: "...", icon: "...", iconColor: .blue, isOn: $setting)
// To:
SettingsRow(title: "...", subtitle: "...", icon: "...", color: .blue, isOn: $setting)
```

---

### Social Views (PactCardView.swift, PactDetailView.swift, CreatePactSheet.swift)

#### Multiple lines: Type 'Theme.Colors' has no member 'streakGold' or 'completionMint'
**Status**: ✅ Already fixed by adding these colors to Theme.swift

---

### ChatTasksView.swift

#### Lines 631, 849: Missing CosmicWidget.Typography.meta
**Status**: ✅ Already fixed by adding the typography property

#### Line 1008: Missing CosmicWidget.Widget.electricCyanGradient
**Status**: ✅ Already fixed by adding the gradient

#### Line 1009: Missing CosmicWidget.Radius.large
**Status**: ✅ Already fixed by adding the radius property

---

### MainContainerView.swift

#### Multiple lines: Missing CosmicWidget.Widget.violetSecondary and violetGradient
**Status**: ✅ Already fixed by adding these properties

---

### VeloceApp.swift

#### Line 14: 'main' attribute can only apply to one type in a module
**Fix**: Remove `@main` from GoalWidget.swift. Keep it only in VeloceApp.swift.

#### Line 134: Value of type 'AppViewModel' has no member 'signIn'
**Problem**: Method might be named differently or doesn't exist.

**Fix**: Check AppViewModel for the correct method name. It might be:
- `login()` instead of `signIn()`
- `authenticate()` instead of `signIn()`
- Or the method needs to be added to AppViewModel

---

## 📝 Pattern Fixes Summary

### Common Issues Found:

1. **Parameter Name Mismatches**
   - `iconColor` vs `color`
   - `label` vs `title`
   - `systemImage` vs `systemName`

2. **Duplicate Declarations**
   - Remove duplicate `StatCard`, `MilestoneBadge`, `GoalQuickActionButton`, `GoalStatCard` declarations

3. **Missing Imports**
   - Add `import AppIntents` to GoalCardView.swift

4. **Multiple @main Attributes**
   - Remove `@main` from GoalWidget.swift

5. **Method Name Mismatches**
   - `errorFeedback()` should be `error()` in HapticsService

6. **Enum to String Conversion**
   - Use `.rawValue` or appropriate string conversion for TaskType

---

## 🎯 Priority Order for Fixes

1. **High Priority** (Blocking compilation):
   - Remove duplicate `@main` attributes
   - Add missing imports (AppIntents)
   - Fix HapticsService method names

2. **Medium Priority** (Component errors):
   - Fix parameter name mismatches
   - Remove duplicate component declarations
   - Fix enum conversions

3. **Low Priority** (Already fixed or auto-resolved):
   - Color/spacing properties (already added)
   - Gradient properties (already added)

---

## 🔍 Files Modified

✅ **LiquidGlassButton.swift** - Fixed prismatic border and GlassTints
✅ **LiquidGlassTextField.swift** - Fixed prismatic border
✅ **Theme.swift** - Added missing colors
✅ **CosmicWidgetDesignSystem.swift** - Added missing properties

---

## 📌 Next Steps

1. Apply the remaining fixes listed above in priority order
2. Build the project to verify all errors are resolved
3. Test the affected components to ensure functionality is preserved
4. Review and remove any truly unused duplicate components

