# Milestones

## 001 — First successful EPUB import and read on a clean slate

**Date and time:** 2026-10-25 00:08:33 EDT (−0400)
**Recorded by:** the engineering session, immediately after the owner’s report
**Build:** `dist/AsterismaV1.0-1.0-arm64.zip`
**SHA-256:** `c77b61af98a6b193f17882bc4abd72119b67b6a232473aa67490e149dcdad649`
**Code:** `3281450` · tag `asterisma-v1.0-import-fix`

### What happened

For the first time, the owner:

1. opened the Add Book picker,
2. selected an EPUB from `Desktop/library tests`,
3. imported it successfully,
4. opened it in the reader, and
5. actually read it.

The live store confirms the full loop, not just the picker:

```text
1 book / 1 session / 24 page timings
```

### Why this is monumental

This is the first clean-slate, end-to-end proof of the app’s core promise:

```text
choose a book → import it → see it in the library → open it → read it
→ record a real reading session and page timings
```

It validates the file picker contract, iBooks-style EPUB package support, the
import pipeline, the library surface, the reader, and session timing together.
After the recent erase/reset work, this is a genuinely fresh library rather
than a carry-over from old test data.

### What this does not mean

This is a **capability milestone**, not a declaration that every issue is
fixed. Multiple unrelated issues remain, and the owner’s test results remain
the absolute source of truth. It means the central product loop is now real
and repeatable.

### Evidence

- Owner report, recorded at the timestamp above.
- Live SQLite library: 1 book / 1 session / 24 page timings.
- Package checksum above.
- Picker/package regression tests and full census: **217 passed / 0 failed /
  9 skipped** at this build.

### Next

Keep reading. Use **More (…) → Erase Library & Data…** between test sessions
when a clean slate is useful, and keep recording owner results as the truth of
record.

---

## 002 — RSVP speed reader survived deliberate abuse

**Date and time:** 2026-10-25 00:17:54 EDT (−0400)
**Recorded by:** the engineering session, immediately after the owner’s report
**Build:** `dist/AsterismaV1.0-1.0-arm64.zip`
**SHA-256:** `c77b61af98a6b193f17882bc4abd72119b67b6a232473aa67490e149dcdad649`

### What happened

The owner deliberately tried to break the RSVP speed-reader feature:

- violently dragged its sliders,
- pushed its buttons in rapid succession,
- changed settings mid-flow.

It stayed responsive. No crash, freeze, “beachball,” or visual crack. The owner
described it as “unusually crisp.”

The live store after the session: **1 book / 4 sessions / 50 page timings**.

### Why it matters

The RSVP surface is a high-frequency interaction surface: rapid slider changes
and button presses can expose re-entrancy, timer, layout, or cancellation bugs
that ordinary reading never touches. It held up under deliberate abuse.

### Future polish (not a defect in this milestone)

- Make the RSVP typography designable.
- Consider honoring the EPUB’s chosen font rather than using a fixed reader
  font.

### Scope note

This milestone covers RSVP stability only. It does not claim that the EPUB
pagination/page-count issues reported in the same session are resolved.

---

## 003 — Beta audit remediation accepted: the core reader works end to end

**Date and time:** 2026-10-25 01:46:44 EDT (−0400)
**Recorded by:** the engineering session, immediately after the owner’s report
**Build:** `dist/AsterismaV1.0-1.0-arm64.zip`
**SHA-256:** `936ba504337d6cb6663c66f736cee0bcb64491a6b0abf2588f0fd9bcc1a566ed`
**Code:** `8a68136` · tag `asterisma-v1.0-ux-audit-2`

### What happened

The owner resumed live testing after the second UX-audit remediation batch and
reported that **everything worked perfectly**:

- EPUB import and open.
- Reading and page turns.
- Typography/theme controls.
- Sidebar hiding in reading mode.
- Search and selected-book detail.
- Reading-progress restoration.
- The paged reader and its controls.

Live store at the report: **1 book / 3 sessions / 20 page timings**.

### Why it matters

This is the first time the complete product loop has passed the owner’s real
testing after the beta-audit remediation work:

```text
import → open → read → navigate → change reading settings
→ leave → reopen at the saved position
```

The remaining request is a refinement, not a broken workflow: auto-hide the
floating upper-left reader controls after a few seconds and reveal them on
demand.

### Scope note

This is owner-accepted behavior for the tested build. It does not convert every
remaining product decision in the UX audit into a completed feature.
