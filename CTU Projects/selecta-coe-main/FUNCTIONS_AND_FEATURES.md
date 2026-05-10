# SELECTA-COE — Functions & Features Reference

This document describes what the Flutter app does, screen by screen, and what the main classes and methods are responsible for.  
**Package name:** `selecta_coee` · **Product name:** SELECTA-COE (Student Electronic Ledger & Competency Tracker).

---

## High-level architecture

| Layer | Role |
|--------|------|
| **UI (`lib/screens/`, `lib/widgets/`)** | Auth, home shell, dashboard, searchable ledger, profile editor, loading splash. |
| **State (`lib/data/app_store.dart`)** | Singleton `ChangeNotifier`: login, profiles, privacy, skills/projects/certs/education/experience/achievements, search, recent views, sync hooks to Firebase/SQLite. |
| **Local DB (`lib/data/database_helper.dart`)** | SQLite (`selecta_coe.db`) for users and related tables; migrations on upgrade. |
| **Cloud (`lib/data/firebase_database_service.dart`)** | Firestore: users doc + subcollections for skills, projects, certifications, education, experience, achievements; profile views/likes. |
| **Models (`lib/models/models.dart`)** | `UserAccount`, `SkillCategory`, `Skill`, `Project`, `Certification`, `EducationalAttainment`, `Experience`, `Achievement` — JSON for prefs/Firestore/SQLite. |
| **Theme (`lib/theme.dart`, `lib/theme_provider.dart`)** | Material 3 light/dark themes; persisted theme toggle. |

---

## App entry & startup (`lib/main.dart`)

| Symbol | What it does |
|--------|----------------|
| **`main()`** | Ensures Flutter bindings, immediately `runApp(_BootstrapApp)` so UI appears without waiting on I/O. |
| **`_BootstrapApp` / `_BootstrapAppState`** | Wraps startup: Firebase init + Firestore probe, `AppStore().init()`, optional Firebase test data, `ThemeProvider.init()`. Shows loading, error + retry, or `SelectaCOEApp`. |
| **`_runStartup()`** | Async pipeline above; catches errors and surfaces them. |
| **`SelectaCOEApp`** | `MultiProvider` with `AppStore` + `ThemeProvider`; `MaterialApp` with routes `/` → `AuthScreen`, `/home` → `HomeScreen`. |

---

## Screens & user-visible features

### `AppLoadingScreen` (`lib/screens/app_loading_screen.dart`)

- Shown during `_BootstrapApp` startup.
- Branding: logo asset, title, subtitle, progress indicator.

### `AuthScreen` (`lib/screens/auth_screen.dart`)

- **Tabs:** Login and Register.
- **Login:** Email/password; validates against `AppStore.login`; navigates to `/home` on success.
- **Register:** Collects account fields; `AppStore.createAccount` (local + Firebase when available).
- **Theme toggle** in app bar via `ThemeProvider.toggleTheme`.
- **Auto-fill:** When returning from register (or similar flows), credentials can be passed into the login tab (`_handleAutoFill`, `_onTabChanged`, `_LoginFormState.autoFillCredentials`).

### `HomeScreen` (`lib/screens/Dashboard.dart`)

- **Shell:** Animated slide-out **sidebar** (`_SideDrawer`) with nav items; overlay tap closes drawer.
- **Bottom / drawer destinations (tabs):** Dashboard tab, **Database** screen, **Search**, **Profile** (see `_pages`).
- **App bar:** `PillHeader` + dark/light toggle.
- **`_DashboardTab`:** If no `currentUser`, redirects to `/`. Otherwise shows:
  - Profile summary card (`_ProfileCard`) with avatar, like button (`AppStore.toggleProfileLike` / `isProfileLiked`), stats.
  - Sections: Top Competencies, Recent Projects, Certifications, Education, Experience, Achievements (from `UserAccount`).
