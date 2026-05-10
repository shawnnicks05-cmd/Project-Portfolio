# SELECTA-COE Project Documentation

A concise guide to the app structure, main files, data flow, and how it is organized.

---

## What this project is

SELECTA-COE is a Flutter app for managing student portfolios and competency tracking.
Users can save profiles, skills, projects, certifications, education, experience, and achievements.
The app works offline with SQLite and can sync to Firestore when available.

---

## Project structure

- `lib/main.dart` — app startup, theme, routes.
- `lib/data/app_store.dart` — app state, authentication, CRUD logic.
- `lib/data/database_helper.dart` — local SQLite database operations.
- `lib/data/firebase_database_service.dart` — Firestore sync and engagement data.
- `lib/models/models.dart` — shared model classes.
- `lib/screens/` — UI screens for auth, home, search, profile, and database.
- `lib/widgets/` — reusable widgets such as `PillHeader`.
- `lib/theme.dart` / `lib/theme_provider.dart` — app theming and dark mode.
- `pubspec.yaml` — dependencies and assets.

---

## Main app flow

1. Startup begins in `main()`.
2. App initializes Firebase, theme, and `AppStore` state.
3. User lands on `AuthScreen`.
4. After login, app navigates to `HomeScreen`.
5. From home, user can manage profile, search, and edit records.

---

## Data management

### SQLite (`lib/data/database_helper.dart`)

- Stores users and related data in `selecta_coe.db`.
- Handles creation and migration of tables.
- Provides CRUD functions for users, skills, projects, certifications, education, experience, and achievements.

### App state (`lib/data/app_store.dart`)

- Keeps current user session.
- Loads data from SQLite on startup.
- Saves changes from the UI back to the database.
- Supports login, register, logout, profile updates, and search.

### Cloud sync (`lib/data/firebase_database_service.dart`)

- Syncs user data to Firestore when online.
- Records profile views and likes.
- Provides backup and search support.

---

## Key models

- `UserAccount` — main user profile and related record lists.
- `SkillCategory` / `Skill` — grouped skill data.
- `Project` — project details.
- `Certification` — certifications and issuer info.
- `EducationalAttainment` — education history.
- `Experience` — work or volunteer entries.
- `Achievement` — awards and recognitions.

---

## Primary screens

- `AuthScreen` — login and registration.
- `HomeScreen` — dashboard with navigation.
- `DatabaseScreen` — manage skills, projects, certifications, education, experience, achievements.
- `SearchScreen` — search across users and records.
- `ProfileScreen` — view/edit profile and privacy settings.

---

## How to use

- `flutter pub get`
- `flutter run`
- Login or register to start using the app.
- Use the database screen to add or edit portfolio items.
- Use search to find users and records.

---

## Notes

- The app persists theme choice and login session.
- Local SQLite is the primary storage.
- Firestore is optional and used for syncing and social features.
- This document is a brief reference; the code files contain the full implementation details.


**Key Features**:
- Bottom navigation bar with 4 tabs
- Dashboard tab with user statistics
- Database tab for skills/projects/certifications
- Search tab for global discovery
- Profile tab for user management

### `lib/screens/profile_screen.dart`

**Purpose**: User profile management and editing.

**Key Features**:
- Editable user profile fields
- Image picker for avatar
- Skills management (add/remove)
- Projects management
- Certifications management
- Real-time updates to database

### `lib/screens/search_screen.dart`

**Purpose**: Global search across all user data.

**Key Features**:
- Real-time search as you type
- Filter by type (Users, Skills, Projects, Certifications)
- Sort results (Name, Type, User)
- Detailed record view on tap
- Async search with loading states

### `lib/screens/database_screen.dart`

**Purpose**: Manage skills, projects, and certifications.

**Key Features**:
- Add/edit/delete skills with categories
- Add/edit/delete projects with tags
- Add/edit/delete certifications
- Proficiency level selection
- Tag management for projects

---

## 🎨 Theming System

### `lib/theme.dart`

**Purpose**: Centralized app theming and design system.

