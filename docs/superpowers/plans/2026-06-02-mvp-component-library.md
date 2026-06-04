# MVP Component Library Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first reusable SwiftUI component library for Ayu Walk, with enough structure to restyle trip planning and journal pages without rewriting screens.

**Architecture:** Keep design tokens in `AyuWalkApp/Design`, base components in `AyuWalkApp/Views/Components`, and feature-shaped components close enough to be reused by screens. The first implementation focuses on additive components and a journal-page migration so the app keeps working while the design system grows.

**Tech Stack:** SwiftUI, AyuWalkCore journal models, local `AyuWalkTheme` and `AyuWalkTypography`.

---

### Task 1: Design Token Utilities

**Files:**
- Modify: `AyuWalkApp/Design/AyuWalkTheme.swift`

- [ ] **Step 1: Add spacing and sizing namespaces**

Add `AyuWalkSpacing`, `AyuWalkRadii`, and `AyuWalkShadow` next to `AyuWalkTheme`. Use static values only so call sites can update without state or dependency injection.

- [ ] **Step 2: Build the app**

Run: `xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build`

Expected: `BUILD SUCCEEDED`.

### Task 2: Base Component Expansion

**Files:**
- Modify: `AyuWalkApp/Views/Components/AyuWalkComponents.swift`

- [ ] **Step 1: Add reusable component primitives**

Add `AWActionCapsuleButton`, `AWSelectableChip`, `AWInfoRow`, `AWEmptyState`, and `AWCardChrome`. These cover the repeated button, chip, row, empty state, and card shell patterns already appearing in planning and journal screens.

- [ ] **Step 2: Build the app**

Run the iOS simulator build command from Task 1.

Expected: `BUILD SUCCEEDED`.

### Task 3: Journal Framework Components

**Files:**
- Create: `AyuWalkApp/Views/Components/AWJournalComponents.swift`
- Modify: `AyuWalkApp/Views/Components/JournalPageCard.swift`

- [ ] **Step 1: Create journal page shell**

Add `AWJournalBookFrame`, `AWJournalPageSurface`, `AWJournalBlockCard`, `AWStickerLayer`, and `AWStickerToken`. These define the book/page frame and keep stickers as a separate visual layer so future transparent sticker assets can replace SF Symbols.

- [ ] **Step 2: Migrate JournalPageCard**

Use the new journal components while preserving existing inputs: `page`, `visibleBlocks`, and `stickers`.

- [ ] **Step 3: Build the app**

Run the iOS simulator build command from Task 1.

Expected: `BUILD SUCCEEDED`.

### Task 4: Journal Preview Toolbar Cleanup

**Files:**
- Modify: `AyuWalkApp/Views/Journal/JournalPreviewView.swift`

- [ ] **Step 1: Replace custom toolbar pills**

Use `AWActionCapsuleButton` for export, sticker, and module actions. Keep the same sheet behavior.

- [ ] **Step 2: Build and run on simulator**

Run: XcodeBuildMCP `build_run_sim`.

Expected: the app launches on iPhone 17 and the journal page still opens.

### Task 5: Visual Verification

**Files:**
- No source changes.

- [ ] **Step 1: Capture simulator screenshots**

Capture the journal page and verify the frame, module cards, and sticker layer render without overlap.

- [ ] **Step 2: Note follow-up components**

Record obvious next components to add later: trip summary card, day itinerary card, activity row, route map panel, budget tile, packing tile.
