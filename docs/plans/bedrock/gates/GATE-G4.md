# Gate G4 — Weather that works (Open-Meteo)

**Date:** 2026-10-24
**Status:** PROVIDER + PIPELINE PASS
**Branch:** `bedrock/2026-10-24`

## Scope delivered

- [x] `WeatherProviding` protocol; `OpenMeteoProvider` (current + archive).
- [x] No WeatherKit entitlement required; WeatherKit stays optional behind the protocol.
- [x] 15 s request timeout, typed HTTP/malformed errors, no silent default city.
- [x] Current + archive endpoints; WMO code mapping; unit conversion
  (humidity/cloud 0–1, visibility m, snow cm→mm).
- [x] `WeatherKitService` now uses the provider for live/historical/forecast paths.
- [x] Location: `.notDetermined` and `.denied` no longer return NYC; they throw
  honestly; manual latitude/longitude fallback added to Settings ▸ Weather.
- [x] Weather panel shows a visible “Location is off — weather paused” banner.
- [x] Row-level `dataCoverageScore` now threads the real coverage ratio through
  `analyzeCorrelations` and both correlation builders.
- [x] Nearest-snapshot join is capped at ±1 hour.
- [x] Weather store honors `RT_TEST_STORE_DIR`; tests no longer write real weather DB.
- [x] `OpenMeteoProviderTests` (5) + live provider smoke + live pipeline test
  (session → snapshot → SQLite → range query → coverage).

## Verification

- Provider mapping tests: **5/5 pass**.
- Weather confidence suite: **5/5 pass**.
- Live provider smoke: **PASS** (real network, ~0.54 s).
- Live pipeline: **PASS** (session → snapshot → temp SQLite → range query, coverage 1.0).
- Weather live tests are opt-in (`RT_OPENMETEO_LIVE=1`), never part of the default census.
- Full census: **204 passed / 0 failed / 8 skipped** (212 cases; skips: 4 Mirage,
  benchmark, SQLite real-parity, 2 Open-Meteo live tests).

## Known deltas

- Weather snapshots still live in the legacy `weather_snapshots.sqlite3` until the
  G3B/G3C unified-DB cutover.
- Forecast/historical paths have no UI consumer today; provider support is ready.
- Manual location is latitude/longitude, not a city search.

## Rollback

```bash
git checkout bedrock-g3a
```

## Decision requested

- [x] APPROVE
- [ ] APPROVE WITH CHANGES
- [ ] STOP
