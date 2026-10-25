# Asterisma v1.0 — Beta UX Audit & Remediation Register

**Date:** 2026-10-25
**Evidence:** owner screenshots captured approximately 01:06–01:07 AM, plus live
testing reports
**Scope:** library dashboard, EPUB reader, window chrome, navigation, typography,
floating controls, persistence, accessibility, macOS integration
**Status:** handoff document — not a claim that every finding is fixed

> **Important:** the screenshots predate the paged-reader candidate
> (`asterisma-v1.0-ux-audit-2`). Several findings below are already addressed
> in that build; each row carries its current disposition. Any "fixed" claim
> still requires owner visual acceptance.

---

## Evidence and severity

| Label | Meaning |
|---|---|
| OBSERVED | Directly visible in the screenshots |
| STRONG CONCERN | Screenshot evidence plus a design risk; needs user testing |
| VERIFY | Plausible failure mode; not confirmable from a static screenshot |
| PRODUCT DECISION | Requires explicit product direction |

| Severity | Meaning |
|---|---|
| P0 | Release blocker: data loss, broken core workflow, security, inaccessible primary path |
| P1 | High: substantial obstacle to reading, navigation, or discoverability |
| P2 | Medium: recurring friction, weak feedback, accessibility/usability risk |
| P3 | Polish after core workflow correction |

No P0 runtime defect is established by the screenshots alone.

---

## Finding register

| ID | Severity | Evidence | Finding | Current disposition |
|---|---|---|---|---|
| ASTER-001 | P1 | OBSERVED + STRONG CONCERN | Sparse library leaves a huge unexplained canvas | **Partially fixed** — explicit empty state and selected-book detail with Open action added |
| ASTER-002 | P2 | OBSERVED | Count and icon actions have weak semantics | **Partially fixed** — Add/More now have tooltips and accessibility labels; count semantics still open |
| ASTER-003 | P2 | OBSERVED + STRONG CONCERN | One book card is tiny relative to the canvas | **Partially fixed** — selected-book detail gives a large cover/title/Open surface; shelf/list layout still a product decision |
| ASTER-004 | P2 | OBSERVED + VERIFY | Search scope/live behavior/no-results state unclear | **Fixed in candidate** — explicit no-results state and Clear Search action; keyboard search audit remains |
| ASTER-005 | P2 | OBSERVED + PRODUCT DECISION | Starfield may compete with text/controls | **Open** — reduce brightness/density near chrome only after contrast testing |
| ASTER-006 | P1 | OBSERVED | Floating reading-status panel overlaps reader navigation/text | **Fixed in candidate** — ReadingHUD is hidden while a reader is open |
| ASTER-007 | P1 | OBSERVED + STRONG CONCERN | Toolbar chapter label can disagree with document heading (25 vs 12) | **Mitigated** — labels now fall back to spine index when TOC count differs; deterministic retest required |
| ASTER-008 | P2 | OBSERVED + VERIFY | Back/forward arrow scope ambiguous | **Superseded** — native reader toolbar hidden; compact Back/chapter controls replace it; verify discoverability |
| ASTER-009 | P2 | OBSERVED | Chapter navigation looks disconnected from document heading | **Partially fixed** — chapter list and title now derive from one spine-index source; visual hierarchy still needs design |
| ASTER-010 | P1 | OBSERVED + VERIFY | Progress metadata ambiguous/crowded | **Partially fixed** — HUD shows chapter/page + book percentage and a progress bar; global book-page map remains a product decision |
| ASTER-011 | P1 | OBSERVED | Reading estimates only via hover | **Fixed in candidate** — selecting a book shows a detail surface with a Reading Estimate action; hover is no longer the only path |
| ASTER-012 | P2 | OBSERVED | Right-side icon controls lack visible context | **Partially fixed** — primary reader controls now have tooltips/accessibility labels; remaining icon audit open |
| ASTER-013 | P1 | OBSERVED + VERIFY | Floating/persistent reader layers lack a formal model | **Partially fixed** — HUD removed; top-left controls auto-hide after 3s, pause while hovered/popover-open, and return via a reveal control; layering spec still needed |
| ASTER-014 | P1 | OBSERVED + VERIFY | EPUB text column/typography may be too wide/small | **Fixed in candidate** — 620pt column cap, font size, line spacing, alignment, and reading themes; full typography regression remains |
| ASTER-015 | P2 | OBSERVED + PRODUCT DECISION | Bright document inside dark shell is a stark transition | **Fixed in candidate** — light, sepia, and dark reading themes |
| ASTER-016 | P2 | OBSERVED + VERIFY | Sidebar behavior in reading mode unclear | **Fixed in candidate** — sidebar auto-hides while reading; Back restores it with selection intact |
| ASTER-017 | P2 | OBSERVED | Selected-book metadata is compressed/duplicated | **Partially fixed** — large selected-book detail; card/detail metadata contract still needed |
| ASTER-018 | P2 | VERIFY | Save-status model unclear | **Fixed in candidate** — exact chapter/page persists on page changes and immediately on close; regression test added |
| ASTER-019 | P2 | OBSERVED + VERIFY | Narrow/split-screen/macOS scaling behavior untested | **Partially fixed** — floor lowered to 900×640 and pagination switches to one column; full responsive matrix still required |
| ASTER-020 | P2 | VERIFY | Hover/focus/selection/disabled states not established | **Partially fixed** — reader controls now have an explicit visible/hidden/hovered model; global token and state audit required |
| ASTER-021 | P2 | OBSERVED | Persistent top-left reader controls never yield the page | **Fixed in candidate** — controls fade after 3s, pause while hovered or while a popover/sheet is open, and return via a small reveal control |

