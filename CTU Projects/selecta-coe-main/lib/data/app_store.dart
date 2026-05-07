// lib/data/app_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database_helper.dart';
import '../utils/database_exporter.dart';

class AppStore extends ChangeNotifier {
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

  List<UserAccount> _accounts = [];
  UserAccount? _currentUser;

  List<UserAccount> get accounts => List.unmodifiable(_accounts);
  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load demo account from SharedPreferences
    final demoJson = prefs.getString('demoAccount');
    if (demoJson != null) {
      final demoUser = UserAccount.fromJson(jsonDecode(demoJson));
      _accounts.add(demoUser);
    } else {
      // Create and save demo account to SharedPreferences
      final demoUser = _demoAccount();
      await prefs.setString('demoAccount', jsonEncode(demoUser.toJson()));
      _accounts.add(demoUser);
    }

    // Load users from SQLite database
    await _loadAccountsFromDatabase();

    // Get current user from SharedPreferences
    final uid = prefs.getString('currentUserId');
    if (uid != null) {
      _currentUser = _accounts.where((a) => a.id == uid).firstOrNull;
    }

    // If no current user, default to demo account
    if (_currentUser == null && _accounts.isNotEmpty) {
      _currentUser = _accounts.first;
      await prefs.setString('currentUserId', _currentUser!.id);
    }

