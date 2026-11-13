---
id: SPEC-013
title: Deepen Stationery Sheet Geometry & Paper Heart Sizing
status: completed
created_at: 2026-11-13T00:20:00+08:00
adr: ADR-0006, ADR-0008
---

# Specification: Deepen Stationery Sheet Geometry & Paper Heart Sizing

## Problem Statement

When a diarist opens or edits an entry, the visual presentation of each **Stationery Sheet** is governed by its bounded **Paper Heart** (版心), **Heaven and Earth Margins** (天头地脚), and the opening **Journal Letterhead**. However, this geometric model is currently fragmented across widgets, screen state, and layout calculators, introducing concrete visual bugs and shallow interfaces:

- **Two-Frame Layout Flutter & Redundant Post-Frame Measurement**: The **Journal Letterhead** spans deterministically four ruled rows of the active line stride. Yet the main editor screen maintains an unmeasured default header height (96.0px) on frame 1, assigns a global key to the letterhead widget, schedules a post-frame callback to measure its render box, and calls `setState()` to update the header height on frame 2. On lined stationery templates where the line stride is 29.0px (4 rows = 116.0px), frame 1 renders ruled lines behind the letterhead with the wrong offset before snapping down on frame 2.
- **Redundant RenderObject Wrapper**: An integer-snapped layout wrapper sits between the sheet view and the letterhead to snap arbitrary raw heights to integer line strides. Because the enclosed letterhead already specifies its height as an exact integer multiple of the line stride, this render object performs redundant calculations and adds unnecessary layout complexity.
- **Leaked Template Inset Calculations Across Widget Boundaries**: The margin rules and horizontal breathing room required to prevent text from colliding with vertical red margin lines (in lined stationery) or grid columns are hard-coded independently in multiple places. The paper canvas manually calculates left and right insets based on background types, and regression test suites duplicate the exact same arithmetic.
- **Unpacked Geometry Parameter Drilling**: The paper canvas unpacks its layout results into five separate numeric parameters—layout metrics, active row height, horizontal left, horizontal right, and letterhead header height—and drills them into the text sheet view, which further passes them to continuation colophon headers and editor bodies.

## Solution

Deepen the **Stationery Sheet** geometry domain into a deterministic, cohesive geometry value object and consolidate template insets:

- **Cohesive Stationery Sheet Geometry Value Object**: Introduce a dedicated immutable geometry object that encapsulates the complete spatial contract of a tactile **Stationery Sheet** on the **Scholar's Desk**. Given the canvas dimensions, resting desk height, template styling, and typography, this value object computes the outer card dimensions, bounded **Paper Heart** (`innerFrameRect`), active line stride, **Sheet Row Capacity**, exact opening header height, body heights for opening and continuation sheets, continuation colophon positioning in the Heaven Margin, and template-specific horizontal text insets.
- **Deterministic Zero-Flutter Letterhead Layout**: Calculate the opening **Journal Letterhead** height directly from the reserved row count and line stride. Eliminate global key measurements, post-frame layout callbacks, and second-frame `setState()` rebuilds from the editor screen, ensuring frame 1 paints with zero pixel phase drift.
- **Consolidated Template Text Insets**: Establish a single source of truth for template-specific horizontal text insets and margin rules. Both the canvas painter that draws the vertical vermilion margin line and the geometry calculator that determines text padding consume the same configuration, guaranteeing that text margins and visual rulings stay synchronized.
- **Simplified Widget Seam**: Pass the unified geometry object directly from the paper canvas to the sheet views and desk lifters. The text sheet view receives a single geometry contract rather than five disparate numbers, and letterhead configuration retains only its authentic metadata and modification callbacks.

## User Stories

### First-Frame Visual Fidelity & Performance

1. As a diarist opening a diary entry on lined paper, I want the ruled lines, red margin line, and **Journal Letterhead** to paint at their final, correct positions on the very first frame, so that I never see a visual snap or jitter when the screen loads.
2. As a diarist switching between different paper templates (such as lined, square grid, dot grid, or plain rice paper), I want the layout geometry to recalculate synchronously during build, so that the editor never triggers redundant post-frame rebuilds.
3. As a diarist using custom typography with larger line strides (such as 29px), I want the 4-row **Journal Letterhead** height to immediately match $4 \times 29\text{px} = 116\text{px}$ without defaulting to 96px on frame 1, so that the stationery divider line perfectly aligns with the fourth baseline.

### Authentic Framing & Text Margin Alignment

