# Yogya App — Comprehensive Codebase Audit Report

> **Prepared for:** hiteshraj007/yogya  
> **Scope:** Full repository, line-by-line analysis  
> **Focus areas:** `sync_from_api.js`, timeline logic, real vs mock data  

---

## 1. Repository-Wide File Inventory

| Area | Files |
|------|-------|
| **App entry** | `lib/main.dart` |
| **Routing** | `lib/core/router/app_router.dart` |
| **Theme/Design** | `lib/core/theme/`, `lib/core/constants/colors.dart`, `app_animations.dart` |
| **Constants / Static data** | `lib/core/constants/exam_data.dart`, `india_data.dart`, `strings.dart` |
| **Core Services** | `lib/core/services/auth_service.dart`, `eligibility_service.dart`, `exam_timeline_service.dart`, `notification_service.dart`, `ocr_service.dart`, `ocr_profile_validator.dart`, `pdf_parser_service.dart`, `report_service.dart` |
| **Remote data** | `lib/data/remote/api_service.dart`, `firestore_exam_service.dart`, `firestore_sync_service.dart` |
| **Local data** | `lib/data/local/hive_service.dart` |
| **Data models** | `lib/data/models/` |
| **Data providers** | `lib/data/providers/auth_provider.dart`, `ocr_provider.dart` |
| **Presentation providers** | `lib/presentation/providers/remote_data_provider.dart`, `eligibility_provider.dart`, `profile_provider.dart`, `settings_provider.dart` |
| **Screens** | `dashboard`, `timeline`, `auth`, `profile`, `eligibility`, `documents`, `settings`, `splash`, `help`, `attempt_history`, `main_shell` |
| **Widgets** | `lib/presentation/widgets/common/` |
| **Sync tool (Node.js)** | `tools/sync/sync_from_api.js`, `.env` |
| **Seed tool (Node.js)** | `tools/seed/seed.js` |
| **Cloud Function** | `functions/index.js` |
| **Config** | `pubspec.yaml`, `firebase.json`, `.firebaserc`, `render.yaml` |

---

## 2. File-by-File Purpose & Behavior

### `lib/main.dart`
- Initializes Firebase, Hive (local storage), NotificationService.
- Firebase init is wrapped in try/catch so app stays alive even if Firebase is unavailable in dev.
- Launches Flutter app with `ProviderScope` + `GoRouter`.

### `lib/core/constants/exam_data.dart`
- Defines `ExamInfo` model and `ExamData.allExams` — a hardcoded catalog of 11 major Indian government exams (UPSC, SSC, IBPS, RRB, etc.) with eligibility rules, URLs, and metadata.
- This is **reference/catalog data**, not "mock" data — it reflects real exam requirements.
- **Previously also contained** two static getters `upcomingDeadlines` and `timelineEvents` that returned fully fake, relative-date mock lists. **These have been removed** in this PR.

### `lib/core/services/exam_timeline_service.dart`
- Contains `_calendar`: a hardcoded map of approximate annual exam dates (month/day only) for 10 exams.
- Used as **fallback** when Firestore is empty/unavailable.
- `upcomingDeadlines()` and `timelineEvents()` compute dates by projecting the template calendar onto the current/next year.
- **This is a smart fallback, not real data.** It produces approximate dates derived from historical patterns.

### `lib/data/remote/api_service.dart`
- REST client using `Dio` for a future backend at `https://api.example.com/v1`.
- **Critical finding (now fixed):** `simulateRealtime = true` caused ALL methods (`login`, `fetchExams`, `fetchDeadlines`, `fetchTimelineEvents`, etc.) to return mock/simulated data instead of calling any real endpoint. **Set to `false` in this PR.**
- When `simulateRealtime = false`, the class calls real REST endpoints (login, deadlines, timeline, exams).
- **Note:** `baseUrl = 'https://api.example.com/v1'` is a placeholder. This service is not yet connected to a real backend — Firestore is the live data source.

