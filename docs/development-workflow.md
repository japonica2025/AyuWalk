# AyuWalk Development Workflow

This document defines how AyuWalk work should be planned, implemented, reviewed, debugged, verified, and backed up from now on.

The goal is to keep feature work, UI design alignment, component system work, debugging, and review moving together without letting the codebase become fragmented.

## Default Operating Model

AyuWalk should use a lightweight multi-agent workflow.

One coordinator owns the full task. Specialized agents may investigate or implement focused work when the scope is independent enough to avoid file conflicts.

Use multiple agents for:

- separate feature areas, such as budget, packing, journal, itinerary, or export
- debugging a specific bug while another task continues
- code review after a meaningful change
- UI or component-system review
- simulator QA for affected flows

Do not use multiple agents when:

- two tasks need to edit the same SwiftUI file at the same time
- the root cause is not understood yet and broad context is required
- a decision affects app architecture, naming, or data ownership

The coordinator makes final decisions on architecture, naming, file placement, git commits, and integration.

## Roles

### Coordinator

Owns the task end to end.

Responsibilities:

- clarify the request and success criteria
- decide whether the task should be split
- assign independent work to focused agents
- protect existing user changes
- integrate changes into one coherent result
- run final verification
- decide whether the work is ready to commit

### Feature Agent

Builds one focused user-facing capability.

Examples:

- manual budget entry
- AA participant editing
- packing-list templates
- itinerary item detail
- journal export

Rules:

- stay inside the assigned feature area
- avoid broad refactors
- expose UI through existing components where possible
- report changed files and behavioral impact

### Component Agent

Keeps the UI system healthy.

Responsibilities:

- add or update Design tokens
- add or update Primitive components
- add or update Pattern components
- add or update Scene scaffolds
- check whether a new feature introduced duplicate styling

Every new feature must include a component-system checkpoint. See `docs/component-system.md`.

### Debug Agent

Investigates a bug before large fixes are made.

Responsibilities:

- reproduce the issue when possible
- identify the smallest affected area
- separate root cause from symptoms
- propose the smallest reliable fix
- state what was verified after the fix

The debug agent should not rewrite unrelated code while diagnosing.

### Review Agent

Reviews completed work before it is treated as stable.

Focus areas:

- behavioral regressions
- state ownership mistakes
- missing edge cases
- fragile gesture or animation logic
- duplicate UI components
- hard-coded visual values that should be tokens
- missing simulator or test coverage

Critical and important review issues must be resolved before the next phase.

### QA Agent

Runs user-flow verification.

Responsibilities:

- build the app
- run relevant tests
- launch the simulator when needed
- check affected screens and entry points
- report visible regressions or incomplete flows

## Standard Feature Flow

Use this flow for every non-trivial feature or UI change.

1. Define the user outcome.
2. Check whether the feature touches existing data, navigation, UI, gestures, or export.
3. Decide whether the work should stay single-agent or split into focused agents.
4. Run the component-system checkpoint.
5. Implement the smallest coherent slice.
6. Run a focused review.
7. Fix review findings.
8. Build and test.
9. Check affected simulator flows.
10. Commit a backup when the slice is stable.

## Component-System Checkpoint

Before implementing or changing UI, answer these questions:

- Does this require a new Design token?
- Does this repeat a button, card, input, chip, tab, modal, or icon-button pattern?
- Does this belong in `Views/Primitives`?
- Does this belong in `Views/Patterns/<Feature>`?
- Does this need a shared page or sheet layout in `Views/Scenes`?
- Is this truly one-off, or will design work need to align it later?

If the answer points to a reusable component, create or update the component as part of the feature.

## Debug Flow

Use this flow when a bug appears.

1. Reproduce the bug or describe the closest observed failure.
2. Identify the user action that triggers it.
3. Identify the smallest involved files.
4. Check whether the issue is gesture state, view state, data state, layout, persistence, or navigation.
5. Fix the root cause.
6. Add a focused regression check when practical.
7. Verify the affected simulator flow.

For gesture-heavy areas such as stickers and journal pages, always verify that the background page does not receive gestures while an overlay object is being adjusted.

## Review Flow

Request review after:

- completing a feature slice
- changing shared components
- changing app state or persistence
- fixing a complex bug
- before backing up to git

The review should answer:

- Does the change satisfy the request?
- Did it introduce duplicate UI or hard-coded styling?
- Did it touch unrelated behavior?
- Are there missing edge cases?
- Are tests or simulator checks enough for the risk level?

## Verification Rules

For app code changes, run:

```bash
xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build
```

For core package changes, run:

```bash
swift test --package-path AyuWalkCore
```

For visible UI changes, also launch the simulator and check the affected screen.

Minimum simulator checks for current major areas:

- home opens without crashing
- budget sheet opens and saves expected values
- AA participant editing works when changed
- packing sheet can add and toggle items
- journal opens and sticker controls remain usable after resize and rotation
- adjusting stickers does not flip or drag the journal page underneath

## Git Backup Rules

Create a backup commit when:

- the app builds
- relevant tests pass
- affected simulator flows have been checked
- review issues are resolved or explicitly deferred

Commit scope should be understandable:

- one stable feature slice
- one bug fix plus its verification
- one component-system migration slice
- one documentation-only process update

Avoid mixing unrelated unstable work into a backup commit unless the purpose is a clearly labeled work-in-progress safety backup.

## Current AyuWalk Priorities

Near-term work should be split around these tracks:

- stabilize journal sticker gestures
- finish budget manual entry and AA participant editing
- finish packing custom items and templates
- continue component-system migration while building features
- review and verify every visible flow before backup commits

The component system is now part of the normal development process, not a separate cleanup task.
