# AyuWalk Component System

This guide defines how AyuWalk UI should be organized from now on. The goal is to let feature work and visual design work move in parallel without scattering one-off UI styling across screens.

## Layers

### Design

Path: `AyuWalkApp/Design`

Use this layer for design tokens:

- colors
- typography
- spacing
- radii
- shadows
- semantic sizes
- motion values

Do not add repeated raw colors, spacing, radii, or sizing values directly in feature views. If a value is reused or represents a design decision, add a token first.

### Primitives

Path: `AyuWalkApp/Views/Primitives`

Use this layer for business-free SwiftUI building blocks. Primitives must not import `AyuWalkCore` or read `AppState`.

Current primitives include:

- `AWPrimaryButton`
- `AWActionCapsuleButton`
- `AWPlainIconButton`
- `AWCardChrome`
- `AWPanel`
- `AWTextField`
- `AWStatusPill`
- `AWSelectableChip`
- `AWMetricTile`
- `AWFloatingTabBar`

### Patterns

Path: `AyuWalkApp/Views/Patterns`

Use this layer for reusable AyuWalk product components. Patterns may import `AyuWalkCore`, but they should receive values and callbacks from the caller. They should not own app state, persistence, AI, or networking.

Current pattern groups:

- `Patterns/Journal`
- `Patterns/Budget`
- `Patterns/Packing`

### Scenes

Path: `AyuWalkApp/Views/Scenes`

Use this layer for shared page and sheet scaffolds. Scenes define layout slots, navigation chrome, scroll containers, padding, and background behavior.

Current scenes:

- `AWPageScaffold`
- `AWSheetScaffold`

## Naming

Use the `AW` prefix for app UI components.

Use short, stable names for primitives:

- `AWCard`
- `AWTextField`
- `AWChip`
- `AWIconButton`

Use product-specific names for patterns:

- `AWBudgetTotalCard`
- `AWParticipantEditorCard`
- `AWPackingChecklistCard`
- `AWJournalPageSurface`

Do not rename components to match external examples unless the rename improves AyuWalk consistency.

## New Feature Checkpoint

Every new feature must include a component-system checkpoint:

- New reusable visual element: add or update a Primitive or Pattern.
- New repeated layout: add or update a Scene scaffold.
- New visual constant: add or update Design tokens before using it.
- Existing page-local card, button, input, chip, or sheet styling: replace it with the shared component unless it is truly one-off.

## Migration Rule

When touching an existing screen, do not rewrite the whole screen only for purity. Migrate the UI surface you are already changing:

- Budget and packing surfaces should use their Pattern components.
- Journal page and sticker surfaces should use `Patterns/Journal`.
- General buttons, cards, chips, and text fields should come from `Primitives`.

## Verification

After component changes, run:

```bash
xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build
swift test --package-path AyuWalkCore
```

For visible changes, run the app in the simulator and check the affected screen.
