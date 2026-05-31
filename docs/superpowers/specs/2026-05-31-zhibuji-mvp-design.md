# 织步记 MVP Design

Date: 2026-05-31
Status: Draft for user review
English name: Ayu Walk.

## Product Positioning

织步记 is an iOS travel planning and digital journal app. The product has two equal core pillars:

1. AI-assisted travel planning.
2. Digital travel journal generation and export.

The MVP focuses on helping users turn scattered travel ideas, screenshots, notes, and booking information into a usable trip plan, then convert that structured trip into a simple but complete digital journal that can be shared or exported.

The product should not start as a generic note app or a pure scrapbook app. Its strongest differentiation is the loop from planning data to travel-ready itinerary to shareable journal.

## MVP Scope

The MVP covers pre-trip planning and lightweight journal creation.

In scope:

- Create a trip plan.
- Generate an initial itinerary with AI from manual input.
- Import screenshots and pasted text as planning material.
- Use MapKit to show itinerary places on a map.
- Edit itinerary through a map and daily timeline.
- Plan budget categories and expected spend.
- Track split expenses with an AA calculator.
- Generate and edit a packing list.
- Generate a digital journal from trip data.
- Support modular light editing for journal pages.
- Support a lightweight sticker system.
- Export shareable long images, PDF, and Markdown.
- Keep the app local-first, with iCloud and account-based sync reserved for later.

Out of scope for MVP:

- Full free-canvas journal editor.
- Large template marketplace.
- Real-time multiplayer collaboration.
- Full backend account system.
- Public community feed.
- Deep custom map base styling.
- Automatic parsing of restricted social links such as Xiaohongshu links.
- Full restaurant and hotel recommendation engine.
- Real-time opening-hours optimization.

## Product Flow

### 1. Create Trip

Users can create a trip in two ways.

Manual input plus AI assistance:

- Destination.
- Trip length by number of days or exact dates.
- Travel purpose, such as concert, honeymoon, family trip, friends trip, city walk, shopping, or food trip.
- Budget preference.
- Pace preference.
- Existing ideas, must-go places, or rough notes.

If the user provides exact dates, the AI planning layer should later be able to consider holidays, weekday/weekend differences, and opening-hour constraints when data sources are available.

Import material:

- Screenshot import, including travel guides, flights, hotels, chat screenshots, or booking screenshots.
- Text import, including copied guides, memo content, chat content, or existing itinerary drafts.
- Imported material also needs AI assistance: AI should identify places, dates, times, tickets, hotels, notes, and uncertain details, then turn them into an editable trip draft.

Link import is reserved for later because some content platforms have unstable access, login restrictions, or anti-scraping controls.

### 2. Generate Initial Itinerary

The AI service converts user input and imported material into a structured trip draft.

The result should include:

- Trip summary.
- Daily plan.
- Activities.
- Places.
- Suggested time ranges.
- Notes and assumptions.
- Missing information prompts.
- Confidence or warning flags for uncertain extracted data.

AI output must be structured data, not only prose. The app uses that structure to render maps, timelines, budgets, packing lists, and journals.

### 3. Edit Itinerary

The planning workspace has two linked surfaces:

- MapKit map with places and route preview.
- Daily timeline below or beside the map.

MVP behavior:

- Show all activity places on the map.
- Show itinerary route lines on the map so users can see the travel order visually.
- Label route points with ordered numbers such as 1, 2, 3, 4, and 5.
- Let users drag or reorder places at a lightweight level.
- Let users edit activities in the timeline.
- Let AI assist with reordering, time conflicts, route efficiency, and missing meal/rest gaps.

Long-term behavior reserved:

- Fully live map, timeline, route, traffic, restaurant, hotel, budget, and opening-hour optimization.
- Deeper map base styling through another provider if MapKit becomes limiting.

## Digital Journal

The journal is a core feature, not an add-on. The MVP can keep editing simple, but the feature chain must be complete.

Journal creation:

- One-tap generation from trip data.
- Page-turning UI that simulates a real book, journal, or diary.
- Daily pages as the main reading structure so users can flip through the trip by day.
- Cover page.
- Trip overview page.
- Daily pages.
- Optional budget and packing summary pages.

