# Selecta COE App Structure & Functions Guide

## 📱 Create Account Section Location

### Primary Files:
- **`lib/screens/auth_screen.dart`** - Main registration UI
- **`lib/data/app_store.dart`** - Account creation logic
- **`lib/data/database_helper.dart`** - Database operations

---

## 🗂️ Complete File Structure & Functions

### **1. Authentication (`lib/screens/auth_screen.dart`)**
**Purpose**: User registration and login interface

#### Key Classes:
- **`AuthScreen`** - Main auth screen with tabs (Login/Register)
- **`_LoginForm`** - Login form component
- **`_RegisterForm`** - Registration form component

#### Key Functions:
```dart
// Registration form submission
Future<void> _register() async {
  // Creates UserAccount object
  // Calls AppStore().createAccount(account)
  // Shows success/error messages
}

// Login form submission  
Future<void> _login() async {
  // Calls AppStore().login(email, password)
  // Navigates to home screen on success
}
```

#### Registration Flow:
1. User fills form (name, email, password, etc.)
2. `_register()` creates `UserAccount` object
3. Calls `AppStore().createAccount(account)`
4. Success → Switch to login tab with success message
5. Error → Show "email already exists" message

---

### **2. Data Management (`lib/data/app_store.dart`)**
**Purpose**: Central state management and business logic

#### Key Functions:
```dart
// CREATE ACCOUNT
Future<bool> createAccount(UserAccount account) async {
  // 1. Check if email already exists
  // 2. Save to SQLite database
  // 3. Refresh accounts list
  // 4. Export account data to text file
}

// LOGIN
Future<bool> login(String email, String password) async {
  // 1. Find user by email and password
  // 2. Set as current user
  // 3. Save to SharedPreferences
}

// PROFILE LIKES
Future<bool> toggleProfileLike(String targetUserId) async {
  // Add/remove like from profile
}

// PROFILE VIEWS
Future<void> recordProfileView(String viewedUserId) async {
  // Increment view count
}

// PRIVACY SETTINGS
Future<void> toggleProfilePrivacy(String profileType) async {
  // Toggle skills/projects/certifications privacy
}
```

#### Data Flow:
- **Registration**: `auth_screen.dart` → `app_store.dart` → `database_helper.dart`
- **Login**: `auth_screen.dart` → `app_store.dart` (checks memory)
- **Profile Updates**: `profile_screen.dart` → `app_store.dart` → `database_helper.dart`

---

### **3. Database Operations (`lib/data/database_helper.dart`)**
**Purpose**: SQLite database management

#### Key Tables:
```sql
users - User accounts and profiles
├── id, name, email, password
├── skillsPrivate, projectsPrivate, certificationsPrivate
├── profileViews, profileLikes, likedBy
└── All profile data (bio, course, etc.)

skill_categories - Skill categories per user
skills - Individual skills
projects - User projects  
certifications - User certifications
```

#### Key Functions:
```dart
// USER OPERATIONS
Future<int> insertUser(UserAccount user) // Create new user
Future<UserAccount?> getUserById(String id) // Get user by ID
Future<List<UserAccount>> getAllUsers() // Get all users
Future<void> updateUser(UserAccount user) // Update user data

// DATABASE SETUP
Future<void> _onCreate(Database db, int version) // Create tables
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) // Migrations
```

---

### **4. Profile Display (`lib/screens/profile_screen.dart`)**
**Purpose**: User profile viewing and editing

#### Key Components:
- **Profile Header**: Avatar, name, basic info
- **Privacy Settings**: Public/private toggles
- **Content Sections**: Skills, projects, certifications
- **Like Button**: Profile interaction
- **View Counter**: Profile statistics

#### Key Functions:
```dart
// Initialize profile data
Future<void> _initControllers() async {
  // Load user data
  // Record profile view
  // Load like status
}

// Privacy toggle
Widget _buildPrivacyToggle(String title, bool isPrivate, String type)

// Content sections
Widget _buildSkillsSection(UserAccount user)
Widget _buildProjectsSection(UserAccount user)  
Widget _buildCertificationsSection(UserAccount user)
```

---

### **5. Data Models (`lib/models/models.dart`)**
**Purpose**: Data structure definitions