### `lib/data/remote/firestore_exam_service.dart`
- **The primary real-data service.** Reads from Firestore collections: `exam_deadlines`, `timeline_events`, `exams`.
- `fetchDeadlines()` / `fetchTimelineEvents()`: one-shot async fetches with `whereIn` filter (≤10 exam IDs).
- `watchTimelineEvents()` / `watchDeadlines()`: **real-time Firestore streams** that auto-push UI updates when Cloud Function writes new data.
- Proper null-safe field access and date fallback (`DateTime.now()` if Timestamp missing).

### `lib/data/remote/firestore_sync_service.dart`
- Syncs user profile and academic documents between Hive (local) and Firestore.
- `syncProfileToCloud()`, `syncDocToCloud()`, `deleteDocFromCloud()`, `syncDownFromCloud()`.
- Safe: uses `SetOptions(merge: true)` so partial updates don't overwrite full documents.
- **Minor issue:** uses `print()` for error logging instead of a proper logging framework.

### `lib/presentation/providers/remote_data_provider.dart`
- Riverpod providers for exam data, deadlines, timeline.
- `allExamsProvider`: fetches from Firestore; falls back to `ExamData.allExams` if empty.
- `timelineStreamProvider` / `deadlinesStreamProvider`: real-time Firestore stream providers — UI auto-refreshes.
- `deadlinesProvider` / `timelineEventsProvider`: legacy one-shot FutureProviders (kept for backward compat).

### `lib/presentation/screens/timeline/timeline_screen.dart`
- Watches `timelineStreamProvider` (Firestore real-time stream).
- Falls back to `ExamTimelineService.instance.timelineEvents()` (approximate calendar data) when stream is loading or empty.
- **Text fix applied:** was showing "Syncing timeline from live simulation..." — corrected to "Syncing latest timeline from Firestore...".
- Filter chips, deadline banner, future eligibility projections all work correctly.

### `lib/presentation/screens/dashboard/dashboard_screen.dart`
- Watches `deadlinesStreamProvider` (Firestore real-time stream).
- No fallback to mock data — shows empty list when stream produces nothing.
- Eligible exam count computed from Hive cache or live profile data.

### `tools/sync/sync_from_api.js`
- Manual script to sync data from RapidAPI → Firestore.
- **See Section 3 for deep review.**

### `tools/seed/seed.js`
- One-time seed script to populate Firestore with initial sample data.
- Clearly labeled `// -------- SAMPLE DATA --------`.
- Marks documents with `source: "manual_seed"` so they can be identified and replaced.
- Intended to be run **once** before real API sync is set up.

### `functions/index.js`
- Firebase Cloud Function (`scheduledSync`) that runs every 6 hours.
- Fetches from two RapidAPI endpoints (results + jobs), normalizes, deduplicates, and batch-upserts to Firestore.
- Writes `sync_meta/meta` doc with status, counts, and timestamp.
- **See Section 3 for comparison with `sync_from_api.js`.**

---

## 3. Deep Review: `sync_from_api.js`

### Before fixes (original state)

