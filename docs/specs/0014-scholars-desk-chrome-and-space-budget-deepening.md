---
id: SPEC-014
title: Deepen Scholar's Desk Chrome & Formatting State Ownership
status: completed
created_at: 2026-11-13T21:46:30+08:00
adr: ADR-0003, ADR-0009
---

# Specification: Deepen Scholar's Desk Chrome & Formatting State Ownership

## Problem Statement

While writing on the **Scholar's Desk**, the bottom writing chrome and **Desk Workstation** geometry suffer from split state ownership, duplicated layout arithmetic, and unpacked prop drilling:

- **Lost Formatting Ribbon State Across Keyboard Transitions**: Both the resting **Writing Dock** and the keyboard-open **Keyboard Accessory Row** manage their own private ephemeral open/closed boolean for the expandable rich-text formatting ribbon. When a diarist opens the formatting ribbon in the **Writing Dock** and taps a **Stationery Sheet** to start typing, the dock yields to the **Keyboard Accessory Row** and the formatting ribbon unexpectedly collapses back to closed—and the reverse happens when dismissing the software keyboard.
- **Double Desk Space Budget Evaluation**: During layout of the **Scholar's Desk**, the canvas evaluates `DeskSpaceBudget.resolve` twice per frame: once with the **Desk Workstation** forced open solely to inspect whether it fits, which feeds `resolveInitialWorkstation`, and a second time with the resolved collapse boolean to build the actual desk budget. Furthermore, leaving `resolveInitialWorkstation` as a separate public step forces layout callers to orchestrate an internal multi-step handshake correctly.
- **Unpacked Chrome Prop Drilling & Unsafe Callback Unwraps**: Although writing panels already receive the chrome controller directly, the paper canvas unpacks the exact same chrome controller into four separate properties—collapsed flag, collapse callback, restore callback, and dock-restore callback—and drills them into the desk media area. Both the desk media area and the **Writing Dock** still rely on forced null-unwraps (`!`) on optional callbacks and sit on the project's grandfathered callback-unwrap exception list.

## Solution

Deepen the chrome state and desk space budget seam around the existing editor chrome controller without widening its dependencies:

- **Controller-Owned Formatting Ribbon State**: Move `isFormattingOpen` and `toggleFormatting()` onto the chrome controller so formatting ribbon openness stays sticky in memory across software keyboard open/close transitions, **Writing Dock** hide/restore toggles, and sheet turns within an editing session. Convert both **Writing Dock** and **Keyboard Accessory Row** into stateless controlled presentation widgets driven by explicit props.
- **Single-Pass Desk Budget Resolution**: Add a pure workstation-fit probe to the desk space budget value object and introduce a single `resolveDeskBudget` operation on the chrome controller that handles first-layout workstation collapse internally and constructs `DeskSpaceBudget` strictly once per layout pass. Retire `resolveInitialWorkstation` from the controller's public interface.
- **Direct Chrome Passing & Safer Callbacks**: Pass the chrome controller directly to the desk media area (matching how writing panels already consume it), removing the four unpacked properties and callbacks. Replace forced optional callback unwraps (`!`) in the two refactored widget modules with local nullable bindings and remove those files from the code-style audit allowlist.

## User Stories

### Formatting Continuity Across Writing Modes

1. As a diarist browsing my entry at rest, I want to open the formatting ribbon in the **Writing Dock** and then tap a **Stationery Sheet** to type, so that the **Keyboard Accessory Row** keeps my formatting ribbon open instead of collapsing it.
2. As a diarist typing with the **Keyboard Accessory Row** formatting ribbon expanded, I want dismissing the software keyboard to leave the **Writing Dock** formatting ribbon open, so that I can continue adjusting headings or styles without re-tapping `[Aa]`/`Tt`.
3. As a diarist navigating across multiple **Stationery Sheets** via **Page Corners** or swiping, I want my formatting ribbon open state to remain undisturbed throughout the editing session until I explicitly close it.
4. As a diarist viewing a **Tipped-In Ephemera Leaf** sheet when I open formatting in either the **Writing Dock** or the **Keyboard Accessory Row**, I want the editor to automatically ensure an active text sheet exists before expanding the ribbon, matching the dictation toggle behavior.
5. As a diarist toggling the **Writing Dock** hidden via `收起文房` while the keyboard is open or closed, I want formatting ribbon openness to remain independent of dock visibility, so restoring the dock later preserves my expected formatting tool state.

### Single-Pass Desk Budget & Short-Viewport Ergonomics

6. As a diarist opening an entry on a short viewport or landscape split screen (< 420dp height), I want the **Desk Workstation** to auto-collapse on the very first resolved layout pass so the **Restore Pill** replaces the mat cleanly without obscuring the active **Stationery Sheet** or **Cinnabar Signature Seal**.
7. As a diarist collapsing or restoring the **Desk Workstation**, I want the choice to stick across subsequent layout passes rather than being overridden if the viewport or **Staging Handscroll** item count changes.
8. As a diarist opening the software keyboard, I want the resting desk height to hold steady while the **Desk Workstation** steps aside, so my **Stationery Sheet** never resizes or re-paginates.

