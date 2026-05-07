# SELECTA-COE Project Documentation
## Student Electronic Ledger & Competency Tracker

---

## 📁 Project Structure Overview

```
selecta-coe-main/
├── lib/
│   ├── data/
│   │   ├── app_store.dart          # Main state management
│   │   └── database_helper.dart    # SQLite database operations
│   ├── models/
│   │   └── models.dart             # Data models
│   ├── screens/
│   │   ├── auth_screen.dart        # Login/Registration
│   │   ├── home_screen.dart        # Main dashboard
│   │   ├── profile_screen.dart     # User profile management
│   │   ├── search_screen.dart      # Global search functionality
│   │   └── database_screen.dart    # Skills/Projects/Certifications
│   ├── theme.dart                  # App theming
│   └── main.dart                    # App entry point
├── android/                        # Android configuration
└── pubspec.yaml                    # Dependencies
```

---

## 🗄️ Database System

### `lib/data/database_helper.dart`

**Purpose**: Handles all SQLite database operations for the app.

**Key Tables**:
1. **users** - User profiles and account information
2. **skill_categories** - Groups skills by category (e.g., "Programming Languages")
3. **skills** - Individual skills with proficiency levels
4. **projects** - Student projects with descriptions and tags
5. **certifications** - Professional certifications

**Core Functions**:

#### Database Initialization
```dart
Future<Database> _initDatabase() async
```
- Creates database file at `selecta_coe.db`
- Sets up all tables with proper schema
- Creates indexes for performance optimization

#### Table Creation
```dart
Future<void> _onCreate(Database db, int version) async
```
- Creates 5 main tables with foreign key relationships
- Establishes indexes for faster queries
- Ensures data integrity with constraints

#### User Operations
```dart
Future<int> insertUser(UserAccount user)           // Add new user
Future<List<UserAccount>> getAllUsers()            // Get all users
Future<UserAccount?> getUserByEmail(String email)  // Find user by email
Future<UserAccount?> getUserById(String id)        // Find user by ID
Future<int> updateUser(UserAccount user)            // Update user data
Future<int> deleteUser(String id)                  // Delete user
```

#### Skill Operations
```dart
Future<List<SkillCategory>> getSkillCategoriesForUser(String userId)
Future<int> insertSkillCategory(SkillCategory category, String userId)
Future<List<Skill>> getSkillsForCategory(String categoryId)
Future<int> insertSkill(Skill skill, String categoryId)
```

#### Project & Certification Operations
```dart
Future<List<Project>> getProjectsForUser(String userId)
Future<int> insertProject(Project project, String userId)
Future<List<Certification>> getCertificationsForUser(String userId)
Future<int> insertCertification(Certification certification, String userId)
```

#### Search Functionality
```dart
Future<List<Map<String, dynamic>>> searchRecords(String query) async
```
- Performs full-text search across all data types
- Returns unified results for users, skills, projects, certifications
- Supports filtering by type and sorting

---

## 🏪 State Management

### `lib/data/app_store.dart`

**Purpose**: Central state management using Provider pattern with ChangeNotifier.

**Key Properties**:
```dart
List<UserAccount> _accounts = []        // All users in system
UserAccount? _currentUser                // Currently logged-in user
```

**Core Functions**:

#### Initialization
```dart
Future<void> init() async
```
- Loads all users from SQLite database
- Sets up current user from session (SharedPreferences)
- Creates demo account if no users exist
- Handles database errors gracefully

#### Authentication
```dart
Future<bool> login(String email, String password) async
```
- Validates credentials against database
- Sets current user on successful login
- Updates session state

```dart
Future<bool> createAccount(UserAccount account) async
```
- Creates new user account in database
- Checks for email duplicates
- Auto-logs in new user

```dart
Future<void> logout() async
```
- Clears current user session
- Removes session from SharedPreferences

#### User Data Management
```dart
Future<void> updateCurrentUser(UserAccount updated) async
```
- Updates user data in database
- Synchronizes all related data (skills, projects, certifications)

#### Skill Management
```dart
Future<bool> addSkillToCurrentUserFromRecord({required String category, required Skill skill})
Future<void> addSkillCategory(SkillCategory cat)
Future<void> addSkillToCategory(String catId, Skill skill)
Future<void> removeSkill(String catId, String skillId)
```

#### Project & Certification Management
```dart
Future<void> addProject(Project project)
Future<void> removeProject(String projectId)
Future<void> addCertification(Certification cert)
Future<void> removeCertification(String certId)
```

#### Search & Discovery
```dart
Future<List<Map<String, dynamic>>> getAllRecords() async
Future<List<Map<String, dynamic>>> search(String query) async
```

---

## 📊 Data Models

### `lib/models/models.dart`

**Purpose**: Defines all data structures used throughout the app.

#### UserAccount
```dart
class UserAccount {
  String id;                    // Unique identifier
  String name;                  // Full name
  String email;                 // Email address (unique)
  String phone;                 // Phone number
  String password;              // Encrypted password
  String course;                // Academic course
  String yearLevel;             // Academic year
  String studentId;             // Student ID number
  String location;              // Geographic location
  String avatarInitials;       // Avatar text initials
  String avatarUrl;             // Profile image URL
  String bio;                   // User biography
  String instagramUrl;          // Social media links
  String facebookUrl;
  List<SkillCategory> skillCategories;  // User's skills
  List<Project> projects;                 // User's projects
  List<Certification> certifications;    // User's certifications
}
```

#### SkillCategory
```dart
class SkillCategory {
  String id;           // Unique identifier
  String name;         // Category name (e.g., "Programming")
  List<Skill> skills;  // Skills in this category
}
```

#### Skill
```dart
class Skill {
  String id;                    // Unique identifier
  String name;                  // Skill name (e.g., "Python")
  String level;                  // Proficiency level
  double proficiencyPercent;     // Skill percentage (0-100)
}
```

#### Project
```dart
class Project {
  String id;           // Unique identifier
  String title;        // Project title
  String description;   // Project description
  String date;          // Completion date
  int memberCount;     // Team size
  List<String> tags;   // Technology tags
}
```

#### Certification
```dart
class Certification {
  String id;      // Unique identifier
  String title;   // Certification name
  String issuer;  // Issuing organization
  String date;    // Issue date
  String certId;  // Certificate ID
}
```

---

## 🖼️ UI Screens

### `lib/screens/auth_screen.dart`

**Purpose**: Handles user authentication (login/registration).

**Key Features**:
- Login form with email/password validation
- Registration form with all user fields
- Avatar initial generation
- Form validation and error handling
- Integration with AppStore for authentication

### `lib/screens/home_screen.dart`

**Purpose**: Main dashboard with tabbed navigation.

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