| # | Issue | Line(s) | Severity |
|---|-------|---------|----------|
| 1 | **ENV var mismatch (runtime crash):** `.env` defines `RAPIDAPI_URL_RESULTS` and `RAPIDAPI_URL_JOBS`, but `fetchApiRows()` checked for `RAPIDAPI_URL` (absent). Script would always throw "Missing RAPIDAPI_KEY / RAPIDAPI_HOST / RAPIDAPI_URL". | 548–551 | 🔴 Critical |
| 2 | **No `sync_meta` tracking:** Success/failure status was never written to Firestore. Impossible to monitor sync health. | — | 🟠 High |
| 3 | **No serviceAccount env fallback:** Hardcoded `fs.readFileSync(./serviceAccountKey.json)` — no support for `FIREBASE_SERVICE_ACCOUNT` env var (needed for CI/CD). | 496–498 | 🟠 High |
| 4 | **No full try/catch in `runSync()`:** If `upsertCollection()` failed after fetch succeeded, there was no error status written to Firestore and no clean exit. | 622–639 | 🟡 Medium |
| 5 | **Single-endpoint fetch:** Used only one `RAPIDAPI_URL` instead of two (results + jobs) like the Cloud Function does. | 547–562 | 🟡 Medium |
| 6 | **ID generation:** Used `${examId}_${type}_${date.toMillis()}` — non-deterministic when same event comes from different API calls (milliseconds vary). Creates duplicate docs. | 613 | 🟡 Medium |
| 7 | **Dead code:** ~470 lines of commented-out earlier iterations. Confusing and hard to maintain. | 1–485 | 🟢 Low |

### After fixes (this PR)

- **ENV vars corrected**: Now reads `RAPIDAPI_URL_RESULTS` and `RAPIDAPI_URL_JOBS` to match `.env`.
- **Two-endpoint fetch**: Fetches both results and jobs endpoints, matching Cloud Function behavior.
- **Deterministic IDs**: Uses `makeDeterministicId(prefix, title, link)` → base64url, preventing duplicates.
- **In-memory dedupe**: Map deduplication by `sourceUrl__event` before writing to Firestore.
- **`sync_meta` tracking**: Writes success/failure status, counts, and timestamps.
- **ServiceAccount env fallback**: Reads `FIREBASE_SERVICE_ACCOUNT` env var first, then falls back to file.
- **Full try/catch**: `runSync()` now writes failure status to Firestore and exits with code 1 on error.
- **Dead code removed**: All commented-out iterations cleaned up.

---

## 4. Deep Review: Timeline Code Paths

### Data Flow

```
RapidAPI (every 6h via Cloud Function)
    ↓
functions/index.js → Firestore (timeline_events, exam_deadlines)
    ↓
firestore_exam_service.dart → watchTimelineEvents() stream
    ↓
remote_data_provider.dart → timelineStreamProvider
    ↓
timeline_screen.dart → real-time UI update
         ↓ (fallback when empty)
    ExamTimelineService._calendar → approximate dates
```

### Correctness Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| Real-time streaming | ✅ Correct | `watchTimelineEvents()` uses Firestore snapshots |
| Fallback behavior | ✅ Acceptable | Falls back to ExamTimelineService approximate dates |
| Completed flag | ✅ Correct | `date.isBefore(now)` |
| Sorting | ✅ Correct | Sorted by date ascending in both Firestore service and provider |
| Filtering by exam | ✅ Correct | `whereIn` query (≤10 items) or full collection scan |
| Edge case >10 exams | ⚠️ Partial | `whereIn` limited to 10; if >10 eligible exams, full collection returned |
| Timeline screen fallback text | ✅ Fixed | Was "live simulation", now "Firestore" |

---

## 5. Data Provenance Audit

### Real Data ✅

| Source | Where Used |
|--------|-----------|
| Firestore `timeline_events` collection | `firestore_exam_service.dart` → `timeline_screen.dart` |
| Firestore `exam_deadlines` collection | `firestore_exam_service.dart` → `dashboard_screen.dart` |
| Firestore `users` collection | `firestore_sync_service.dart` |
| RapidAPI Sarkari Result | `functions/index.js` (Cloud Function), `tools/sync/sync_from_api.js` |
| Firebase Auth (Google/email) | `auth_service.dart` |
| Device OCR / PDF parser | `ocr_service.dart`, `pdf_parser_service.dart` |

### Mock / Approximate Data (was being served as real) ⚠️ — Fixed

