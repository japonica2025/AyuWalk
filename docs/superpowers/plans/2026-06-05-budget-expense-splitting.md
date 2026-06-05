# Budget Expense Splitting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-expense budget entries where each new expense defaults to all trip participants, and users can remove participants who should not share that cost.

**Architecture:** Store expenses inside `BudgetPlan` so budget data remains part of the existing trip persistence model. Add core calculation helpers in `BudgetSplitCalculator`, expose mutation methods through `AppState`, and build the UI through Budget pattern components.

**Tech Stack:** Swift, SwiftUI, AyuWalkCore XCTest, Xcode iOS Simulator.

---

### Task 1: Core Budget Model and Calculator

**Files:**
- Modify: `AyuWalkCore/Sources/AyuWalkCore/Models/Trip.swift`
- Modify: `AyuWalkCore/Sources/AyuWalkCore/Engines/BudgetSplitCalculator.swift`
- Modify: `AyuWalkCore/Tests/AyuWalkCoreTests/BudgetSplitCalculatorTests.swift`

- [ ] Write failing tests for per-expense splits.
- [ ] Verify the tests fail before production code changes.
- [ ] Add `BudgetExpense`, `BudgetCategory`, and `BudgetParticipantShare`.
- [ ] Add `BudgetSplitCalculator.expenseShares` and `BudgetSplitCalculator.participantTotals`.
- [ ] Keep old total-budget split behavior intact.

### Task 2: App State Mutations

**Files:**
- Modify: `AyuWalkApp/AppState.swift`

- [ ] Add methods to create, update, and delete budget expenses.
- [ ] New expenses default to all current participant IDs.
- [ ] Add a method to toggle a participant for one expense.
- [ ] Persist after each budget mutation.

### Task 3: Budget UI Components

**Files:**
- Modify: `AyuWalkApp/Views/Patterns/Budget/AWBudgetComponents.swift`
- Modify: `AyuWalkApp/Views/Plan/BudgetPlannerView.swift`
- Modify: `AyuWalkApp/Views/Plan/PlanHomeView.swift`

- [ ] Add a reusable expense-entry card.
- [ ] Add a reusable expense-list card.
- [ ] Add participant chips for each expense.
- [ ] Add category selection for each expense.
- [ ] Wire the budget sheet to AppState mutation methods.

### Task 4: Verification

**Files:**
- No code-only files.

- [ ] Run `swift test --package-path AyuWalkCore`.
- [ ] Run `xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build`.
- [ ] Launch the simulator and check the budget sheet flow.
