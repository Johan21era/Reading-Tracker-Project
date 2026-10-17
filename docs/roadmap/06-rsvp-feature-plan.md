# 06 · RSVP Feature Plan

*A standalone, toggleable RSVP reading mode for the Reading Tracker app, modeled on readrrr (iOS).*

**Method:** built from readrrr's own site and App Store listing, the published research behind the underlying RSVP/ORP technique (Spritz, 2013–2015), and a few open-source RSVP readers used as prior-art references — not a binary teardown, which Apple doesn't allow and which this doesn't require. RSVP is a well-documented, reproducible pattern, not a trade secret, so everything below is buildable from first principles.

---

## 1. What are they doing?

readrrr takes any text you feed it — a pasted article, an imported PDF or ePub, a scanned book page, or something from its built-in library of books, essays, and Wikipedia entries — and streams it one word at a time to a single fixed point on screen. The reader controls pace directly through the interaction itself: press and hold (or hold Space on a keyboard) to read, release to stop, and drag a slider to change speed, with typical use landing between 250 and 800+ WPM. Everything else in the app — a synced-audio Narrator, a Safari extension, highlights, a personal library — exists either to feed text into that one loop or to make it easy to come back to.

## 2. How did they do it?

Three mechanisms stack on top of each other, and this stack is identical across every RSVP app surveyed — it's the standard shape of the feature, not a proprietary trick. A tokenizer splits the source text into individual words; each word is rendered with one letter — the Optimal Recognition Point, positioned further into the word as the word gets longer — highlighted in red and pinned to the exact same x-position every single time, so the eye never has to search for a new starting point; and a pacing layer stretches or compresses each word's on-screen duration based on its length and trailing punctuation, so short words flash by, long words linger, and sentence ends get a beat to land. That combination — tokenize, pin-and-highlight, adaptive pacing — is what readrrr, Spritz before it, and every open-source RSVP reader examined are doing underneath their own UI polish.

## 3. Why?

Normal reading speed is bottlenecked less by how fast the brain processes language and more by the eyes — several small jumps ("saccades") per second, plus a "return sweep" back to the start of each new line, and each of those tiny movements is a moment attention can slip. Removing the eye's need to travel, by bringing the word to a fixed point instead of asking the eye to find it on a page, is the entire mechanism behind the WPM gains people report: average reading sits around 200–250 WPM, and RSVP readers commonly report 400–800+. Worth being direct about the tradeoff, since it should shape how this gets built: peer-reviewed research on Spritz specifically found it can impair literal comprehension and increase visual fatigue relative to normal reading, and earlier RSVP research found comprehension drops noticeably past roughly 500 WPM on anything longer than a single sentence — largely because the format removes the small regressions (glancing back a few words) that normal reading relies on more than most people notice. That's an argument for making speed, pause, and rewind first-class controls rather than an afterthought, not a reason to skip the feature.

## 4. How can we integrate it?

Build it as one fully self-contained module — text in, full-screen reading overlay out — with zero dependency on the Environment Engine, Spatial Library, or anything else already shipped; that's what makes "standalone, flip on/off" true rather than aspirational. Surface a single entry point (toolbar icon, keyboard shortcut, or context-menu item) anywhere the app already shows readable text — notes, quotes, imported articles — and gate the whole feature behind one "Speed Read" toggle in Settings, next to WPM, font, and — if you want to go beyond what readrrr itself offers — chunk-size controls, since showing 1–3 words per beat is a common customization in competing RSVP readers. All of it persists across sessions via `@AppStorage`. Nothing about this touches an existing view hierarchy beyond that one entry point and one settings section.

## 5. Is this plausible on Swift?

Yes, cleanly — arguably more so than on most platforms. Apple's NaturalLanguage framework ships a locale-aware word tokenizer (`NLTokenizer`) that solves the hardest part of tokenization for free; a `Timer` or an async `Task` loop handles WPM-paced advancement with no custom scheduling code; and pinning a word to its pivot letter is a two-`Text`-view layout trick, not a rendering challenge. The one real adaptation needed is interaction, not technology: readrrr is built around a touch-first press-and-hold gesture, so the macOS version should lean on its own native equivalent — hold Space to read, arrow keys to nudge speed, a draggable scrub bar — rather than porting a phone gesture onto a trackpad.

## 6. What would we need to do in order to achieve what they did?