    // Load recently viewed profiles
    await loadRecentlyViewedProfiles();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString('currentUserId', _currentUser!.id);
      // Update user in database
      final dbHelper = DatabaseHelper();
      await dbHelper.updateUser(_currentUser!);
    }
  }

  Future<bool> login(String email, String password) async {
    // Check in local accounts list (includes SharedPreferences demo + SQLite users)
    final match = _accounts
        .where((a) =>
            a.email.toLowerCase() == email.toLowerCase() &&
            a.password == password)
        .toList();

    if (match.isNotEmpty) {
      _currentUser = match.first;
      await _save();
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    notifyListeners();
  }

  Future<bool> createAccount(UserAccount account) async {
    // Check if user already exists in local accounts
    final existingUser = _accounts
        .where((a) => a.email.toLowerCase() == account.email.toLowerCase())
        .firstOrNull;
    if (existingUser != null) return false;

    // Save to SQLite database
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.insertUser(account);
      
      // Refresh accounts list from database to ensure synchronization
      await _loadAccountsFromDatabase();
      
      // Export account information to text file
      await DatabaseExporter.exportUserAccount(account);

      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating account: $e');
      return false;
    }
  }

  Future<void> _loadAccountsFromDatabase() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final users = await db.query('users');
      final dbUsers = users.map((json) => UserAccount.fromJson(json)).toList();
      
      // Keep demo account and add database users
      _accounts.clear();
      _accounts.addAll(dbUsers);
      
      // Add demo account if not already present
      if (!_accounts.any((a) => a.id == 'demo-001')) {
        _accounts.add(_demoAccount());
      }
    } catch (e) {
      print('Error loading database users: $e');
    }
  }

  Future<void> updateCurrentUser(UserAccount updated) async {
    final idx = _accounts.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _accounts[idx] = updated;
      _currentUser = updated;
      await _save();
      notifyListeners();
    }
  }

  Future<UserAccount?> getUserById(String id) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.getUserById(id);
  }

  Future<bool> canViewSkills(String viewerId, String targetUserId) async {
    // Can view if it's their own profile
    if (viewerId == targetUserId) return true;

    final dbHelper = DatabaseHelper();
    final targetUser = await dbHelper.getUserById(targetUserId);

    if (targetUser == null || !targetUser.skillsPrivate) return true;

    return false; // Private profile - cannot view
  }

  Future<bool> canViewProjects(String viewerId, String targetUserId) async {
    // Can view if it's their own profile
    if (viewerId == targetUserId) return true;

    final dbHelper = DatabaseHelper();
    final targetUser = await dbHelper.getUserById(targetUserId);

    if (targetUser == null || !targetUser.projectsPrivate) return true;

    return false; // Private profile - cannot view
  }

  Future<bool> canViewCertifications(
      String viewerId, String targetUserId) async {
    // Can view if it's their own profile
    if (viewerId == targetUserId) return true;

    final dbHelper = DatabaseHelper();
    final targetUser = await dbHelper.getUserById(targetUserId);

    if (targetUser == null || !targetUser.certificationsPrivate) return true;

    return false; // Private profile - cannot view
  }

  Future<void> toggleProfilePrivacy(String profileType) async {
    if (_currentUser == null) return;

    switch (profileType.toLowerCase()) {
      case 'skills':
        _currentUser!.skillsPrivate = !_currentUser!.skillsPrivate;
        break;
      case 'projects':
        _currentUser!.projectsPrivate = !_currentUser!.projectsPrivate;
        break;
      case 'certifications':
        _currentUser!.certificationsPrivate =
            !_currentUser!.certificationsPrivate;
        break;
      case 'all':
        final isCurrentlyPrivate = _currentUser!.skillsPrivate &&
            _currentUser!.projectsPrivate &&
            _currentUser!.certificationsPrivate;
        _currentUser!.skillsPrivate = !isCurrentlyPrivate;
        _currentUser!.projectsPrivate = !isCurrentlyPrivate;
        _currentUser!.certificationsPrivate = !isCurrentlyPrivate;
        break;
    }

    await updateCurrentUser(_currentUser!);
  }

  // Profile viewing and recently viewed functionality
  List<String> _recentlyViewedProfiles = [];
  List<String> get recentlyViewedProfiles =>
      List.unmodifiable(_recentlyViewedProfiles);

  Future<void> recordProfileView(String viewedUserId) async {
    if (_currentUser == null || viewedUserId == _currentUser!.id) return;

    // Increment view count for the viewed user
    final viewedUser = await getUserById(viewedUserId);
    if (viewedUser != null) {
      viewedUser.profileViews++;
      await updateCurrentUser(viewedUser);
    }

    // Remove if already exists, then add to beginning
    _recentlyViewedProfiles.remove(viewedUserId);
    _recentlyViewedProfiles.insert(0, viewedUserId);

    // Keep only last 10 viewed profiles
    if (_recentlyViewedProfiles.length > 10) {
      _recentlyViewedProfiles = _recentlyViewedProfiles.take(10).toList();
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'recentlyViewedProfiles', _recentlyViewedProfiles);

    notifyListeners();
  }

  Future<bool> toggleProfileLike(String targetUserId) async {
    if (_currentUser == null || targetUserId == _currentUser!.id) return false;

    final targetUser = await getUserById(targetUserId);
    if (targetUser == null) return false;

    final isLiked = targetUser.likedBy.contains(_currentUser!.id);

    if (isLiked) {
      // Unlike
      targetUser.likedBy.remove(_currentUser!.id);
      targetUser.profileLikes--;
    } else {
      // Like
      targetUser.likedBy.add(_currentUser!.id);
      targetUser.profileLikes++;
    }

    await updateCurrentUser(targetUser);
    notifyListeners();
    return !isLiked; // Return new like status
  }

  Future<bool> isProfileLiked(String targetUserId) async {
    if (_currentUser == null) return false;
    final targetUser = await getUserById(targetUserId);
    return targetUser?.likedBy.contains(_currentUser!.id) ?? false;
  }

  Future<void> loadRecentlyViewedProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    _recentlyViewedProfiles =
        prefs.getStringList('recentlyViewedProfiles') ?? [];
    notifyListeners();
  }

  Future<List<UserAccount>> getRecentlyViewedUsers() async {
    final List<UserAccount> users = [];
    for (final userId in _recentlyViewedProfiles) {
      final user = await getUserById(userId);
      if (user != null) {
        users.add(user);
      }
    }
    return users;
  }

  Future<void> clearRecentlyViewedProfiles() async {
    _recentlyViewedProfiles.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recentlyViewedProfiles');
    notifyListeners();
  }

  Future<bool> addSkillToCurrentUserFromRecord(
      {required String category, required Skill skill}) async {
    if (_currentUser == null) return false;
    final user = _currentUser!;
    final existingCategory = user.skillCategories.firstWhere(
        (c) => c.name.toLowerCase() == category.toLowerCase(),
        orElse: () => SkillCategory(id: '', name: ''));

    if (existingCategory.id.isEmpty) {
      user.skillCategories.add(SkillCategory(
        id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
        name: category,
        skills: [skill],
      ));
    } else {
      final existingSkill = existingCategory.skills
          .any((s) => s.name.toLowerCase() == skill.name.toLowerCase());
      if (existingSkill) return false;
      existingCategory.skills.add(skill);
    }

    await updateCurrentUser(user);
    return true;
  }

  Future<void> addSkillCategory(SkillCategory cat) async {
    if (_currentUser == null) return;
    _currentUser!.skillCategories.add(cat);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> addSkillToCategory(String catId, Skill skill) async {
    if (_currentUser == null) return;
    final cat = _currentUser!.skillCategories
        .firstWhere((c) => c.id == catId, orElse: () => throw Exception());
    cat.skills.add(skill);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> removeSkill(String catId, String skillId) async {
    if (_currentUser == null) return;
    final cat = _currentUser!.skillCategories.firstWhere((c) => c.id == catId);
    cat.skills.removeWhere((s) => s.id == skillId);
    if (cat.skills.isEmpty) {
      _currentUser!.skillCategories.removeWhere((c) => c.id == catId);
    }
    await updateCurrentUser(_currentUser!);
  }

  Future<void> addProject(Project project) async {
    if (_currentUser == null) return;
    _currentUser!.projects.add(project);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> removeProject(String projectId) async {
    if (_currentUser == null) return;
    _currentUser!.projects.removeWhere((p) => p.id == projectId);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> addCertification(Certification cert) async {
    if (_currentUser == null) return;
    _currentUser!.certifications.add(cert);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> removeCertification(String certId) async {
    if (_currentUser == null) return;
    _currentUser!.certifications.removeWhere((c) => c.id == certId);
    await updateCurrentUser(_currentUser!);
  }

  // All records flattened for search/select
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.searchRecords('');
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final dbHelper = DatabaseHelper();
    return await dbHelper.searchRecords(query);
  }

  bool canUserViewPrivateContent(String targetUserId, String viewerId) {
    final targetUser = _accounts.where((a) => a.id == targetUserId).firstOrNull;
    if (targetUser == null) return false;

    // User can view their own content
    if (targetUserId == viewerId) return true;

    // Check if profile is public
    if (!targetUser.skillsPrivate &&
        !targetUser.projectsPrivate &&
        !targetUser.certificationsPrivate) {
      return true;
    }

    return false;
  }

  UserAccount _demoAccount() {
    return UserAccount(
      id: 'demo-001',
      name: 'Maria Sofia Santos',
      email: 'maria.santos@ctu.edu.ph',
      phone: '+63 912 345 6789',
      password: 'password123',
      userType: 'Student',
      course: 'BS Industrial Engineering',
      yearLevel: '4th Year',
      studentId: '2023-IE-0001',
      location: 'Cebu City, Philippines',
      avatarInitials: 'MS',
      avatarUrl: '',
      bio:
          'I am a 4th year Industrial Engineering student at Cebu Technological University. I love AutoCAD, simulation tools, and building project portfolios.',
      skillsPrivate: true, // Demo account has private skills
      projectsPrivate: true, // Demo account has private projects
      certificationsPrivate: true, // Demo account has private certifications
      approvedViewers: [], // No approved viewers initially
      skillCategories: [
        SkillCategory(
          id: 'cat-1',
          name: 'Programming Languages',
          skills: [
            Skill(
                id: 's1',
                name: 'Python',
                level: 'Expert',
                proficiencyPercent: 92),
            Skill(
                id: 's2',
                name: 'JavaScript',
                level: 'Advanced',
                proficiencyPercent: 75),
            Skill(
                id: 's3',
                name: 'C++',
                level: 'Advanced',
                proficiencyPercent: 68),
            Skill(
                id: 's4',
                name: 'Java',
                level: 'Advanced',
                proficiencyPercent: 65),
          ],
        ),
        SkillCategory(
          id: 'cat-2',
          name: 'CAD/Simulation Tools',
          skills: [
            Skill(
                id: 's5',
                name: 'AutoCAD',
                level: 'Expert',
                proficiencyPercent: 90),
            Skill(
                id: 's6',
                name: 'SolidWorks',
                level: 'Expert',
                proficiencyPercent: 88),
            Skill(
                id: 's7',
                name: 'Vensim',
                level: 'Advanced',
                proficiencyPercent: 72),
            Skill(
                id: 's8',
                name: 'MATLAB',
                level: 'Advanced',
                proficiencyPercent: 70),
          ],
        ),
      ],
      projects: [
        Project(
          id: 'p1',
          title: 'Smart Traffic Management System',
          description:
              'Developed an IoT-based traffic monitoring and optimization system using sensor networks and machine learning algorithms to reduce congestion in urban areas.',
          date: 'Jan 2026',
          memberCount: 4,
          tags: ['Python', 'TensorFlow', 'Arduino', 'React'],
        ),
        Project(
          id: 'p2',
          title: 'Renewable Energy Optimization Platform',
          description:
              'Created a web platform for analyzing and optimizing solar panel placement using geographic data and weather prediction models.',
          date: 'Oct 2025',
          memberCount: 3,
          tags: ['JavaScript', 'Node.js', 'PostgreSQL', 'D3.js'],
        ),
      ],
      certifications: [
        Certification(
          id: 'c1',
          title: 'AWS Certified Solutions Architect',
          issuer: 'Amazon Web Services',
          date: 'March 2026',
          certId: 'ID: AWS-SA-2026-12345',
        ),
        Certification(
          id: 'c2',
          title: 'Professional Engineer (FE Exam)',
          issuer: 'NCEES',
          date: 'January 2026',
          certId: 'ID: FE-2026-67890',
        ),
        Certification(
          id: 'c3',
          title: 'Certified ScrumMaster (CSM)',
          issuer: 'Scrum Alliance',
          date: 'November 2025',
          certId: 'ID: CSM-2025-54321',
        ),
        Certification(
          id: 'c4',
          title: 'AutoCAD Professional Certification',
          issuer: 'Autodesk',
          date: 'August 2025',
          certId: 'ID: ACAD-2025-99012',
        ),
      ],
    );
  }
}
