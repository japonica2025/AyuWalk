# AyuWalk Component System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish AyuWalk's four-layer SwiftUI component system and migrate the most repeated current UI into it.

**Architecture:** Keep visual decisions in `AyuWalkApp/Design`, move business-free UI into `Views/Primitives`, move AyuWalk-specific reusable UI into `Views/Patterns`, and add `Views/Scenes` scaffolds for shared page and sheet structure. Preserve existing behavior while creating clear homes for all future UI work.

**Tech Stack:** SwiftUI, AyuWalkCore models, existing AyuWalk app target, XcodeBuildMCP iOS simulator verification.

---

## File Structure

Create:

- `AyuWalkApp/Views/Primitives/AWButton.swift`: button variants and icon button.
- `AyuWalkApp/Views/Primitives/AWCard.swift`: card shell and empty state.
- `AyuWalkApp/Views/Primitives/AWTextField.swift`: consistent text input wrapper.
- `AyuWalkApp/Views/Primitives/AWChip.swift`: selectable chip, status pill, metric tile.
- `AyuWalkApp/Views/Primitives/AWFloatingTabBar.swift`: existing floating tab bar.
- `AyuWalkApp/Views/Scenes/AWPageScaffold.swift`: shared full-page and sheet scaffolds.
- `AyuWalkApp/Views/Patterns/Journal/AWJournalComponents.swift`: journal page, block, sticker components.
- `AyuWalkApp/Views/Patterns/Budget/AWBudgetComponents.swift`: budget total card and participant row.
- `AyuWalkApp/Views/Patterns/Packing/AWPackingComponents.swift`: packing progress card, add form, item row.
- `docs/component-system.md`: human-facing guide for design/development alignment.

Modify:

- `AyuWalkApp/Design/AyuWalkTheme.swift`: add missing semantic size tokens used by migrated components.
- `AyuWalkApp/Views/Components/AyuWalkComponents.swift`: remove moved component definitions after replacements compile.
- `AyuWalkApp/Views/Components/AWJournalComponents.swift`: move contents to `Patterns/Journal`.
- `AyuWalkApp/Views/Plan/BudgetPlannerView.swift`: replace local card/input/button styling with budget patterns and primitives.
- `AyuWalkApp/Views/Plan/PackingListView.swift`: replace local card/input/button styling with packing patterns and primitives.
- `AyuWalkApp/Views/Journal/JournalPreviewView.swift`: update imports/references after journal component move.
- `AyuWalkApp/Views/Components/JournalPageCard.swift`: update references after journal component move.

Test:

- `AyuWalkCore/Tests/AyuWalkCoreTests/BudgetSplitCalculatorTests.swift`: existing split behavior remains unchanged.
- App build and simulator run after each structural batch.

---

### Task 1: Add Missing Design Tokens

**Files:**

- Modify: `AyuWalkApp/Design/AyuWalkTheme.swift`

- [ ] **Step 1: Add semantic sizing tokens**

Add `AyuWalkSize` near the existing token enums:

```swift
enum AyuWalkSize {
    static let iconButton: CGFloat = 40
    static let compactIconButton: CGFloat = 34
    static let largeIconButton: CGFloat = 44
    static let formControlHeight: CGFloat = 44
    static let floatingTabWidth: CGFloat = 72
    static let floatingTabHeight: CGFloat = 35
    static let stickerControl: CGFloat = 22
    static let stickerHandle: CGFloat = 18
}
```

- [ ] **Step 2: Add semantic motion tokens**

Add:

```swift
enum AyuWalkMotion {
    static let quick = Animation.spring(response: 0.28, dampingFraction: 0.88)
    static let standard = Animation.spring(response: 0.45, dampingFraction: 0.88)
}
```

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build
```

Expected: `BUILD SUCCEEDED`.

### Task 2: Create Primitive Layer

**Files:**

- Create: `AyuWalkApp/Views/Primitives/AWButton.swift`
- Create: `AyuWalkApp/Views/Primitives/AWCard.swift`
- Create: `AyuWalkApp/Views/Primitives/AWTextField.swift`
- Create: `AyuWalkApp/Views/Primitives/AWChip.swift`
- Create: `AyuWalkApp/Views/Primitives/AWFloatingTabBar.swift`
- Modify: `AyuWalkApp/Views/Components/AyuWalkComponents.swift`

- [ ] **Step 1: Create `AWButton.swift`**

Move the behavior of `AWPrimaryButton`, `AWActionCapsuleButton`, and `AWPlainIconButton` into this file. Keep compatibility type names for now so existing screens do not need a full rename in the same step.

- [ ] **Step 2: Create `AWCard.swift`**

Move `AWPanel`, `AWCardChrome`, `AWEmptyState`, and `AWIconBadge` into this file.

- [ ] **Step 3: Create `AWTextField.swift`**

Add:

```swift
import SwiftUI

struct AWTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textFieldStyle(.plain)
            .font(AyuWalkTypography.bodyStrong)
            .foregroundStyle(AyuWalkTheme.ink)
            .padding(.horizontal, AyuWalkSpacing.md)
            .frame(height: AyuWalkSize.formControlHeight)
            .background(AyuWalkTheme.surface)
            .clipShape(Capsule())
    }
}
```

- [ ] **Step 4: Create `AWChip.swift`**

Move `AWStatusPill`, `AWSelectableChip`, and `AWMetricTile` into this file.

- [ ] **Step 5: Create `AWFloatingTabBar.swift`**

Move `AWFloatingTabItem` and `AWFloatingTabBar` into this file.

- [ ] **Step 6: Remove moved definitions from `AyuWalkComponents.swift`**

Keep `AyuWalkComponents.swift` temporarily if any older component remains. If it becomes empty, delete it from the project and verify Xcode membership.

- [ ] **Step 7: Build**

Run the app build command from Task 1.

Expected: `BUILD SUCCEEDED`.

### Task 3: Create Scene Scaffolds

**Files:**

- Create: `AyuWalkApp/Views/Scenes/AWPageScaffold.swift`

- [ ] **Step 1: Add page and sheet scaffolds**

Create:

```swift
import SwiftUI

