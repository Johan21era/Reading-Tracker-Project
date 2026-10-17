# Reading Tracker — Testing Strategy

Companion to `AUDIT_REPORT.md` and `TECH_DEBT.md`. Where those documents describe what's wrong, this describes what to build so the same classes of bug get caught automatically next time, rather than by another full manual audit pass.

## Step zero: make the test target real

Every recommendation below is moot until Audit §6.1 / Tech Debt D3 is fixed: **`Reading TrackerTests` currently runs exactly one empty placeholder test.** Before writing a single new test, either:
- Add `WeatherKitService2.swift`'s three existing suites to the `Reading TrackerTests` synchronized folder (converting `XCTestCase`/`XCTAssert*` to `Testing`/`@Test`/`#expect` for consistency with the stub file already there), or
- Give the test target explicit Sources membership and confirm `XCTest.framework` is actually linked for it.

Either way, confirm with a deliberately-failing assertion that `⌘U` / `xcodebuild test` actually reports a failure — right now there's no evidence that path has ever been exercised, so it's worth not assuming it works even after the fix.

## Testing pyramid for this app

```
        /  UI/Flow tests  \        Few — launch, import, delete, session lifecycle end-to-end
       /  Integration tests \      Some — DataStore read/write round-trips, Achievement→toast queue, SQLite store
      /     Unit tests        \    Many — pure functions: AnalyticsEngine, EstimationEngine, AchievementEngine, DifficultyAnalyzer, date math
```
This codebase is unusually well-suited to a unit-heavy pyramid: most of the highest-risk logic (`AnalyticsEngine`, `EstimationEngine`, `AchievementEngine2`, `DataIntegrityValidator`, `WeatherAnalysisEngine`) is already written as pure `enum`-namespaced static functions or side-effect-free structs with no SwiftUI or persistence dependency — exactly the shape that's cheap to unit test and currently has close to zero coverage actually running.

## What to cover, mapped to what's actually risky here

| Area | Test type | Why (ties to audit finding) |
|---|---|---|
| `DataStore.save()` / `loadBooks()` failure paths | Unit + integration | D1 — inject a `FileManager` that fails writes; assert the new failure-surfacing property gets set, not just `print()`-ed |
| `deleteItems` / multi-index removal | Unit | §2.1 — feed a multi-index `IndexSet` and assert the correct book IDs are removed, not index-shifted ones |
| Achievement toast queue | Unit | §2.2 — assert two simultaneously-earned achievements both eventually surface, and that a mid-toast arrival doesn't get dropped |
| `BehaviorContextAccessKit.startMonitoring`/`stopMonitoring` | Integration | §4.1 — assert observer count doesn't grow across repeated start/stop cycles (this is exactly the kind of bug a "call stop→start 50 times, assert no duplicate notifications" test catches immediately) |
| `AnalyticsPeriod.dateRange` / `.previousPeriod` | Unit, parameterized by `Calendar` | §5.1 — run the existing logic against a Hebrew or Japanese `Calendar` explicitly, not just `.current` on the test machine, to catch the force-unwrap risk in CI regardless of the CI runner's locale |
| `WeatherSnapshotStore` round-trip | Integration (already written, just not running) | §6.1 |
| `DataIntegrityValidator.validate` | Unit | D1/§3.3 — assert `hasUnrepairableErrors` is both computed correctly *and* actually changes `loadBooks()`'s behavior once that's wired up |
| `NewYearCelebrationOverlay` timer chain | Unit (with a controllable clock/scheduler, not real `Timer`) | §8.1 — inject a fake timer source so tests can force the "disappear mid-phase-transition" race deterministically instead of relying on real 1.5–10s timing windows |

**Skip:** `Book`/`Chapter`/`ReadingSession` model `Codable` conformance (auto-synthesized, low-value to hand-test), SwiftUI view layout code, the Developer Console (debug-only, not user-facing).

## Example test cases

A few concrete ones, written against what the code actually looks like today, to make "add tests for this" less abstract:

```swift
// Regression test for Audit §2.1 — deleteItems index-shift bug
@Test func deletingMultipleBooksRemovesCorrectOnes() {
    let store = DataStore(inMemory: true) // or however the store is made test-injectable
    let books = (0..<6).map { Book.mock(title: "Book \($0)") }
    books.forEach(store.addBook)
    let toDelete = IndexSet([2, 5])
    // exercise the same logic ContentView.deleteItems uses
    let idsToDelete = Set(toDelete.map { store.books[$0].id })
    idsToDelete.forEach { store.removeBook(id: $0) }
    #expect(store.books.count == 4)
    #expect(store.books.map(\.title).sorted() == ["Book 0", "Book 1", "Book 3", "Book 4"])
}

// Regression test for Audit §4.1 — observer duplication across start/stop cycles
@Test func repeatedStartStopDoesNotDuplicateScreenLockObservers() async {
    let kit = BehaviorContextAccessKit()
    for _ in 0..<10 { kit.startMonitoring(); kit.stopMonitoring() }
    NotificationCenter... // post a synthetic com.apple.screenIsLocked and assert recordEvent fires exactly once, not 10x
}

// Regression test for Audit §3.3 — unrepairable errors shouldn't get silently resaved
@Test func unrepairableCorruptionIsNotSilentlyPersisted() {
    let corrupted = [Book.mock(withInvalidPageRange: true)]
    let (repaired, report) = DataIntegrityValidator.validate(corrupted)
    #expect(report.hasUnrepairableErrors == true)
    // once loadBooks() is fixed to check this flag: assert save() was NOT called / .bak was preserved
}
```

## Coverage gaps to close, roughly in priority order

1. **Zero running tests today** for anything (Step zero above) — this is the actual current state, not "low coverage."
2. **Persistence failure paths** — no test anywhere exercises a failed write, a failed directory creation, or a corrupted-but-decodable file with unrepairable content.
3. **Concurrency/lifecycle** — nothing tests repeated start/stop, repeated appear/disappear, or rapid double-invocation of anything (`startReading` re-entry, `spawnParticles` re-entry). These are exactly the categories this audit's methodology found real bugs in by inspection; they're also the categories unit tests catch cheaply and permanently once written.
4. **Calendar/locale edge cases** — nothing pins `AnalyticsEngine` behavior against a non-Gregorian calendar, so a regression here would currently only surface as a field crash report from an affected user, not a CI failure.
5. **The Environment Engine / Spatial Library / Progressive Filtering systems** have no tests at all yet — reasonable given they're not wired in (Audit §1.1), but worth building alongside the Part 12 wiring work rather than after, especially for `AdaptiveLayoutTier`'s boundary logic and the `NewYearCelebrationOverlay` timer chain (§8.1), which is exactly the kind of narrow-timing-window bug that's far cheaper to catch with a fake clock in a unit test than by manual QA.