**Key Features**:
- Material Design 3 color scheme
- Custom color palette (primary, secondary, surface)
- Text styles and typography
- Consistent spacing and sizing
- Dark/light theme support preparation

---

## 🚀 App Entry Point

### `lib/main.dart`

**Purpose**: Application initialization and routing.

**Key Functions**:

#### Main Function
```dart
void main() async
```
- Initializes Flutter bindings
- Calls AppStore().init() to load database
- Starts the application

#### App Configuration
```dart
class SelectaCOEApp extends StatelessWidget
```
- Sets up MaterialApp with custom theme
- Configures initial routing based on login state
- Defines app routes (/ for auth, /home for main app)

---

## 🔧 Database Flow Diagram

```
App Launch
    ↓
main.dart → AppStore().init()
    ↓
DatabaseHelper._initDatabase()
    ↓
Create/Load SQLite Database
    ↓
Load Users from Database
    ↓
Check Session (SharedPreferences)
    ↓
Set Current User or Create Demo
    ↓
App Ready for User Interaction
```

---

## 🔄 Data Flow Patterns

### 1. User Registration
```
Registration Form → AppStore.createAccount() → DatabaseHelper.insertUser() → SQLite → Show Success Message → Switch to Login Tab
```
- User creates account but is NOT automatically logged in
- Registration form clears and switches to login tab
- User can then choose to sign in with their new credentials
- Account credentials are saved in SQLite database

### 2. User Login
```
Login Form → AppStore.login() → DatabaseHelper.getUserByEmail() → Validate → Set Current User → Navigate to Home
```

### 2.5. User Logout
```
Logout Button → AppStore.logout() → Clear Current User → Remove Session from SharedPreferences → Navigate to Auth Screen
```
- Properly clears current user state (_currentUser = null)
- Removes session from SharedPreferences (currentUserId)
- Updates UI listeners with notifyListeners()
- Redirects to authentication screen for fresh login
- Database remains intact - user data is preserved

### 3. Adding a Skill
```
Skill Form → AppStore.addSkillToCategory() → DatabaseHelper.insertSkill() → SQLite → Update UI
```

### 4. Search Operation
```
Search Query → AppStore.search() → DatabaseHelper.searchRecords() → SQLite → Return Results → Update UI
```

---

## 🛡️ Data Integrity Features

### Foreign Key Relationships
- Skills belong to Skill Categories
- Categories belong to Users
- Projects belong to Users
- Certifications belong to Users

### Indexes for Performance
- Email index for fast user lookup
- User ID indexes for related data
- Category ID indexes for skill lookup

### Error Handling
- Database connection failures
- Duplicate email prevention
- Data validation at model level
- Graceful fallbacks for missing data

---

## 📱 User Experience Features

### Real-time Updates
- Provider pattern for reactive UI
- Automatic data synchronization
- Loading states for async operations

### Search & Discovery
- Full-text search across all data
- Type-based filtering
- Multiple sort options
- Detailed record views

### Profile Management
- Editable profile fields
- Avatar management
- Skills tracking with proficiency
- Project portfolio
- Certification tracking

---

## 🔮 Future Enhancements

### Potential Features
1. **Cloud Sync** - Firebase/Supabase integration
2. **Offline Mode** - Enhanced local caching
3. **Export/Import** - Data portability
4. **Analytics** - Skill progress tracking
5. **Social Features** - User connections
6. **Recommendations** - Skill suggestions

### Scalability Considerations
- Database migration system ready
- Modular architecture for easy expansion
- Separation of concerns for maintenance
- Type-safe data models

---

## 📝 Summary

This SELECTA-COE application provides a comprehensive student competency tracking system with:

- **Robust Database**: SQLite with proper relationships and indexing
- **Clean Architecture**: Separated concerns with clear data flow
- **Modern UI**: Material Design 3 with consistent theming
- **Full CRUD Operations**: Complete data management capabilities
- **Search & Discovery**: Powerful search across all data types
- **User Management**: Authentication and profile management
- **Scalable Design**: Ready for future enhancements

The database migration from SharedPreferences to SQLite provides better performance, data integrity, and query capabilities while maintaining the same user experience.
