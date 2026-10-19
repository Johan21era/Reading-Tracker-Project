# 06 · RSVP Feature Plan

> **STATUS: SHIPPED.** RSVP speed-reading landed as **P5-B2** (commit `f5ec995`): tokenizer → playback engine → UI → wiring, and the hare button streams the current EPUB chapter or an entire PDF. This document is preserved as the *design record* — §6's four build steps are exactly the shape the implementation took. For the shipped feature's behavior, use the app; for its tests, see `07-testing-strategy.md` (tokenizer edge-coverage is the standing frontier).

## What this document is

A plan for adding **RSVP speed-reading** to Reading Tracker. RSVP ("Rapid Serial Visual Presentation") shows you one word at a time, pinned to the same spot on screen, so your eyes never have to travel across the page. It's modeled on the iOS app readrrr.

**Who should read this:** Anyone who wants to understand or build the speed-reading feature.

**What you'll find:**
- §1–3: Plain-English explanation of what RSVP is, how it works, and why
- §4: How to integrate it into this app (non-technical)
- §5: Why it's straightforward to build on this platform
- §6: Four build steps in order
- Appendix: Technical scaffolding (Swift code sketches) — only for people writing code

---

## 1. What is readrrr doing?

readrrr takes any text — a pasted article, an imported PDF or ePub, a scanned book page, or something from its built-in library — and streams it **one word at a time to a single fixed point on screen**.

You control the pace directly: press and hold (or hold Space on a keyboard) to read, release to stop, and drag a slider to change speed. Typical use lands between 250 and 800+ words per minute.

Everything else in readrrr — a synced-audio Narrator, a Safari extension, highlights, a personal library — exists either to feed text into that one loop or to make it easy to come back to it.

---

## 2. How does it work?

Three mechanisms stack on top of each other, and this stack is identical across every RSVP app surveyed — it's the standard shape of the feature, not a proprietary trick:

1. **Tokenize:** A splitter breaks the source text into individual words.
2. **Pin & highlight:** Each word is rendered with one letter — the **Optimal Recognition Point**, positioned further into the word as the word gets longer — highlighted in red and pinned to the exact same x-position every single time, so the eye never has to search for a new starting point.
3. **Adaptive pacing:** Each word's on-screen duration stretches or compresses based on its length and trailing punctuation — short words flash by, long words linger, sentence ends get a beat to land.

That combination — tokenize, pin-and-highlight, adaptive pacing — is what readrrr, Spritz before it, and every open-source RSVP reader examined are doing underneath their own UI polish.

---

## 3. Why build this?

Normal reading speed is bottlenecked less by how fast the brain processes language and more by the **eyes** — several small jumps ("saccades") per second, plus a "return sweep" back to the start of each new line, and each of those tiny movements is a moment attention can slip.

Removing the eye's need to travel — by bringing the word to a fixed point instead of asking the eye to find it on a page — is the entire mechanism behind the WPM gains people report:
- **Average reading:** ~200–250 words per minute
- **RSVP reading:** commonly 400–800+ words per minute

**Tradeoff to be direct about:** peer-reviewed research on Spritz found it can impair literal comprehension and increase visual fatigue relative to normal reading, and earlier RSVP research found comprehension drops noticeably past roughly 500 WPM on anything longer than a single sentence — largely because the format removes the small regressions (glancing back a few words) that normal reading relies on.

That's an argument for making **speed, pause, and rewind first-class controls** rather than an afterthought — not a reason to skip the feature.

---

## 4. How can we integrate it?

Build it as **one fully self-contained module** — text in, full-screen reading overlay out — with zero dependency on the Environment Engine, Spatial Library, or anything else already shipped. That's what makes "standalone, flip on/off" true rather than aspirational.

**Surface a single entry point** (toolbar icon, keyboard shortcut, or context-menu item) anywhere the app already shows readable text — notes, quotes, imported articles — and gate the whole feature behind one **"Speed Read" toggle in Settings**, next to WPM, font, and — if you want to go beyond what readrrr itself offers — **chunk-size controls** (showing 1–3 words per beat is a common customization in competing RSVP readers).

All of it persists across sessions. Nothing about this touches an existing view hierarchy beyond that one entry point and one settings section.

---

## 5. Why is this plausible on this platform?

Yes, cleanly — arguably more so than on most platforms.

- **Tokenization:** Apple's NaturalLanguage framework ships a locale-aware word tokenizer (`NLTokenizer`) that solves the hardest part for free.
- **Pacing:** A `Timer` or an async `Task` loop handles WPM-paced advancement with no custom scheduling code.
- **Pinning:** Pinning a word to its pivot letter is a two-view layout trick, not a rendering challenge.

