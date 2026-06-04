# AyuWalk Component System Design

## Goal

Build a stable SwiftUI component system for AyuWalk so visual design work can proceed in parallel with feature development. The system should make future design-team updates mostly token and component changes, not broad page rewrites.

## Decision

AyuWalk will use a four-layer component system:

1. `Design`: design tokens and semantic style values.
2. `Primitives`: reusable UI building blocks with no AyuWalk business model dependency.
3. `Patterns`: AyuWalk-specific reusable UI composed from primitives.
4. `Scenes`: page and sheet scaffolds that define layout slots but do not own business state.

The app will keep the existing `AW` prefix. We will not rename components to match external prompt examples such as `AyuButton`. The canonical naming style is:

- `AWButton`, `AWCard`, `AWTextField`, `AWChip`, `AWIconButton` for primitives.
- `AWBudgetSummaryCard`, `AWPackingItemRow`, `AWJournalPage`, `AWStickerLayer` for patterns.
- `AWPageScaffold`, `AWSheetScaffold`, `AWPlannerScene`, `AWJournalScene` for scene scaffolds.

## Layer Rules

### Design

Path: `AyuWalkApp/Design`

Responsibilities:

- Define colors, typography, spacing, radii, shadows, sizing, and animation tokens.
- Provide semantic names that match app intent, not raw visual values.
- Keep all provisional visual values centralized because the final design spec is not locked yet.

Rules:

- SwiftUI views should not introduce new raw colors.
- Repeated spacing, radius, shadow, and icon sizes must become tokens.
- Screen-specific fixed layout sizes are allowed only when they are named semantic constants.

### Primitives

Path: `AyuWalkApp/Views/Primitives`

Responsibilities:

- Provide business-free UI atoms and shells.
- Expose style variants through small enums or properties.
- Use only `Design` tokens for visual values.

Allowed dependencies:

- `SwiftUI`
- `AyuWalkApp/Design`

Forbidden dependencies:

- `AyuWalkCore`
- `AppState`
- specific trip, journal, budget, packing, or map models

Initial primitive set:

- `AWButton`
- `AWIconButton`
- `AWCard`
- `AWTextField`
- `AWChip`
- `AWStatusPill`
- `AWMetricTile`
- `AWEmptyState`
- `AWFloatingTabBar`

### Patterns

Path: `AyuWalkApp/Views/Patterns`

Responsibilities:

- Provide reusable AyuWalk-specific components.
- Compose primitives into product UI for planning, journal, budget, packing, map, and creation flows.
- Accept data through values and callbacks. They may know `AyuWalkCore` models, but they must not own global app state.

Allowed dependencies:

- `SwiftUI`
- `AyuWalkCore`
- `Design`
- `Primitives`

Forbidden dependencies:

- direct `@Environment(AppState.self)`
- persistence
- network or AI services

Initial pattern groups:

- `Journal`: page surface, block card, sticker layer, sticker token.
- `Plan`: itinerary timeline, route preview pieces, quick action rows.
- `Budget`: budget summary and participant rows.
- `Packing`: packing item rows and progress cards.
- `Create`: destination and purpose selection rows.

### Scenes

Path: `AyuWalkApp/Views/Scenes`

Responsibilities:

- Define reusable page and sheet scaffolds.
- Own layout slots, navigation chrome, safe-area spacing, scroll containers, and sheet structure.
- Keep business logic in existing screen views or `AppState`, not inside scaffolds.

Allowed dependencies:

- `SwiftUI`
- `Design`
- `Primitives`
- `Patterns` when a scene scaffold intentionally represents a product area

Initial scene set:

- `AWPageScaffold`
- `AWSheetScaffold`
- `AWScrollablePageScaffold`

## Migration Strategy

The migration will be incremental but structurally complete:

1. Create the new folders and canonical primitive files.
2. Move or wrap existing `AW` components into the right layer without changing behavior.
3. Replace page-local card, button, chip, and input styling in recently edited Budget and Packing screens first.
4. Move journal components into `Patterns/Journal` and keep current sticker behavior intact.
5. Add a short component guide for design and development alignment.

Large page rewrites are not required for the first pass. The success criterion is that new UI has a clear home and existing repeated UI starts flowing through shared components.

## New Feature Rule

Every future feature implementation must include a component-system checkpoint:

- If the feature introduces a reusable visual building block, create or update a Primitive or Pattern.
- If the feature introduces a repeated screen layout, create or update a Scene scaffold.
- If the feature needs new visual constants, add them to Design tokens first.
- Do not add page-local card, button, input, chip, or sheet styling unless it is truly one-off and documented in code by naming a local semantic constant.

## Testing And Verification

Each migration step must pass:

- `xcodebuild -project AyuWalkApp.xcodeproj -scheme AyuWalkApp -destination 'generic/platform=iOS Simulator' build`
- `swift test --package-path AyuWalkCore`

For visible migrations, run the app on the iPhone 17 simulator and verify:

- Plan page still opens.
- Budget sheet still supports manual budget and participant editing.
- Packing sheet still supports adding, editing, checking, and deleting items.
- Journal page still renders stickers and editing controls.

## Risks

- Moving files can break Xcode project membership. We will verify after each small batch.
- Over-abstracting Scene templates too early can reduce flexibility. The first Scene layer will focus on scaffolds, not fully opinionated page templates.
- Some raw sizes are interaction geometry, especially stickers and maps. These should become named semantic constants instead of generic spacing tokens.