| File | What | Fix Applied |
|------|------|-------------|
| `lib/data/remote/api_service.dart` | `simulateRealtime = true` caused ALL endpoints to return fake data | **Set to `false`** |
| `lib/core/constants/exam_data.dart` | `upcomingDeadlines` / `timelineEvents` static getters with relative-date hardcoded lists labeled "Mock" | **Removed** |
| `lib/presentation/screens/timeline/timeline_screen.dart` | Text "Syncing timeline from live simulation..." | **Fixed to "Syncing latest timeline from Firestore..."** |

### Reference / Catalog Data (intentional, correct)

| File | What | OK? |
|------|------|-----|
| `lib/core/constants/exam_data.dart` | `allExams` — exam catalog with eligibility rules | ✅ Static reference data |
| `lib/core/services/exam_timeline_service.dart` | `_calendar` — approximate annual dates | ✅ Fallback only |
| `tools/seed/seed.js` | Sample seed data marked `source: "manual_seed"` | ✅ One-time bootstrap only |

---

## 6. Security & Reliability Findings

| # | Finding | File | Line | Severity | Fix Applied |
|---|---------|------|------|----------|-------------|
| S1 | **Real RapidAPI key committed to repo** in `tools/sync/.env` | `.env` | 1 | 🔴 Critical | Key rotated to placeholder; `.env` added to `.gitignore` |
| S2 | `baseUrl = 'https://api.example.com/v1'` — placeholder URL in production code | `api_service.dart` | 11 | 🟠 High | Needs real backend URL when REST API is built |
| S3 | `simulateRealtime = true` — app was serving mock data to users | `api_service.dart` | 15 | 🟠 High | **Set to `false`** |
| S4 | `firebase.json` — Firebase config exposed; no separate dev/prod environments | `firebase.json` | — | 🟡 Medium | Acceptable for open-source; use `.firebaserc` aliases for dev/prod |
| S5 | `print()` used for error logging in sync service | `firestore_sync_service.dart` | 42, 64, 131 | 🟢 Low | Replace with proper logger in production |
| S6 | Firebase init in `main.dart` swallows all init errors | `main.dart` | 130 | 🟢 Low | Should at least log the error |
| S7 | Firestore `whereIn` limited to 10 values — silent fallback to full scan | `firestore_exam_service.dart` | 27–29 | 🟡 Medium | Add paginated batch query for >10 exam IDs |
| S8 | `date` field fallback to `DateTime.now()` when Timestamp is missing | `firestore_exam_service.dart` | 41, 73 | 🟡 Medium | Silently corrupts event ordering; log a warning |

---

## 7. Defect List with Severity & Remediation

### 🔴 Critical (Fixed)

**D1 — Exposed API key in version control**
- File: `tools/sync/.env`
- The real RapidAPI key `2386d2f84cmsh...` was committed. Anyone with repo access could abuse the key.
- **Fix:** Key replaced with placeholder; `.env` added to `.gitignore`; `.env.example` created.
- **Action required:** Rotate the leaked key in the RapidAPI dashboard.

**D2 — `sync_from_api.js` always crashed on startup (ENV mismatch)**
- File: `tools/sync/sync_from_api.js`, line 548
- `RAPIDAPI_URL` was never defined in `.env`, so `fetchApiRows()` always threw immediately.
- **Fix:** Updated to use `RAPIDAPI_URL_RESULTS` + `RAPIDAPI_URL_JOBS`, matching `.env`.

### 🟠 High (Fixed)

**D3 — App served mock data to all users (`simulateRealtime = true`)**
- File: `lib/data/remote/api_service.dart`, line 15
- Every API call (login, fetchExams, fetchDeadlines, fetchTimelineEvents) returned fake in-memory data.
- **Fix:** Set `simulateRealtime = false`.

**D4 — No `sync_meta` tracking in manual sync script**
- File: `tools/sync/sync_from_api.js`
- Sync health was unmonitorable; failures were only logged to console.
- **Fix:** Added `sync_meta/meta` Firestore write on both success and failure.