### Developer Ergonomics & Structural Safety

9. As a developer working on the **Scholar's Desk**, I want a single cohesive `resolveDeskBudget` method on the chrome controller instead of orchestrating `resolveInitialWorkstation` and calling `DeskSpaceBudget.resolve` twice, so desk layout code is concise and less error-prone.
10. As a developer writing unit tests for desk layout, keyboard visibility, and toolbar state, I want to verify all **Desk Space Budget** auto-collapse and formatting ribbon transitions directly against the in-memory chrome controller without constructing full editor widget trees.
11. As a developer reading widget code, I want the desk media area to consume the chrome controller directly—just like writing panels—without four unpacked booleans and callbacks or forced `!` callback unwraps.

## Implementation Decisions

### 1. Chrome Controller Deepening (Editor Controllers)

- **Own Formatting Ribbon State**:
  - Add an in-memory `isFormattingOpen` getter (initial value `false`, not persisted to app-wide settings across entries—matching `isDictating`) and `toggleFormatting()` method that flips state and notifies listeners.
  - `isFormattingOpen` remains sticky across `syncKeyboardInset`, `setWritingDockVisible`, `collapseWorkstation`/`expandWorkstation`, and sheet turns within a session.
- **Unify Desk Budget Resolution**:
  - Keep `resolveRestingDeskHeight(double visibleHeight)` as the initial step executed before sheet geometry sizing so the controller remains decoupled from template styling and typography math.
  - Add `DeskSpaceBudget resolveDeskBudget({required double restingDeskHeight, required double sheetHeight, required double sealBlockHeight, required bool isHandscrollEmpty, required bool isLastSheet})` returning a resolved budget in one pass.
  - Pass `restingDeskHeight` explicitly to avoid silent miscalculation when layout occurs before a resting frame has cached `_restingDeskHeight`.
  - Internally check initial workstation fit on the first unresolved call; if the workstation does not fit, set `_isWorkstationCollapsed = true` immediately for the returned budget and retain the existing post-frame `SchedulerBinding.instance.addPostFrameCallback` listener notification (guarded by `!_isDisposed`) so external observers sync safely outside build/layout.
  - Remove `resolveInitialWorkstation` from the public interface by making it private inside the controller.

### 2. Pure Workstation Fit Probe (Desk Space Budget)

- Extract a static helper `DeskSpaceBudget.fitsWorkstation({required double canvasHeight, required double sheetHeight, required bool isHandscrollEmpty})` using the canonical reserved header band, sheet gap, and open/closed workstation minimum heights (`150.0` vs `110.0`).
- Have `DeskSpaceBudget.resolve` call `fitsWorkstation` so fit rules have a single source of truth while keeping `DeskSpaceBudget.resolve` callable once inside `resolveDeskBudget`.

### 3. Stateless Controlled Tool Rows & Panels Orchestration (Editor Widgets)

- **Writing Dock & Keyboard Accessory Row**:
  - Convert both **Writing Dock** and **Keyboard Accessory Row** from `StatefulWidget` to `StatelessWidget`.
  - Add `final bool isFormattingOpen` (default `false`) and `final VoidCallback? onToggleFormatting` parameters to both widgets and remove all private `_isFormattingOpen` fields and `_toggleFormatting` state mutations.
  - Preserve existing visual keys (`writing_dock_format_btn`, `keyboard_accessory_format_btn`), haptic feedback on tap, button accessibility semantics, and clamped `MediaQuery` text scaling (`maxScaleFactor: 1.3`).
- **Editor Writing Panels**:
  - Add a private `_toggleFormatting()` helper matching `_toggleDictation()`: call `onEnsureTextController()` if `!chrome.isFormattingOpen`, then call `chrome.toggleFormatting()`.
  - Pass `chrome.isFormattingOpen` and `_toggleFormatting` down to both `KeyboardAccessoryRow` and `WritingDock`.
  - Both tool rows still receive `onEnsureTextController` for ribbon style buttons triggered directly from `FormattingRibbonReveal`.

### 4. Direct Chrome Passing & Callback Hygiene (Editor Paper Canvas & Desk Media Area)

- **Desk Media Area**:
  - Replace the four unpacked properties (`isWorkstationCollapsed`, `onCollapseWorkstation`, `onRestoreWorkstation`, `onRestoreWritingDock`) on `EditorDeskMediaArea` with a single `required EditorChromeController chrome` parameter, retaining `required DeskSpaceBudget budget`.
  - Derive workstation collapse visibility, pull-tab `onCollapse: chrome.collapseWorkstation`, restore-pill `onRestore: chrome.expandWorkstation`, and `chrome.showsWritingDockRestoreTab` with `WritingDockRestoreTab(onRestore: () => chrome.setWritingDockVisible(true))` directly from `chrome`.
