# Reader & Library Polish — 2026-10-25

**Status:** Phase 1 implemented; owner retest pending
**Build:** `3bff002` · tag `asterisma-v1.0-polish-1`
**Package:** `dist/AsterismaV1.0-1.0-arm64.zip` · SHA-256 `a8ebf2ec1efd0b3513dd59a04a1efb8a830aefb2007b32632539906ba0517009`
**Benchmark:** Apple Books on macOS, plus Apple's public Books user guide

## What Apple Books exposes

Apple's Mac guide and current Books builds make the reading surface tunable:

- Six page themes: Original, Quiet, Paper, Bold, Calm, Focus.
- Font size with A-/A+ and reset.
- Font family, including Original and several serif/sans options.
- Bold text.
- Line spacing, character spacing, word spacing, and margins.
- Justify Text on/off.
- Allow Multiple Columns on/off (one or two pages).
- Light / Dark / Automatic page background.
- Auto-hyphenation.
- Page-turn style (Curl, Fast Fade, Scroll) and scrolling view on iOS.
- Reading controls that recede so the page owns the screen.

Primary references:

- https://support.apple.com/guide/books/change-a-books-appearance-ibks8923126d/mac
- https://support.apple.com/guide/iphone/read-books-iphc1af7c57/ios

## Phase 1 shipped

### Appearance panel

- Six Asterisma theme presets, each with its own page palette and typography
  starting point.
- Theme tiles with live `Aa` previews and a selected ring.
- Font menu: Original, New York, Georgia, Palatino, Charter, Iowan Old Style,
  Athelas, Avenir Next, Seravek, San Francisco, Times New Roman.
- Bold Text toggle.
- Text size A-/A+ plus slider, 80–200%.
- Line spacing, character spacing, word spacing, and margin sliders.
- Justify Text toggle.
- Columns: Auto / One / Two, with narrow-window fallback.
- Hyphenate toggle.
- Page turn: Slide / Fade / Instant.
- Show Page Numbers toggle.
- Reset Theme restores the active theme's typography and layout; text size is
  intentionally preserved.

### Reader chrome

- Top and bottom capsules now follow the page theme instead of always using a
  black pill with white text.
- Persistent chrome remains auto-hiding on the top-left.
- Page-number capsule can be hidden entirely.
- Edge clicks turn pages; this is implemented inside the document so trackpad
  scrolling and links keep working.
- Page turns animate with a short eased slide or a fast fade; instant remains
  available.

### Library polish

- Selected-book detail is now a horizontal book plate with a large cover,
  serif title, metadata pills, progress bar, and paired primary actions.
- Sidebar rows drop the boxed format badge and use a quieter metadata line with
  progress percentage.

## Deliberately still open

- Highlights, notes anchored to text, bookmarks, and in-book search.
- Vertical scroll reading mode.
- Page-curl animation.
- Per-theme customizations remembered separately.
- Brightness/dim overlay (macOS controls display brightness system-wide).
- Whole-book physical page map.
- Full VoiceOver/focus audit of the Appearance panel and edge-click behavior.

## Owner acceptance checklist

1. Open an EPUB and open Appearance from the `Aa` button.
2. Switch through all six themes; page colors and chrome should update live.
3. Change font, size, bold, spacing, and margins; text should reflow.
4. Toggle Justify and One/Two columns; page count should update honestly.
5. Try Slide/Fade/Instant page turns and hide page numbers.
6. Click the left and right page edges to turn pages.
7. Close and reopen the book; appearance settings should persist.
8. Select a book in the library; the new book plate should fit at 900×640.

## Next polish phases

1. **In-book navigation** — search, bookmarks, and a persistent chapter/page
   scrubber that matches Apple Books' reading position model.
2. **Annotations** — text selection, highlights, and notes anchored to EPUB
   CFI or a stable text offset.
3. **Reading modes** — vertical scroll as an alternative to columns, plus a
   page-curl presentation if it can be made performant in WKWebView.
4. **Per-theme memory** — remember custom font/spacing per theme rather than
   one global typography profile.
5. **Library finish** — shelf/grid alternative, richer resume state, and a
   consistent focus/hover token pass.
6. **Verification** — VoiceOver/keyboard matrix, narrow-window matrix, and a
   real-book visual pass on the owner's Mac.

## Verification

- Debug build: **BUILD SUCCEEDED**.
- `ReaderAppearanceTests`: **5/5 passed** — WCAG AA contrast for all six
  themes, legacy theme migration, theme defaults, full settings injection, and
  Original-font preservation.
- Prior accepted baseline: **218 passed / 0 failed / 9 skipped**.
- Full census rerun on 2026-10-25 was blocked before test discovery by the
  macOS UI-test runner (`testmanagerd` automation bootstrap). This is an
  environment failure, not an app assertion; the new suite and build were
  verified independently.
- Owner visual acceptance is still required for theme fit, spacing, page-turn
  feel, and the redesigned book plate.

## Session close

Committed as `3bff002` (docs `6bcea96`) and tagged
`asterisma-v1.0-polish-1`. The final signed package was preserved; generated
Xcode/test residue was removed. Graphify was rebuilt against the new source
(5,265 nodes / 11,862 edges); `graph.html` was regenerated as the aggregated
community view because the graph exceeds the default 5,000-node limit.