---

## First five investigations

### 1. Chapter 25 / Chapter 12 mismatch

**Root cause found:** `Book.chapters` is built from TOC entries at import time,
while the reader's `currentChapterIndex` is a spine index. The two counts are
not guaranteed to match. Indexing TOC titles by spine position can therefore
show a title from the wrong chapter.

**Candidate fix:** chapter titles and the chapter list now fall back to
`Chapter N` from the spine when TOC count and spine count differ. A
deterministic retest with the same book is required.

### 2. Floating status panel

**Fixed in candidate:** ReadingHUD is suppressed whenever the reader is open.
Reader status now lives in the compact floating controls instead of overlapping
the document.

### 3. Narrow-window reader behavior

**Open:** the window floor is 1000×680 and pagination shows one column below
1000pt, two columns above. Split-screen, display scaling, and popover bounds
still need a formal test matrix.

### 4. Reading estimates without hover

**Fixed in candidate:** selecting a book shows a large detail card with cover,
title, author, format, pages, progress, an Open action, and a **Reading
Estimate** action. The hover path remains, but is no longer the only path.

### 5. Sparse-library layout

**Partially fixed:** zero books now shows a deliberate empty state with Add Book,
and one selected book gets a large detail/resume surface. Shelf/grid/list and
resume-first layouts remain a product decision, not a settled design.

---

## Second remediation batch (candidate)

- Search no-results state + Clear Search.
- Tooltips/accessibility labels for Add, More, Back, chapter list, RSVP, info,
  reading settings, and page navigation.
- Reader typography popover: text size, line spacing, left/justified alignment.
- Light / sepia / dark reading themes.
- Cover/titlepage-only spine items filtered out of the reading flow.
- Sidebar auto-hides while reading and returns with the selection intact.
- Book-level progress percentage and progress bar alongside chapter/page.
- Window floor lowered to 900×640; reader falls back to one page below 1000pt.
- Accessibility labels on primary reader controls.

Still product decisions / open verification:

- Whole-book physical page map (chapter/page + percentage is the current model).
- Starfield contrast/density specification.
- Remaining icon and focus-state audit.
- Full responsive and screen-reader matrix.
- Shelf/grid/resume library layout beyond the selected-book detail.
- Design-token migration across every legacy surface.

---

## Third refinement (owner-requested, candidate)

- Floating upper-left reader controls fade out after 3 seconds of inactivity.
- Hovering the controls cancels the hide timer; leaving restarts it.
- The controls stay visible while a popover or sheet is open.
- When hidden, a small top-left reveal control restores them; hovering the
  reveal control also restores them.
- Chapter changes deliberately re-show the controls with the new label.

This is a reading-focus refinement, not a replacement for the remaining
layering specification below.

---

## Product decisions still required

1. Is Asterisma primarily a reader or a library manager?
2. Is the starfield global or library-specific?
3. Is the sidebar persistent, collapsible, or contextual?
4. Do back/forward arrows mean history, chapters, or app navigation?
5. What is the authoritative progress representation?
6. What belongs on a card versus a details panel?
7. Which controls are always visible versus overflow?
8. Are reading estimates essential or secondary?
9. What happens when opening a previously-read book?
10. How should incomplete EPUB metadata be handled?
11. Which reading settings persist globally versus per book?
12. What is the intended narrow-window behavior?
13. Which keyboard shortcuts exist and how are they discovered?
14. What is the save/restore contract?
15. What accessibility standard is required for beta?

---

## Remediation phases

### Phase 1 — clarity and correctness
- Deterministic chapter/spine retest.
- Remove/replace any remaining overlapping reader panel. *(candidate done)*
- Clarify reader navigation and progress model. *(candidate in progress)*
- Verify reading-position synchronization. *(candidate done; retest pending)*
- Make estimates available without hover.

### Phase 2 — reading ergonomics
- Typography controls (size, line spacing, alignment).
- Sidebar collapse/width behavior in reader.
- Contrast/focus/reduced-motion audit.
- Responsive matrix: 1000pt, 1280pt, 1512pt, fullscreen, split-screen.

### Phase 3 — library quality
- Shelf/list/resume layout decision.
- No-results search state.
- Card/detail metadata contract.
- Import progress and failure feedback.

### Phase 4 — visual polish
- Starfield brightness/density near chrome.
- Icon weight and spacing.
- Hover/selection transitions.
- Shell/document surface relationship.

---

## Beta QA matrix

The audit's L-001…L-010, R-001…R-016, and S-001…S-006 scenarios are accepted as
the beta QA matrix. They must be executed against the **paged-reader candidate**
before visual acceptance, not against the older screenshots.

Minimum gates:

- Keyboard-only library and reader workflows.
- Exact position restore after close/relaunch.
- No chapter/toolbar/document mismatch.
- No overlay overlaps at supported window sizes.
- Search no-results and query reset.
- Every icon-only control has an accessible name and tooltip.
- Reader typography remains usable at narrow and wide widths.
- Fullscreen entry/exit without losing position.

---

## Current candidate references

```text
Second UX-audit candidate: 936ba504337d6cb6663c66f736cee0bcb64491a6b0abf2588f0fd9bcc1a566ed
Code:                   8a68136
Tag:                    asterisma-v1.0-ux-audit-2
Census:                 218 passed / 0 failed / 9 skipped
```

The audit is a living register. A finding moves to **fixed** only after the
owner reproduces the acceptance criteria in the real application.