- **Editor Paper Canvas**:
  - Replace the local `resolveBudget` closure and dual `DeskSpaceBudget.resolve` + `chrome.resolveInitialWorkstation` calls with a single call to `chrome.resolveDeskBudget(restingDeskHeight: canvasHeight, sheetHeight: cardHeight, sealBlockHeight: sealBlockHeight, isHandscrollEmpty: stagedItems.isEmpty, isLastSheet: currentSheetIndex == totalSheets - 1)`.
  - Pass `chrome: chrome` into `EditorDeskMediaArea` instead of unpacking chrome fields.
- **Null-Safety Cleanup**:
  - Eliminate all optional callback `!` force-unwraps (`onRestoreWritingDock!`, `onPickVideo!`, `onShuffleSpark!`) in the desk media area and writing dock widgets using safe local bindings, and remove both widget files from the `grandfatheredCallbackUnwraps` allowlist in the automated code-style audit test.

### 5. Preserved Module Boundaries

- Keep `WritingFocusGuard` (`sheets` iterable, `FocusManager`, and `ModalRoute` inspection) independent from `EditorChromeController` so the chrome controller stays free of document/sheet and `BuildContext` dependencies.
- Keep `syncKeyboardInset` on screen builds and `syncAppBarHiddenExtent` on `EditorAppBarSlide` unchanged.

## Testing Decisions

### Good Test Principles

- Assert external observable behavior—resolved `DeskSpaceBudget` dimensions/flags, listener notifications, rendered widget visibility (e.g., `'B'` / `'I'` formatting buttons present or absent, **Restore Pill** vs **Desk Workstation** presence), and controller getters—never private fields or build counts.
- Prefer the highest, fastest pure or controller seam (`EditorChromeController`) for layout budget and state-machine transitions, complemented by focused widget integration tests across the `EditorWritingPanels` and `EntryEditorScreen` seams.

### Existing Test Seams to Exercise & Update

1. **`EditorChromeController` Unit Tests (Primary In-Process Seam)**:
   - Update existing `workstation` tests from calling `resolveInitialWorkstation` to calling `resolveDeskBudget(...)`, verifying frame-1 collapse decisions, post-frame notification behavior when auto-collapsed, no notification when fitting, and stickiness across subsequent `resolveDeskBudget` calls.
   - Add tests for short-viewport / landscape budgets where resting desk height drops below 420dp and verify `DeskSpaceBudget.showWorkstation == false` / `workstationFits == false`.
   - Add unit tests for `isFormattingOpen` defaulting to `false`, toggling via `toggleFormatting()`, notifying listeners, and remaining intact across `syncKeyboardInset` transitions (`0 → 300 → 0`) and `setWritingDockVisible(false) / (true)`.
2. **`DeskSpaceBudget` Unit Tests**:
   - Add unit checks verifying `DeskSpaceBudget.fitsWorkstation` matches `DeskSpaceBudget.resolve(...).workstationFits` across open and closed handscroll bounds.
3. **`WritingDock` & `EditorWritingPanels` Widget Tests**:
   - Update standalone `WritingDock` widget tests (e.g. using a `StatefulBuilder` wrapper in the tap-to-expand test) to pass controlled `isFormattingOpen` and `onToggleFormatting` callbacks.
   - Add an `EditorWritingPanels` integration test verifying that opening formatting while the **Writing Dock** is visible keeps formatting open when `chrome.syncKeyboardInset(300.0)` switches to **Keyboard Accessory Row**, and keeps it open when returning (`chrome.syncKeyboardInset(0.0)`), plus calls `onEnsureTextController` when opening formatting.
4. **`EditorDeskMediaArea` Widget & `EntryEditorScreen` Regression Tests**:
   - Update `EditorDeskMediaArea` widget tests to pass `EditorChromeController()` directly via `chrome`.
   - Run full editor widget/screen regressions (including `desk_workstation_test`, `split_desk_centering_test`, `tucked_prints_test`, and `code_style_audit_test`) to ensure zero visual or audit regressions after removing both files from `grandfatheredCallbackUnwraps`.

## Out of Scope

- Folding `WritingFocusGuard`, `StationerySheetDescriptor` inspection, or `ModalRoute` checks into `EditorChromeController`.
- Moving `StationerySheetGeometry` calculation into `EditorChromeController`.
- Changing `EditorAppBarSlide`'s `onHiddenExtent` callback architecture or `KeyboardDeskLift`'s animation logic.
- Refactoring Candidate 4 (Desk Media Lifecycle / caption & ephemera parity) or Candidate 5 (Controller-free Delta partitioning & Folio/PDF decoding).
- Persisting `isFormattingOpen` across app launches in `EditorSettingsService`.

## Further Notes

- Builds directly on **SPEC-013** (*Deepen Stationery Sheet Geometry & Paper Heart Sizing*, merged at `6438bdc`), whose `StationerySheetGeometry.cardHeight` feeds `sheetHeight` into `chrome.resolveDeskBudget(...)`.
- Domain terminology aligns with [GLOSSARY.md](file:///home/harry1029/projects/memodiary/GLOSSARY.md) (`Scholar's Desk`, `Writing Dock`, `Keyboard Accessory Row`, `Desk Workstation`, `Restore Pill`, `Staging Handscroll`, `Tucked Prints`).
