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