#### Key Classes:
```dart
class UserAccount {
  String id, name, email, password;
  String userType, course, yearLevel;
  bool skillsPrivate, projectsPrivate, certificationsPrivate;
  int profileViews, profileLikes;
  List<String> likedBy, approvedViewers;
  List<SkillCategory> skillCategories;
  List<Project> projects;
  List<Certification> certifications;
}

class SkillCategory {
  String id, name;
  List<Skill> skills;
}

class Skill {
  String id, name, level;
  double proficiencyPercent;
}

class Project {
  String id, title, description, date;
  List<String> tags;
}

class Certification {
  String id, title, issuer, date;
}
```

---

### **6. Navigation (`lib/main.dart`)**
**Purpose**: App routing and navigation

#### Key Routes:
```dart
'/' → AuthScreen (login/register)
'/home' → HomeScreen (main app)
'/profile' → ProfileScreen (user profiles)
'/database' → DatabaseScreen (data management)
'/search' → SearchScreen (find users)
```

---

### **7. Home Screen (`lib/screens/home_screen.dart`)**
**Purpose**: Main app interface with dashboard

#### Key Components:
- **Dashboard Tab**: Profile stats, top competencies
- **Database Tab**: Skills, projects, certifications management
- **Search Tab**: Find and view other users
- **Profile Tab**: Current user's profile

#### Key Functions:
```dart
class _DashboardTab {
  // Shows user statistics
  // Displays top skills
  // Shows profile likes counter
}

class _DatabaseTab {
  // Skills management
  // Projects management  
  // Certifications management
}
```

---

### **8. Theme (`lib/theme.dart`)**
**Purpose**: App styling and colors

#### Key Colors:
```dart
static const Color primary = Color(0xFF4F46E5);      // Indigo
static const Color success = Color(0xFF10B981);      // Green
static const Color warning = Color(0xFFF59E0B);      // Amber
static const Color danger = Color(0xFFEF4444);       // Red
static const Color textPrimary = Color(0xFF1F2937);   // Dark gray
static const Color textSecondary = Color(0xFF6B7280); // Medium gray
static const Color textMuted = Color(0xFF9CA3AF);     // Light gray
```

---

## 🔍 Create Account Flow - Step by Step

### 1. User Interface (`auth_screen.dart`)
```dart
_RegisterForm → _register() → AppStore().createAccount()
```

### 2. Account Creation (`app_store.dart`)
```dart
createAccount() → 
  checkEmailExists() → 
  dbHelper.insertUser() → 
  _loadAccountsFromDatabase() → 
  exportAccountData()
```

### 3. Database Save (`database_helper.dart`)
```dart
insertUser() → 
  _userToMap() → 
  db.insert('users', userMap) → 
  _saveRelatedData()
```

### 4. Success Flow
- Account saved to database ✅
- Accounts list refreshed ✅  
- User redirected to login ✅
- Can now log in with credentials ✅

---

## 🐛 Common Issues & Debugging

### **Registration Issues:**
1. **"Email already exists"** → Check database for duplicates
2. **Account not saving** → Check database insertion
3. **Can't login after registration** → Check accounts list sync

### **Database Issues:**
1. **Migration failed** → Check database version
2. **Missing columns** → Run app with new version
3. **Data not persisting** → Check SharedPreferences

### **Profile Issues:**
1. **Likes not working** → Check likedBy list
2. **Views not counting** → Check recordProfileView()
3. **Privacy not working** → Check privacy flags

---

## 🛠️ How to Debug Issues

### **1. Check Database:**
- Use Android Studio Database Inspector
- Look in `data/data/com.example.selecta_coee/databases/selecta_coe.db`
- Check users table for your account

### **2. Check Console Logs:**
- Look for "Error creating account:" messages
- Check database migration logs
- Watch for null pointer exceptions

### **3. Test Step by Step:**
1. Clear app data
2. Create new account
3. Check database immediately
4. Try login right away
5. Test all features

---

## 📝 Quick Reference

| File | Purpose | Key Functions |
|------|---------|---------------|
| `auth_screen.dart` | Registration/Login UI | `_register()`, `_login()` |
| `app_store.dart` | Business Logic | `createAccount()`, `login()` |
| `database_helper.dart` | Database Ops | `insertUser()`, `getUserById()` |
| `profile_screen.dart` | Profile Display | `_initControllers()`, privacy toggles |
| `models.dart` | Data Models | `UserAccount`, `Skill`, `Project` |
| `home_screen.dart` | Main Interface | Dashboard, database, search tabs |
| `main.dart` | Navigation | Route definitions |

This guide should help you understand exactly where everything is and how it works together!