- **Export:** Uses `dart:io` / `dart:convert` in this file for sharing or file output where implemented (same module hosts dashboard helpers).

### `DatabaseScreen` (`lib/screens/credential_summary.dart`)

> **Note:** The file path is `credential_summary.dart`, but the top-of-file comment incorrectly says `database_screen.dart`. The widget class is **`DatabaseScreen`** — the full **CRUD / ledger** UI for skills, projects, certifications, education, experience, achievements, and related dialogs (limits, stable IDs for Firestore, theme-aware inputs).

### `SearchScreen` (`lib/screens/search_screen.dart`)

- Text search over aggregated records via **`AppStore.search(query)`**.
- **Filters** by record type (Users, Skills, Projects, etc.).
- **Sort** by name, type, or owning user.
- Tapping results can open **`ProfileScreen`** in view-only mode for other users.

### `ProfileScreen` (`lib/screens/profile_screen.dart`)

- **Own profile vs other user:** `userId` optional; `viewOnly` prevents editing when appropriate.
- **Edit mode:** Controllers for name, email, phone, course, student ID, location, bio, social links, year level; **image picker** for avatar; save via `AppStore.updateCurrentUser`.
- **Privacy:** Uses store rules for private sections and approved viewers.
- **Profile views:** `AppStore.recordProfileView` when viewing someone else.
- **Summary widgets:** e.g. `SummaryItem` for stat chips.

---

## Reusable widgets

### `PillHeader` (`lib/widgets/pill_header.dart`)

- Custom `PreferredSizeWidget` app bar: pill-shaped bar, leading icon (menu/back/etc.), title, trailing actions, optional `SafeArea`.

---

## `AppStore` (`lib/data/app_store.dart`) — main public API

Singleton (`AppStore()`). Key **getters:** `accounts`, `currentUser`, `isLoggedIn`, `recentlyViewedProfiles`.

| Method | Purpose |
|--------|---------|
| **`init()`** | Load demo user from `SharedPreferences`, SQLite accounts, current user id, recently viewed profiles. |
| **`login` / `logout` / `createAccount`** | Session and registration; persists and syncs where configured. |
| **`updateCurrentUser`** | Persist profile changes locally and to Firebase when possible. |
| **`getUserById`** | Resolve a user for profile/search flows. |
| **`canViewSkills` / `canViewProjects` / `canViewCertifications`** | Respect privacy + approved viewers. |
| **`canUserViewPrivateContent`** | Synchronous helper for viewer vs target. |
| **`toggleProfilePrivacy(section)`** | Flip privacy flags per section. |
| **`recordProfileView` / `toggleProfileLike` / `isProfileLiked`** | Social/engagement metrics (Firebase-backed when available). |
| **`loadRecentlyViewedProfiles` / `getRecentlyViewedUsers` / `clearRecentlyViewedProfiles`** | Recent profiles list. |
| **`addSkillToCurrentUserFromRecord`** | Add skill from search/other record. |
| **`addSkillCategory` / `addSkillToCategory` / `removeSkill`** | Skill tree CRUD. |
| **`addProject` / `removeProject`** | Projects. |
| **`addCertification` / `removeCertification`** | Certifications. |
| **`addEducationalAttainment` / `updateEducationalAttainment` / `removeEducationalAttainment`** | Education history. |
| **`addExperience` / `updateExperience` / `removeExperience`** | Work/volunteer experience. |
| **`addAchievement` / `updateAchievement` / `removeAchievement`** | Achievements. |
| **`updateCareerObjective`** | Career objective text + privacy. |
| **`getAllRecords` / `search`** | Flattened records for database/search UIs. |

Internal helpers (`_save`, `_loadAccountsFromDatabase`, `_upsertAccountLocal`, `_updateOtherUser`, `_demoAccount`) support the above.

---

## `FirebaseDatabaseService` (`lib/data/firebase_database_service.dart`)

Firestore singleton. Typical responsibilities:

- **`insertUser` / `updateUser` / `deleteUser`** and **`_saveRelatedData` / `_deleteRelatedData`** — user document plus nested skill/project/cert/education/experience/achievement data.
- **Per-entity getters/inserts/updates/deletes** for subcollections (e.g. `getSkillCategoriesForUser`, `insertProject`, …).
- **`getAllUsers` / `getUserByEmail` / `getUserById`** — load users with nested data.
- **`recordProfileView` / `likeProfile` / `unlikeProfile` / `isProfileLiked`** — engagement.
- **`searchRecords`** — server-side style aggregation for search (used with local logic as wired in the store).
- **`createTestData`** — Dev/demo seed (invoked from startup when Firebase works).
- **`_sync*` helpers** — Keep Firestore subcollections aligned with a `UserAccount` graph.

---

## `DatabaseHelper` (`lib/data/database_helper.dart`)

- Opens SQLite `selecta_coe.db` at version **9** with `onCreate` / `onUpgrade`.
- Tables include **users**, **skill_categories**, **skills**, **projects**, **certifications** (and additional tables/migrations as defined in the file).
- CRUD methods mirror domain entities for offline-first storage (see file for full list).

---

## `DatabaseExporter` (`lib/utils/database_exporter.dart`)

- **`exportUserAccount(UserAccount user)`** — Writes a human-readable text report under app documents (`SELECTA_COE_Exports/`), including snapshot from `FirebaseDatabaseService.getAllUsers()` where used in the template.

---

## `ThemeProvider` (`lib/theme_provider.dart`)

| Method / property | Purpose |
|-------------------|---------|
| **`init()`** | Read `SharedPreferences` for saved dark mode. |
| **`toggleTheme()`** | Flip light/dark and persist. |
| **`themeMode` / `isDarkMode`** | Drives `MaterialApp.themeMode`. |

---

## `AppTheme` (`lib/theme.dart`)

- **`lightTheme` / `darkTheme`** — Full `ThemeData` (Material 3, CTU-style red primary).
- **Static color tokens** — e.g. `lightPrimary`, `darkSurface`, etc.
- **Helpers** — `getColor`, `getSurface`, `getSurfaceVariant`, `getTextPrimary`, `getTextMuted`, etc., for widgets that need explicit colors outside `Theme.of(context)`.

---

## Data models (`lib/models/models.dart`) — feature summary

- **`UserAccount`** — Core profile + nested lists + privacy flags + `approvedViewers` + `profileViews` / `profileLikes` / `likedBy`; **`totalSkills`**, **`avgCompetency`** computed getters; **`toJson` / `fromJson`**.
- **`SkillCategory` / `Skill`** — Grouped competencies with proficiency %.
- **`Project`**, **`Certification`**, **`EducationalAttainment`**, **`Experience`**, **`Achievement`** — Portfolio sections with JSON serialization.

---

## Routes

| Route | Screen |
|-------|--------|
| **`/`** | `AuthScreen` |
| **`/home`** | `HomeScreen` (dashboard shell) |

---

## Dependencies (feature mapping)

| Package | Use in app |
|---------|------------|
| **provider** | `AppStore` + `ThemeProvider` above `MaterialApp`. |
| **firebase_core / cloud_firestore** | Cloud sync, test data, profile views/likes. |
| **sqflite / path** | Local SQLite via `DatabaseHelper`. |
| **shared_preferences** | Demo account JSON, current user id, theme, recent profile IDs. |
| **image_picker** | Profile photo from gallery/camera. |
| **path_provider** | Export directory for `DatabaseExporter`. |
| **intl** | Timestamps in export text. |
| **uuid** | Stable IDs where used. |
| **font_awesome_flutter** | Icons in UI where referenced. |

---

## Maintenance tip

After deleting the **`build/`** folder (generated output), restore it with:

`flutter pub get` then `flutter run` or `flutter build …` — no manual restore of `build/` is required.