The one real adaptation needed is **interaction, not technology**: readrrr is built around a touch-first press-and-hold gesture, so the macOS version should lean on its own native equivalent — hold Space to read, arrow keys to nudge speed, a draggable scrub bar — rather than porting a phone gesture onto a trackpad.

---

## 6. What do we need to do, in order?

Four pieces, each independently testable before the next depends on it:

| Step | What | Testable in isolation? |
|---|------|---|
| **1** | Decide the text source | Yes — product decision |
| **2** | Build tokenizer + ORP calculator (pure logic) | Yes — fully unit-testable |
| **3** | Build playback engine | Yes — ObservableObject with timer loop |
| **4** | Build reader view + Settings toggle | Yes — after 1–3 are solid |

**Order matters:** logic before UI, UI before app-wide exposure. This mirrors how Environment Engine's own phases are sequenced — wiring into the main app is deliberately one of the last steps.

**Step 1 — Decide the text source:** A tracker app doesn't necessarily hold full book text today, so pin down whether RSVP applies to pasted excerpts, existing notes/quotes, or newly-imported articles. That single decision shapes everything downstream.

---

## Appendix — technical scaffolding

*The sections below contain Swift code. They are for people writing the feature; you can skip them if you are not coding.*

### A. Suggested module layout

```
RSVPReader/
├── RSVPTokenizer.swift        // NLTokenizer wrapper → [String]
├── ORPCalculator.swift        // word → pivot index
├── RSVPPlaybackEngine.swift   // ObservableObject: wpm, isPlaying, currentWord, timer loop
├── RSVPReaderView.swift       // full-screen presentation + controls
├── RSVPPivotWordView.swift    // renders one word split at the pivot letter
└── RSVPSettingsView.swift     // toggle + speed/font controls
```

This folder has no imports from Environment Engine, Spatial Library, or Progressive Filtering — that isolation is what makes the on/off toggle safe to build without regression risk elsewhere.

### B. Tokenizer + the pivot-alignment trick (ORP)

```
      prefix    pivot   suffix
  ┌───────────┬─────┬───────────┐
  │     under │  s  │  tanding  │
  └───────────┴─────┴───────────┘
                   ↑
        always the same x-position,
        regardless of word length
```

### C. Playback engine

```swift
// RSVPPlaybackEngine.swift
@MainActor
final class RSVPPlaybackEngine: ObservableObject {
    @Published var currentWord: String = ""
    @Published var pivotIndex: Int = 0
    @Published var isPlaying = false
    @Published var wpm: Double = 300

    private var words: [String] = []
    private var index = 0
    private var task: Task<Void, Never>?

    func load(_ text: String) {
        words = RSVPTokenizer.words(from: text)
        index = 0
    }

    func play() {
        guard !words.isEmpty else { return }
        isPlaying = true
        task = Task {
            while isPlaying, index < words.count {
                let word = words[index]
                currentWord = word
                pivotIndex = ORPCalculator.pivotIndex(for: word)
                try? await Task.sleep(for: .seconds(interval(for: word)))
                index += 1
            }
            isPlaying = false
        }
    }

    func pause() {
        isPlaying = false
        task?.cancel()
    }

    private func interval(for word: String) -> Double {
        var seconds = 60.0 / wpm
        if word.count > 7 { seconds *= 1.25 }
        if word.hasSuffix(",") { seconds *= 1.5 }
        if word.hasSuffix(".") || word.hasSuffix("!") || word.hasSuffix("?") { seconds *= 2.0 }
        return seconds
    }
}
```

### D. Settings & toggle

Every other part of the app checks `isEnabled` once, to decide whether to show the entry point — the reader module itself doesn't need to know Settings exists.

### E. Prior art worth a look

- **readrrr** — App Store · official site — the direct model for this feature
- **chislerr/rsvp-reader** — open-source desktop RSVP reader with ORP highlighting, optional phrase grouping, library management
- **thomaskolmans/rsvp-reading** — smaller, MIT-licensed, useful for seeing the ORP math simply

### F. Sources

- Readrrr — App Store listing, official site
- Benedetto et al., "Rapid serial visual presentation in reading: The case of Spritz" — ScienceDirect, peer-reviewed
- "Spritz and other speed reading apps: prose and cons" — The Conversation
- "Tokenizing text with the Natural Language framework" — Create with Swift