4. As a diarist writing on lined paper with a vertical red margin line, I want my text to automatically indent with adequate breathing room to the right of the margin line, so that my handwriting glyphs never collide with or bleed over the vertical rule.
5. As a diarist writing on grid or dot-grid paper, I want my text to align seamlessly with the grid boundaries without unnecessary left margins, so that character cells coincide with grid intersections.
6. As a diarist writing on plain or colored wash paper, I want standard comfortable margins inside the classical **Paper Heart**, so that the text feels centered and framed by the **Double Outer Border**.

### Continuation Sheets & Colophon Consistency

7. As a diarist viewing a continuation **Stationery Sheet**, I want the colophon header (entry title and page number) to sit cleanly within the Heaven Margin above the **Paper Heart**, positioned deterministically by the geometry model without hard-coded pixel guesses in the widget.
8. As a diarist tapping the body of an opening or continuation sheet, I want the minimum height of the tappable writing area to match the exact ruled row capacity ($(\text{visibleRows} - 4) \times \text{lineStridePx}$ on sheet 1, and $\text{visibleRows} \times \text{lineStridePx}$ on continuation sheets), so that the entire ruled surface accepts taps and opens the keyboard smoothly.

### Architectural Maintainability & Testability

9. As a developer maintaining the editor, I want to verify all card dimensions, row capacities, letterhead heights, and margin clearances in fast, pure unit tests without pumping Flutter widget trees, so that layout regressions are caught instantly in CI.
10. As a developer updating the position of the vertical margin line on lined paper, I want the text indent to update automatically from the same shared constant, so that visual rulings and interactive text flow can never diverge.

## Implementation Decisions

### 1. New Module: Stationery Sheet Geometry (`editor/domain`)

Create an immutable value object representing the complete spatial contract of a tactile **Stationery Sheet** in the paginated editor.

- **Resolved Properties**:
  - `cardSize`: Outer dimensions (`width`, `height`) of the paper card resting on the desk, bounded between 380px and 420px in height with 16px bottom padding below the **Paper Heart**.
  - `cardHeight`: Convenience getter for `cardSize.height`.
  - `paperHeart`: The bounded `innerFrameRect` enclosing the ruling lines and text flow.
  - `lineStridePx`: Vertical distance between baselines.
  - `rowCapacity`: `SheetRowCapacity` encapsulating the maximum visible ruled rows.
  - `openingHeaderHeight`: Exactly four ruled rows ($4 \times \text{lineStridePx}$) reserved for the **Journal Letterhead**.
  - `openingBodyHeight`: Minimum height for the text editor on sheet 1 ($(\text{visibleRows} - 4) \times \text{lineStridePx}$).
  - `continuationBodyHeight`: Minimum height for the text editor on continuation sheets ($\text{visibleRows} \times \text{lineStridePx}$).
  - `continuationColophonRect`: Bounding rectangle for the running colophon in the Heaven Margin on continuation sheets.
  - `textInsets`: Insets relative to the **Paper Heart** (`left`, `right`) based on template style.
  - `textInsetsFromCardEdge`: Insets relative to the outer card edges, computed by combining `paperHeart` margin offsets with `textInsets`.
  - `usableTextWidth`: Available text width inside the **Paper Heart** after subtracting template text insets.
- **Factory Interface**:
  - `StationerySheetGeometry.resolve({required double canvasWidth, required double restingDeskHeight, required TemplateStyle templateStyle, TypographySettings? typography})`: Encapsulates the editor's 14-row maximum cap (`kStandardFolioRowsPerLeaf`), compact margin calculation, and outer card bounding.
  - The shared `StationeryLayoutCalculator` in `features/templates` remains unchanged for non-editor callers (PDF export, custom template designer previews, weekly debrief, and stationery fan panels).

### 2. Consolidated Template Text Insets (`templates/models`)

- Extract a cohesive configuration for template-specific horizontal text insets and margin rules.
- Define a canonical margin rule inset constant (24.0px) for the vertical vermilion margin line in lined stationery.
- Map template background types to horizontal insets:
  - Grid and dot-grid: 0.0px left, 0.0px right.
  - Lined paper: 32.0px left (24.0px margin line + 8.0px breathing clearance), 20.0px right.
  - Plain, colored, and custom wash: 20.0px left, 20.0px right.
- `TemplateCanvasPainter` and `StationerySheetGeometry` both consume this unified definition, ensuring single-point-of-truth alignment.
- Note: PDF export maintains its independent 12.0px margin line in vector page space to preserve print proportions.

### 3. Deletion of Redundant Letterhead Measurement & Snap Wrappers

