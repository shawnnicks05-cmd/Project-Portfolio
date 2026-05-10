# SELECTA-COE — Functions & Features Reference

A short overview of what the app does, where key logic lives, and the main user flows.

---

## What the app does

SELECTA-COE is a student portfolio and competency tracker.
Users can register, log in, edit their profile, add skills, projects, certifications, education, experience, and achievements, and search records across the app.

---

## Core architecture

- `lib/main.dart`: app startup, Firebase init, theme load, route setup.
- `lib/data/app_store.dart`: central state manager and business logic.
- `lib/data/database_helper.dart`: local SQLite storage and CRUD access.
- `lib/data/firebase_database_service.dart`: optional Firestore sync and engagement tracking.
- `lib/models/models.dart`: model classes for users, skills, projects, certifications, education, experience, achievements.
- `lib/theme.dart` / `lib/theme_provider.dart`: app themes and dark-mode persistence.

---

## Main screens

- `AuthScreen`: login and registration.
- `HomeScreen`: dashboard shell with navigation.
- `DatabaseScreen` (`credential_summary.dart`): add/edit skills, projects, certifications, education, experience, achievements.
- `SearchScreen`: search across users and records.
- `ProfileScreen`: view/edit profile and privacy settings.
- `AppLoadingScreen`: loader shown during startup.

---

## Key features

- Email/password login and registration.
- Profile editing with avatar, bio, contact info, and socials.
- Skills organized by category with proficiency values.
- Project, certification, education, experience, achievement entries.
- Search with filters and sorting.
- Privacy controls and profile views/likes.
- Local persistence with SQLite and optional Firestore sync.
- Light/dark theme toggle.

---

## Important app logic

### AppStore (`lib/data/app_store.dart`)

- Manages current user session and app state.
- Loads data from SQLite and saves changes.
- Provides login, registration, logout.
- Handles CRUD for skills, projects, certifications, education, experience, achievements.
- Performs search and permission checks.

### Database helper (`lib/data/database_helper.dart`)

- Creates `selecta_coe.db`.
- Defines tables for users and related data.
- Supports insert, update, delete, query operations.

### Firebase service (`lib/data/firebase_database_service.dart`)

- Syncs user data with Firestore when available.
- Records profile views and likes.
- Provides backup/search support.

---

## Models

- `UserAccount`: main profile data, privacy flags, lists of related records.
- `SkillCategory` / `Skill`: grouped competencies.
- `Project`: project details.
- `Certification`: certification records.
- `EducationalAttainment`: education entries.
- `Experience`: work or volunteer experience.
- `Achievement`: awards or accomplishments.

---

## Routes

- `/` → `AuthScreen`
- `/home` → `HomeScreen`

---

## Dependencies

- `provider`: state management.
- `cloud_firestore` / `firebase_core`: optional cloud sync.
- `sqflite` / `path`: local database.
- `shared_preferences`: saved session and theme.
- `image_picker`: avatar selection.
- `path_provider`: file export.
- `uuid`: stable IDs.

---

## Quick note

The docs are a reference, not the full implementation. For details, inspect the file names above and the corresponding Dart files.