**D5 — No `serviceAccountKey.json` env fallback**
- File: `tools/sync/sync_from_api.js`, line 496–498
- Script crashed in CI/CD environments without a local key file.
- **Fix:** Added `FIREBASE_SERVICE_ACCOUNT` env var support with graceful error message.

### 🟡 Medium (Not fixed — needs owner action)

**D6 — Misleading text "live simulation" in timeline screen**
- File: `lib/presentation/screens/timeline/timeline_screen.dart`, line 231
- **Fix applied:** Changed to "Syncing latest timeline from Firestore..."

**D7 — Firestore `whereIn` silent fallback for >10 exam IDs**
- When a user tracks >10 exams, the filter is silently dropped and the full collection is returned.
- Recommendation: Implement batched `whereIn` queries in groups of 10.

**D8 — `DateTime.now()` fallback for missing Timestamp**
- Silent data corruption: if `date` field is absent in a Firestore doc, the event appears as happening "right now".
- Recommendation: Log a warning; consider filtering out such documents.

**D9 — `ExamTimelineService._calendar` uses hardcoded approximate dates**
- Only covers 10 exams; dates are approximations, not real official dates.
- These are acceptable as fallback but should not be the primary data source.
- Recommendation: Ensure Cloud Function sync is running so Firestore has real data.

### 🟢 Low

**D10 — Dead code in `sync_from_api.js`**
- ~470 lines of commented-out iterations before the active code.
- **Fix applied:** Active section rewritten cleanly; dead code removed.

**D11 — Mock `upcomingDeadlines` / `timelineEvents` getters in `ExamData`**
- Relative-date fake lists that could accidentally be used.
- **Fix applied:** Removed.

---

## 8. Final Verdict

### ✅ Is `sync_from_api.js` correct now?

**Before this PR: NO** — The script had a fatal ENV variable mismatch (`RAPIDAPI_URL` not defined) causing it to crash immediately on every run. It also lacked error handling, `sync_meta` tracking, and used a fragile single-URL fetch instead of the two-endpoint model used by the Cloud Function.

**After this PR: YES** — The script correctly reads `RAPIDAPI_URL_RESULTS` + `RAPIDAPI_URL_JOBS`, uses deterministic document IDs, deduplicates in memory, writes sync status to `sync_meta`, handles errors gracefully, and supports both file-based and env-var Firebase credentials.

### ✅ Is timeline logic correct now?

**Before this PR: PARTIALLY** — The Firestore stream (`watchTimelineEvents`) was architecturally correct, but the UI showed "Syncing from live simulation" (misleading) and fell back to `ExamTimelineService` approximate data. The `simulateRealtime = true` flag meant timeline data in `ApiService` was always fake.

**After this PR: YES** — Timeline reads from Firestore real-time stream. Falls back to `ExamTimelineService` calendar (approximate, but labeled correctly) only when Firestore is empty. UI text is accurate.

### ✅ Does the app avoid mock data?

**Before this PR: NO** — `simulateRealtime = true` in `ApiService` meant login tokens, exam lists, deadlines, and timeline events were all fake. Additionally, `ExamData` had static mock getters with relative-date fake data.

**After this PR: YES** — `simulateRealtime = false`. All data paths go through Firestore. The only "approximate" data is `ExamTimelineService._calendar` which is used as a fallback when Firestore is empty, and `ExamData.allExams` which is a legitimate reference catalog (not mock event data).

---

## Action Items for Maintainers

1. **URGENT: Rotate the leaked RapidAPI key** — the old key `2386d2f84cmsh...` was public in git history. Go to RapidAPI dashboard and regenerate immediately.
2. Deploy or trigger `functions/index.js` (`scheduledSync`) to populate Firestore with real data so the app never shows fallback calendar data.
3. Update `baseUrl` in `api_service.dart` when a real REST backend is built.
4. Replace `print()` calls in `firestore_sync_service.dart` with a proper logger.
5. Consider implementing batched `whereIn` queries to handle users tracking >10 exams.