Page content:

- Title.
- Date and location.
- Map snapshot or route summary.
- Daily timeline.
- Text notes.
- Photo blocks.
- Mood tags.
- Place highlights.
- Budget summary if useful.
- Packing or checklist summary if useful.

Editing model:

- Automatic layout first.
- Modular light editing.
- Users can reorder journal modules.
- Users can choose which modules to show for each itinerary item.
- Default selected modules: title, date and location, photo block, and text notes.
- Optional modules include map snapshot, route summary, timeline, place highlights, budget summary, packing summary, mood tags, and stickers.
- Users can edit titles, text, notes, photos, and mood tags.
- Users can choose a small number of templates or themes.
- Users cannot freely edit every font, spacing, layer, or layout property in MVP.

Sticker system:

- Built-in sticker categories: weather, transport, food, sights, mood, hotels, shopping, and concerts.
- Stickers can be placed on cover pages, daily pages, photo areas, timeline nodes, or note areas.
- MVP supports simple move, scale, rotate, and delete.
- MVP does not include advanced layer management, blend modes, alignment tools, custom sticker upload, or a sticker marketplace.

Templates:

- MVP starts with 1-2 simple templates.
- Recommended first templates:
  - Minimal journal.
  - Travel plan card.
- Later versions can add film, retro, collage, magazine, cute, and premium template packs.

## Sharing And Export

Sharing is part of MVP because it helps product growth.

MVP export formats:

- Long image for social sharing.
- Plan card image for quick posting.
- PDF for saving or sharing with companions.
- Markdown for import into other AI tools, Notion, Obsidian, Apple Notes, or manual editing.

Markdown export should include:

- Trip title.
- Dates.
- Destination.
- Travel purpose.
- Daily itinerary.
- Place notes.
- Journal notes.
- Budget summary.
- AA settlement summary.
- Packing list.

MVP sharing should include light branding or watermarking that does not damage the visual quality.

AI SNS copy:

- During export, AI can generate editable titles, body copy, and hashtags for Xiaohongshu or other SNS platforms.
- Copy should be based on the real itinerary and avoid exaggerated claims.
- Default copy should include product promotion tags such as `#织步记`; `#AyuWalk` can also be added when appropriate.
- Users can edit the generated copy before copying or sharing.

Future sharing:

- Read-only online share link.
- Collaborative trip page.
- Public trip journal page.
- Template-based social cards.

## Budget, Expenses, And AA Calculator

Budget planning is part of pre-trip planning.

MVP budget features:

- Total budget.
- Category budgets, such as transport, hotel, food, tickets, shopping, entertainment, and other.
- Expected cost on activities.
- Budget summary in trip overview.

AA calculator:

- Add trip participants.
- Add expense item.
- Record payer.
- Select participants included in the expense.
- Calculate who should pay whom.
- Export settlement summary to journal, PDF, and Markdown.

MVP can focus on simple split rules. Uneven split, currency conversion, receipt scanning, and advanced settlement optimization can come later.

## Packing List

Packing list is part of pre-trip planning.

MVP behavior:

- Generate a default packing list based on destination, duration, weather assumptions, trip type, and companions.
- Users can add, edit, delete, and check items.
- Items can be grouped by category.
- Packing progress can appear in trip overview and journal export.

Future behavior:

- Weather-aware packing suggestions.
- Family/shared packing list.
- Reusable templates.
- Smart reminders.

## Reminders And Departure Countdown

Reminders are a future enhancement, but the model should reserve room for them.

Future reminders include:

- Departure countdown reminders.
- In-app alert popups.
- Lock-screen or widget countdown to departure.
- Restaurant reservation reminders.
- Key ticket, hotel check-in, transport departure, and activity start reminders.
- Holiday, peak-season, or major local event warnings during itinerary planning.

MVP does not need to implement the full reminder system, but `Trip`, `Activity`, and `Place` should reserve reminder and important-time fields.

## Technical Stack

Recommended MVP stack:

- iOS native app.
- Swift.
- SwiftUI.
- SwiftData for local persistence, with Core Data fallback if model migration or query complexity becomes risky.
- MapKit for maps.
- MiniMax multimodal API for screenshot and image understanding.
- Text model API for itinerary generation, question answering, and itinerary optimization.
- SwiftUI-rendered export components for image and PDF output.
- Markdown export generated from structured trip and journal data.
- taste-skill for early visual design calibration, especially visual language, share cards, journal templates, and marketing presentation checks.

Backend strategy:

- Do not build a full backend first.
- Build local-first data and real end-to-end app flows.
- Define stable data contracts before any backend work.
- Add CloudKit/iCloud sync after local MVP is stable.
- Add self-hosted account/backend only when needed for subscriptions, AI quota, online sharing, collaboration, or cross-platform expansion.

This avoids the previous failure mode where backend and frontend are built separately and do not fit together well.

## Architecture

The app should use clear service boundaries.

Core layers:

- Data Model: owns trip, itinerary, budget, expense, packing, journal, export, and future collaboration records.
- Local Store: persists data on device.
- SyncProvider: reserved interface for iCloud and future backend sync.
- AIService: wraps text generation, multimodal recognition, itinerary optimization, and structured JSON validation.
- MapProvider: abstracts map operations; MVP implementation uses MapKit.
- PlanningEngine: turns user input, imported material, AI output, places, time constraints, and budget constraints into editable plans.
- PlanningScriptEngine: records and executes reusable route-planning scripts, rules, and heuristics to reduce repeated AI calls over time.
- JournalEngine: turns trip data into journal pages and modules.
- ExportService: generates image, PDF, and Markdown outputs.
- EntitlementProvider: reserved for future subscription, AI credits, paid templates, and sticker packs.

The UI can be simple in MVP, but these boundaries should exist early.

## Core Data Model

Initial entities:

- Trip: one travel plan.
- TripDay: one day in a trip.
- Activity: one itinerary item, such as sight, meal, hotel, transport, shopping, concert, free time, or note.
- Place: location, coordinate, address, and provider IDs.
- ImportedSource: screenshot, text, or future link input.
- BudgetPlan: expected spend by category and trip.
- Expense: actual or planned spending item.
- Participant: traveler used for AA and later collaboration.
- PackingList: group of packing items.
- PackingItem: one checklist item.
- JournalPage: cover, overview, daily page, or summary page.
- JournalBlock: modular content block inside a journal page.
- StickerAsset: built-in sticker resource.
- StickerPlacement: position and transform of a sticker on a journal page or block.
- ShareExport: exported image, PDF, or Markdown record.
- Reminder: departure countdown, reservation, transport, check-in, or activity-start reminder record.
- PlanningScript: reusable planning steps, ordering rules, and validation logic generated by AI or extracted from repeated system behavior.

Future-reserved fields:

- ownerId.
- participants.
- visibility.
- syncStatus.
- cloudRecordId.
- createdDeviceId.
- permissions.
- changeLog.

## AI Design

AI features must return structured data.

MVP AI tasks:

- Ask clarifying questions when user input is too vague.
- Generate initial itinerary from manual input.
- Extract structured trip information from screenshots via MiniMax multimodal API.
- Extract structured trip information from pasted text.
- Suggest route and time adjustments.
- Generate packing list suggestions.
- Generate journal drafts from itinerary data.
- Generate editable SNS sharing copy and hashtags for Xiaohongshu or other SNS platforms.

AI output should include assumptions and uncertainty markers so the UI can show warnings instead of silently treating guesses as facts.

Route planning should use AI and deterministic scripts in parallel:

- AI handles user intent, ambiguous information, initial route generation, and explanations for adjustments.
- Scripts handle repeatable checks such as route order, time conflicts, meal gaps, budget categories, reminder triggers, and numbered map labels.
- Each AI route-planning run should record inputs, outputs, assumptions, adjustment reasons, and reusable rules so the product can gradually build PlanningScript assets.
- Over time, stable logic should run through scripts first, and AI should be called only when understanding, generation, tradeoff reasoning, or explanation is needed. This reduces AI cost and instability.

## Map Strategy