- Remove `_letterheadKey`, `_headerHeight`, and `_updateHeaderHeight()` from the main editor screen state. The letterhead height is supplied deterministically via the resolved geometry.
- Remove `letterheadKey` and `headerHeight` from the letterhead configuration model, keeping only domain data and modification callbacks.
- Delete the integer-snapped letterhead layout widget and its render object. Replace its usage in the opening sheet view with a standard `SizedBox` sized to `geometry.openingHeaderHeight`.
- Standardize on the canonical reserved row constant (`kJournalLetterheadReservedRows = 4`) across the codebase, eliminating duplicate definitions in widget classes.

### 4. Simplified Editor Widget Interfaces

- Update the text sheet view to take a single `required StationerySheetGeometry geometry` parameter, replacing the four previously drilled numbers (`metrics`, `activeRowHeight`, `horizontalLeft`, `horizontalRight`) and the letterhead configuration's `headerHeight`.
- The paper canvas derives `StationerySheetGeometry` once per layout pass inside its layout builder, using the resting desk height provided by the chrome controller.
- All internal elements—card container sizing, canvas background container, desk lifter bounds, space budget inputs, and sheet views—consume values directly from the single geometry object.
- The post-frame coordinator synchronization (`coordinator.syncLayoutMetrics(...)`) is retained with its existing signature, fed directly from `geometry.usableTextWidth`, `geometry.lineStridePx`, and `geometry.rowCapacity.visibleRows`.

## Testing Decisions

### Good Test Principles for This Specification

Tests must verify external behavioral contracts and visual invariants, not internal widget private states:
1. **Deterministic Geometry Output**: Given specific viewport dimensions, template styles, and font sizes, the resolved geometry must produce exact, predictable numbers for card sizes, row capacities, header heights, and insets.
2. **Margin Clearance Invariant**: On lined paper, the calculated text start position must always exceed the vertical red margin line position by at least 8px across all valid viewport widths and font sizes.
3. **Zero First-Frame Phase Drift**: Widget tests must verify that on the very first frame of rendering an editor screen with custom line strides (e.g., 29px), the background canvas receives `headerHeight == 116.0` and no secondary frame rebuilds occur.

### Modules to Test

- **Unit Tests (`StationerySheetGeometry`)**:
  - Validate calculations across all template background types (lined, grid, dot-grid, wash/color).
  - Test boundary conditions for small viewports ($< 380\text{px}$) and large viewports ($> 420\text{px}$) to ensure card height clamping works as intended.
  - Validate typography scaling (standard 24px stride vs. customized 29px stride).
  - Verify that `openingBodyHeight` plus `openingHeaderHeight` accurately corresponds to total **Paper Heart** height.
- **Unit & Regression Tests (`TemplateTextInsets` & Margin Rule)**:
  - Verify that the lined margin rule inset constant is exactly 24.0px and the text inset is 32.0px.
  - Update existing paper heart bug regression tests to assert against the shared geometry object rather than re-implementing arithmetic.
- **Widget Tests (`EntryEditorScreen` & `EditorTextSheetView`)**:
  - Verify that opening sheets render the letterhead at exact snapped heights without throwing layout errors or overflowing constraints.
  - Verify that continuation sheets place the colophon text strictly above the **Paper Heart** in the Heaven Margin.
  - Verify that switching templates updates the geometry synchronously without post-frame state mutation cycles.

### Prior Art in Codebase

- `test/features/templates/stationery_layout_calculator_test.dart`: Pure unit test suite for layout metrics calculations.
- `test/features/editor/paper_heart_bug_repro_test.dart`: Regression tests asserting text clearance against margin lines.
- `test/features/editor/sheet_capacity_follows_visible_rows_test.dart`: Tests validating row capacity and letterhead row reservation.
- `test/features/editor/letterhead_editor_screen_test.dart`: Widget test harness for letterhead rendering and interactions.

## Out of Scope

- **Scholar's Desk Chrome & Space Budget Resolution**: Refactoring the chrome controller, resting desk height resolution, and double budget calculation belongs to Candidate 3.
- **Coordinator Synchronization Signature Refactoring**: Altering `coordinator.syncLayoutMetrics` to accept a structured value object belongs to a broader coordinator refactoring; the current signature is preserved.
- **PDF Export Margin Rule Unification**: PDF export uses independent 12px margins tailored to physical page aspect ratios and print typography; it is not modified here.
- **Vertical Keepsake Scroll / Tategaki Transformations**: Read-only vertical scroll styling remains governed by its dedicated view and is unaffected by editor sheet geometry.

## Further Notes

- This specification completes Candidate 2 of the codebase architecture review, establishing high depth and locality for all stationery sheet layout mathematics.
- Deleting the post-frame letterhead measurement cycle permanently removes an entire class of frame-1/frame-2 visual flickers and layout race conditions in the diary editor.