Four pieces, in build order, each independently testable before the next depends on it: **(1)** decide the text source first — a tracker app doesn't necessarily hold full book text today, so pin down whether RSVP applies to pasted excerpts, existing notes/quotes, or newly-imported articles, since that single decision shapes everything downstream; **(2)** build the tokenizer and ORP calculator as pure logic with no UI — `NLTokenizer` for word boundaries, a small function mapping word length to pivot index — fully unit-testable in isolation; **(3)** build the playback engine, an `ObservableObject` holding WPM/position/play-state and driving a timer loop with per-word duration adjusted for length and trailing punctuation; **(4)** build the reader view and the Settings toggle last, once 1–3 are solid, so the feature is fully tested before it's ever wired into the running app. That order — logic before UI, UI before app-wide exposure — mirrors how Environment Engine's own phases are already sequenced, where wiring into `NewContentView.swift` is deliberately one of the last steps rather than the first.

---

## Appendix — technical scaffolding

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

```swift
// RSVPTokenizer.swift
import NaturalLanguage

enum RSVPTokenizer {
    static func words(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }
}
```

```
      prefix    pivot   suffix
  ┌───────────┬─────┬───────────┐
  │     under │  s  │  tanding  │
  └───────────┴─────┴───────────┘
                 ↑
        always the same x-position,
        regardless of word length
```

```swift
// ORPCalculator.swift
enum ORPCalculator {
    /// A common approximation of the published Spritz heuristic:
    /// the pivot moves deeper into the word as the word gets longer.
    static func pivotIndex(for word: String) -> Int {
        switch word.count {
        case 0...1:  return 0
        case 2...5:  return 1
        case 6...9:  return 2
        case 10...13: return 3
        default:     return 4
        }
    }
}
```

```swift
// RSVPPivotWordView.swift
import SwiftUI

struct RSVPPivotWordView: View {
    let word: String
    let pivotIndex: Int

    private var characters: [Character] { Array(word) }
    private var prefix: String { String(characters.prefix(pivotIndex)) }
    private var pivot: String {
        guard characters.indices.contains(pivotIndex) else { return "" }
        return String(characters[pivotIndex])
    }
    private var suffix: String {
        let start = pivotIndex + 1
        guard start < characters.count else { return "" }
        return String(characters[start...])
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(prefix).frame(width: 100, alignment: .trailing)
            Text(pivot).foregroundColor(.red).fontWeight(.bold)
            Text(suffix).frame(width: 100, alignment: .leading)
        }
        .font(.system(size: 36, weight: .medium, design: .monospaced))
    }
}
```

### C. Playback engine

```swift
// RSVPPlaybackEngine.swift
import Foundation
import Combine

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

```swift
// RSVPSettingsView.swift
import SwiftUI

struct RSVPSettingsView: View {
    @AppStorage("rsvp.enabled") private var isEnabled: Bool = false
    @AppStorage("rsvp.wpm") private var wordsPerMinute: Double = 300

    var body: some View {
        Toggle("Speed Read (RSVP)", isOn: $isEnabled)
        if isEnabled {
            Slider(value: $wordsPerMinute, in: 100...800, step: 25) {
                Text("Speed: \(Int(wordsPerMinute)) WPM")
            }
        }
    }
}
```

Every other part of the app checks `isEnabled` once, to decide whether to show the entry point at all — the reader module itself doesn't need to know Settings exists.

### E. Prior art worth a look

- **readrrr** — [App Store](https://apps.apple.com/us/app/readrrr-focus-reader/id6757683148) · [site](https://www.readrrr.app/) — the direct model for this feature.
- **chislerr/rsvp-reader** — [GitHub](https://github.com/chislerr/rsvp-reader) — open-source desktop RSVP reader (different stack: React/Tauri/Python) with a feature-complete scope worth comparing against: ORP highlighting, optional phrase grouping, library management, bookmarks, chapter navigation, smart punctuation pausing.
- **thomaskolmans/rsvp-reading** — [GitHub](https://github.com/thomaskolmans/rsvp-reading) — smaller, MIT-licensed, useful for seeing the ORP math and session-state pattern spelled out simply.

### Sources

- Readrrr — [App Store listing](https://apps.apple.com/us/app/readrrr-focus-reader/id6757683148), [official site](https://www.readrrr.app/)
- Benedetto et al., ["Rapid serial visual presentation in reading: The case of Spritz"](https://www.sciencedirect.com/science/article/abs/pii/S0747563214007663) — ScienceDirect, peer-reviewed
- ["Spritz and other speed reading apps: prose and cons"](https://theconversation.com/spritz-and-other-speed-reading-apps-prose-and-cons-24467) — The Conversation
- ["Tokenizing text with the Natural Language framework"](https://www.createwithswift.com/tokenizing-text-with-the-natural-language-framework/) — Create with Swift