MVP uses Apple MapKit because it fits iOS, has no separate map SDK dependency, and is suitable for Apple ecosystem users.

The design keeps a MapProvider interface so the app can later evaluate Mapbox or Google Maps if needed.

MapKit is acceptable for:

- Native iOS map experience.
- Showing trip places.
- Custom annotations.
- Route overlays.
- Map snapshots.
- App-layer visual design.
- Numbered route points such as 1, 2, 3, 4, and 5.

MapKit is limited for deep base-map styling. If the product later needs full custom road, water, label, and brand map styling, Mapbox should be evaluated.

## Visual Direction

MVP visual style:

- Minimal journal style.
- Clean, calm, lightweight.
- Practical for planning.
- Soft journal accents without making the planning workflow decorative or slow.

The planning workspace should feel clear and efficient. The journal output can carry more personality through templates, stickers, cover pages, and export cards.

Design process:

- Use taste-skill in the early design phase for visual taste calibration.
- taste-skill is more useful for visual and frontend taste than for iOS product interaction architecture, so it should not replace native iOS UX design judgment.
- For 织步记/Ayu Walk, use it mainly to check minimal journal style, share cards, journal templates, page hierarchy, typography, spacing, restrained motion, and avoidance of generic templated visuals.

## Monetization Reserved

MVP should not require a custom account system.

Future paid features may include:

- More AI planning credits.
- Advanced itinerary optimization.
- Premium journal templates.
- Premium sticker packs.
- High-resolution export.
- More trip plans.
- Collaboration.
- Online share pages.
- Advanced reminder widgets and lock-screen countdown styles.

Use Apple In-App Purchase first for iOS monetization unless cross-platform account features become necessary.

## Risks And Mitigations

Risk: MVP scope becomes too large.
Mitigation: Build an end-to-end thin slice first: create trip, generate itinerary, edit timeline, generate journal, export Markdown/image.

Risk: AI returns unusable prose.
Mitigation: Require JSON schemas and validation for AI responses.

Risk: frontend and backend drift apart.
Mitigation: Local-first MVP, shared data contracts, mock JSON before backend implementation, vertical slices instead of separate backend-first development.

Risk: journal editor becomes too complex.
Mitigation: Modular light editing, limited templates, limited sticker controls, no free-canvas editor in MVP.

Risk: AI route-planning costs grow too quickly.
Mitigation: Record AI planning paths as reusable PlanningScript rules and run deterministic scripts before calling AI.

Risk: MapKit styling is not enough.
Mitigation: Keep MapProvider abstraction and move custom visual identity to annotations, overlays, cards, journal templates, and export layouts first.

Risk: social platform link import is unstable.
Mitigation: MVP supports screenshots and pasted text first; link parsing is future work.

## Suggested MVP Build Order

1. Define data model and sample trip JSON.
2. Build local trip creation flow.
3. Build AI text itinerary generation with structured output.
4. Build screenshot/text import pipeline with MiniMax multimodal API.
5. Build itinerary timeline editor.
6. Build MapKit place display, route lines, numbered labels, and basic drag/reorder behavior.
7. Build budget planner.
8. Build AA calculator.
9. Build packing list.
10. Build AI+script parallel planning logs and reusable rule mechanism.
11. Build journal generation engine.
12. Build page-turning journal preview.
13. Build modular journal editor with stickers and module selection.
14. Build image, PDF, and Markdown export.
15. Add light share branding and AI SNS copy generation.
16. Prepare reminder, iCloud/sync, and account interfaces without implementing full backend.

## Implementation Defaults To Confirm

- English product name is Ayu Walk.
- Minimum iOS version should be chosen during implementation planning after checking required MapKit, SwiftData, export, and photo features.
- SwiftData is the default persistence choice unless prototype testing shows migration, query, or sync risk that justifies Core Data.
- Text model provider should be selected during implementation planning; the interface must not be tied to one provider.
- MiniMax API request and response schemas should be captured before implementing screenshot import.
- MVP target includes Markdown and image export; PDF export is included in product scope but may be sequenced after the first vertical slice if needed.
- Online read-only share links are post-MVP unless account and cloud infrastructure are pulled forward intentionally.