struct AWPageScaffold<Content: View>: View {
    var background: Color = AyuWalkTheme.canvas
    var horizontalPadding: CGFloat = AyuWalkSpacing.lg
    var topPadding: CGFloat = AyuWalkSpacing.md
    var bottomPadding: CGFloat = 132
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AyuWalkSpacing.xl) {
                content
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
        }
        .background(background)
    }
}

struct AWSheetScaffold<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            ZStack {
                AyuWalkTheme.pageBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AyuWalkSpacing.lg) {
                        content
                    }
                    .padding(AyuWalkSpacing.xl)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

- [ ] **Step 2: Build**

Run the app build command from Task 1.

Expected: `BUILD SUCCEEDED`.

### Task 4: Move Journal Patterns

**Files:**

- Create: `AyuWalkApp/Views/Patterns/Journal/AWJournalComponents.swift`
- Modify: `AyuWalkApp/Views/Components/AWJournalComponents.swift`
- Modify: `AyuWalkApp/Views/Components/JournalPageCard.swift`
- Modify: `AyuWalkApp/Views/Journal/JournalPreviewView.swift`

- [ ] **Step 1: Move journal components**

Move the contents of `AyuWalkApp/Views/Components/AWJournalComponents.swift` to `AyuWalkApp/Views/Patterns/Journal/AWJournalComponents.swift`.

- [ ] **Step 2: Preserve behavior**

Keep `AWStickerLayer` callbacks unchanged:

```swift
var onRemove: (UUID) -> Void = { _ in }
var onMove: (UUID, Double, Double) -> Void = { _, _, _ in }
var onTransform: (UUID, Double, Double) -> Void = { _, _, _ in }
var onInteractionChanged: (Bool) -> Void = { _ in }
```

- [ ] **Step 3: Build and run**

Run:

```bash
xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build
```

Then run XcodeBuildMCP `build_run_sim`.

Expected: journal page still opens, stickers still render and can be selected.

### Task 5: Add Budget Patterns And Migrate Budget Sheet

**Files:**

- Create: `AyuWalkApp/Views/Patterns/Budget/AWBudgetComponents.swift`
- Modify: `AyuWalkApp/Views/Plan/BudgetPlannerView.swift`

- [ ] **Step 1: Create budget patterns**

Create reusable budget components:

- `AWBudgetTotalCard`
- `AWBudgetSplitCard`
- `AWParticipantEditorRow`

Each component should accept values and callbacks, not `AppState`.

- [ ] **Step 2: Replace local `card()` helper**

Remove the private `card()` extension from `BudgetPlannerView` and use `AWCardChrome` or budget pattern components.

- [ ] **Step 3: Build and simulator check**

Run the app build command, then run the simulator app.

Expected: budget sheet still shows manual total input, save button, add participant field, editable participant rows, and delete buttons.

### Task 6: Add Packing Patterns And Migrate Packing Sheet

**Files:**

- Create: `AyuWalkApp/Views/Patterns/Packing/AWPackingComponents.swift`
- Modify: `AyuWalkApp/Views/Plan/PackingListView.swift`

- [ ] **Step 1: Create packing patterns**

Create reusable packing components:

- `AWPackingProgressCard`
- `AWPackingAddItemCard`
- `AWPackingItemRow`

Each component should accept values and callbacks, not `AppState`.

- [ ] **Step 2: Replace local `card()` helper**

Remove the private `card()` extension from `PackingListView` and use packing pattern components.

- [ ] **Step 3: Build and simulator check**

Run the app build command, then run the simulator app.

Expected: packing sheet still shows progress, item title input, notes input, add button, editable rows, check buttons, and delete buttons.

### Task 7: Add Component Guide

**Files:**

- Create: `docs/component-system.md`

- [ ] **Step 1: Document layer rules**

Write the layer rules from the spec in a short guide for future design and implementation work.

- [ ] **Step 2: Document new-feature checkpoint**

Add this rule:

```markdown
Every new feature must include a component-system checkpoint:

- New reusable visual element: add/update a Primitive or Pattern.
- New repeated layout: add/update a Scene scaffold.
- New visual constant: add/update Design tokens before using it.
```

- [ ] **Step 3: Build and test**

Run:

```bash
xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build
swift test --package-path AyuWalkCore
```

Expected: app build succeeds and core tests pass.

### Task 8: Final Simulator Verification

**Files:**

- No source changes.

- [ ] **Step 1: Run app on simulator**

Run XcodeBuildMCP `build_run_sim`.

Expected: app launches on iPhone 17.

- [ ] **Step 2: Verify visible flows**

Confirm:

- Plan home renders.
- Budget sheet opens.
- Packing sheet opens.
- Journal tab opens.
- Sticker editing controls still appear after selecting a sticker.

- [ ] **Step 3: Commit**

Commit the component-system migration separately from unrelated feature changes where possible:

```bash
git add AyuWalkApp/Design AyuWalkApp/Views docs/component-system.md docs/superpowers/specs/2026-06-05-ayu-walk-component-system-design.md docs/superpowers/plans/2026-06-05-ayu-walk-component-system.md
git commit -m "refactor: establish AyuWalk component system layers"
```
