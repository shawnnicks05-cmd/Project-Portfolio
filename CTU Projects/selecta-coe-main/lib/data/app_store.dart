// lib/data/app_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'database_helper.dart';
import 'firebase_database_service.dart';
import '../utils/database_exporter.dart';

class AppStore extends ChangeNotifier {
  static final AppStore _instance = AppStore._internal();
  factory AppStore() => _instance;
  AppStore._internal();

  final List<UserAccount> _accounts = [];
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
      // Update user in Firebase database
      try {
        final firebaseService = FirebaseDatabaseService();
        await firebaseService.updateUser(_currentUser!);
      } catch (e) {
        print('Error saving to Firebase: $e');
        // Continue without Firebase - data is saved locally in SharedPreferences
      }
    }
  }

  Future<bool> login(String email, String password) async {
    print('Login attempt: email="$email", password="$password"');
    print('Available accounts count: ${_accounts.length}');

    for (var account in _accounts) {
      print('Available account: id="${account.id}", email="${account.email}"');
    }

    // Check in local accounts list (includes SharedPreferences demo + SQLite users)
    final match = _accounts
        .where((a) =>
            a.email.toLowerCase() == email.toLowerCase().trim() &&
            a.password == password.trim())
        .toList();

    print('Found matches: ${match.length}');
    if (match.isNotEmpty) {
      print('Login successful for user: ${match.first.id}');
      _currentUser = match.first;
      await _save();
      notifyListeners();
      return true;
    }

    print('Login failed - no matching account found');
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    notifyListeners();
  }

  Future<bool> createAccount(UserAccount account) async {
    print('Creating account: email="${account.email}", id="${account.id}"');

    // Check if user already exists in local accounts
    final existingUser = _accounts
        .where((a) => a.email.toLowerCase() == account.email.toLowerCase())
        .firstOrNull;
    if (existingUser != null) {
      print('Account already exists: ${existingUser.email}');
      return false;
    }

    // Save to Firebase database
    try {
      final firebaseService = FirebaseDatabaseService();
      await firebaseService.insertUser(account);
      print('Account saved to Firebase database');

      // Refresh accounts list from database to ensure synchronization
      await _loadAccountsFromDatabase();
      print('Accounts list refreshed. New count: ${_accounts.length}');

      // Export account information to text file
      await DatabaseExporter.exportUserAccount(account);

      notifyListeners();
      print('Account creation successful');
      return true;
    } catch (e) {
      print('Error creating account: $e');
      // For demo purposes, add account locally even if Firebase fails
      _accounts.add(account);
      notifyListeners();
      print('Account added locally for demo purposes');
      return true;
    }
  }

  Future<void> _loadAccountsFromDatabase() async {
    try {
      final firebaseService = FirebaseDatabaseService();
      final dbUsers = await firebaseService.getAllUsers();

      // Keep demo account and add database users
      _accounts.clear();
      _accounts.addAll(dbUsers);

      // Add demo account if not already present
      if (!_accounts.any((a) => a.id == 'maria_sofia_santos')) {
        _accounts.add(_demoAccount());
      }

      print('Loaded ${dbUsers.length} users from Firebase database');
    } catch (e) {
      print('Error loading Firebase database users: $e');
      // Ensure demo account is available even if Firebase fails
      if (_accounts.isEmpty) {
        _accounts.add(_demoAccount());
      }
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
    final firebaseService = FirebaseDatabaseService();
    return await firebaseService.getUserById(id);
  }

  Future<bool> canViewSkills(String viewerId, String targetUserId) async {
    // Can view if it's their own profile
    if (viewerId == targetUserId) return true;

    final firebaseService = FirebaseDatabaseService();
    final targetUser = await firebaseService.getUserById(targetUserId);

    if (targetUser == null || !targetUser.skillsPrivate) return true;

    return false; // Private profile - cannot view
  }

  Future<bool> canViewProjects(String viewerId, String targetUserId) async {
    // Can view if it's their own profile
    if (viewerId == targetUserId) return true;

    final firebaseService = FirebaseDatabaseService();
    final targetUser = await firebaseService.getUserById(targetUserId);

    if (targetUser == null || !targetUser.projectsPrivate) return true;

    return false; // Private profile - cannot view
  }

  Future<bool> canViewCertifications(
      String viewerId, String targetUserId) async {
    // Can view if it's their own profile
    if (viewerId == targetUserId) return true;

    final firebaseService = FirebaseDatabaseService();
    final targetUser = await firebaseService.getUserById(targetUserId);

    if (targetUser == null || !targetUser.certificationsPrivate) return true;

    return false; // Private profile - cannot view
  }

  Future<void> toggleProfilePrivacy(String section) async {
    if (_currentUser == null) return;

    switch (section) {
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
      case 'experiences':
        _currentUser!.experiencesPrivate = !_currentUser!.experiencesPrivate;
        break;
      case 'achievements':
        _currentUser!.achievementsPrivate = !_currentUser!.achievementsPrivate;
        break;
      case 'careerObjective':
        _currentUser!.careerObjectivePrivate =
            !_currentUser!.careerObjectivePrivate;
        break;
      case 'all':
        final newValue = !(_currentUser!.skillsPrivate &&
            _currentUser!.projectsPrivate &&
            _currentUser!.certificationsPrivate &&
            _currentUser!.experiencesPrivate &&
            _currentUser!.achievementsPrivate &&
            _currentUser!.careerObjectivePrivate);
        _currentUser!.skillsPrivate = newValue;
        _currentUser!.projectsPrivate = newValue;
        _currentUser!.certificationsPrivate = newValue;
        _currentUser!.experiencesPrivate = newValue;
        _currentUser!.achievementsPrivate = newValue;
        _currentUser!.careerObjectivePrivate = newValue;
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
    if (_currentUser == null) return false;

    // For demo/testing purposes, allow liking own profile
    // In production, you might want to uncomment the line below:
    // if (targetUserId == _currentUser!.id) return false;

    final targetUser = await getUserById(targetUserId);
    if (targetUser == null) return false;

    final isLiked = targetUser.likedBy.contains(_currentUser!.id);
    print(
        'DEBUG: User ${_currentUser!.id} liking $targetUserId, currently liked: $isLiked');

    if (isLiked) {
      // Unlike
      targetUser.likedBy.remove(_currentUser!.id);
      targetUser.profileLikes--;
      print('DEBUG: Unliked - new count: ${targetUser.profileLikes}');
    } else {
      // Like
      targetUser.likedBy.add(_currentUser!.id);
      targetUser.profileLikes++;
      print('DEBUG: Liked - new count: ${targetUser.profileLikes}');
    }

    await updateCurrentUser(targetUser);
    notifyListeners();
    return !isLiked; // Return new like status
  }

  Future<bool> isProfileLiked(String targetUserId) async {
    if (_currentUser == null) {
      print('DEBUG: No current user, returning false');
      return false;
    }
    final targetUser = await getUserById(targetUserId);
    if (targetUser == null) {
      print('DEBUG: Target user not found: $targetUserId');
      return false;
    }
    final isLiked = targetUser.likedBy.contains(_currentUser!.id);
    print(
        'DEBUG: User ${_currentUser!.id} checking if liked $targetUserId: $isLiked');
    print('DEBUG: Target user likedBy list: ${targetUser.likedBy}');
    return isLiked;
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

  // Educational Attainment methods
  Future<void> addEducationalAttainment(EducationalAttainment education) async {
    if (_currentUser == null) return;

    _currentUser!.educationalAttainments.add(education);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> updateEducationalAttainment(
      EducationalAttainment education) async {
    if (_currentUser == null) return;

    final index = _currentUser!.educationalAttainments
        .indexWhere((e) => e.id == education.id);
    if (index != -1) {
      _currentUser!.educationalAttainments[index] = education;
      await updateCurrentUser(_currentUser!);
    }
  }

  Future<void> removeEducationalAttainment(String educationId) async {
    if (_currentUser == null) return;

    _currentUser!.educationalAttainments
        .removeWhere((e) => e.id == educationId);
    await updateCurrentUser(_currentUser!);
  }

  // Experience methods
  Future<void> addExperience(Experience experience) async {
    if (_currentUser == null) return;
    _currentUser!.experiences.add(experience);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> updateExperience(Experience experience) async {
    if (_currentUser == null) return;
    final index =
        _currentUser!.experiences.indexWhere((e) => e.id == experience.id);
    if (index != -1) {
      _currentUser!.experiences[index] = experience;
      await updateCurrentUser(_currentUser!);
    }
  }

  Future<void> removeExperience(String experienceId) async {
    if (_currentUser == null) return;
    _currentUser!.experiences.removeWhere((e) => e.id == experienceId);
    await updateCurrentUser(_currentUser!);
  }

  // Achievement methods
  Future<void> addAchievement(Achievement achievement) async {
    if (_currentUser == null) return;
    _currentUser!.achievements.add(achievement);
    await updateCurrentUser(_currentUser!);
  }

  Future<void> updateAchievement(Achievement achievement) async {
    if (_currentUser == null) return;
    final index =
        _currentUser!.achievements.indexWhere((a) => a.id == achievement.id);
    if (index != -1) {
      _currentUser!.achievements[index] = achievement;
      await updateCurrentUser(_currentUser!);
    }
  }

  Future<void> removeAchievement(String achievementId) async {
    if (_currentUser == null) return;
    _currentUser!.achievements.removeWhere((a) => a.id == achievementId);
    await updateCurrentUser(_currentUser!);
  }

  // Career Objective method
  Future<void> updateCareerObjective(String careerObjective) async {
    if (_currentUser == null) return;
    _currentUser!.careerObjective = careerObjective;
    await updateCurrentUser(_currentUser!);
  }

  // All records flattened for search/select
  Future<List<Map<String, dynamic>>> getAllRecords() async {
    // Note: Firebase doesn't have searchRecords method like SQLite
    // This would need to be implemented differently for Firebase
    // For now, return empty list as this is used for search functionality
    return [];
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      return await FirebaseDatabaseService().searchRecords(query);
    } catch (e) {
      print('Firebase search failed, falling back to local database: $e');
      // Fallback to local database if Firebase fails
      return await DatabaseHelper().searchRecords(query);
    }
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
      id: 'maria_sofia_santos',
      name: 'Maria Sofia Santos',
      email: 'maria.santos@ctu.edu.ph',
      phone: '+63 912 345 6789',
      password: 'password123',
      userType: 'Student',
      course: 'BS Industrial Engineering',
      yearLevel: '4th Year',
      studentId: '2023-IE-0001',
      address: 'Cebu City, Philippines',
      department: 'Bachelor of Science in Industrial Engineering',
      avatarInitials: 'MS',
      avatarUrl: '',
      bio:
          'I am a 4th year Industrial Engineering student at Cebu Technological University. I love AutoCAD, simulation tools, and building project portfolios.',
      skillsPrivate: true, // Demo account has private skills
      projectsPrivate: true, // Demo account has private projects
      certificationsPrivate: true, // Demo account has private certifications
      experiencesPrivate: false, // Demo account has public experiences
      achievementsPrivate: false, // Demo account has public achievements
      careerObjectivePrivate: false, // Demo account has public career objective
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
      educationalAttainments: [
        EducationalAttainment(
          id: 'edu-1',
          schoolName: 'Cebu Technological University',
          degree: 'Bachelor of Science in Industrial Engineering',
          year: '2023',
          address: 'Cebu City, Philippines',
        ),
      ],
      experiences: [
        Experience(
          id: 'exp-1',
          company: 'Tech Solutions Inc.',
          position: 'Industrial Engineering Intern',
          startDate: '2022-06',
          endDate: '2022-12',
          description:
              'Optimized production processes and reduced waste by 15%',
          title: '',
          dateRange: '',
        ),
        Experience(
          id: 'exp-2',
          company: 'Manufacturing Corp',
          position: 'Process Engineer',
          startDate: '2023-01',
          endDate: '2023-06',
          description:
              'Implemented lean manufacturing principles and improved efficiency',
          title: '',
          dateRange: '',
        ),
      ],
      achievements: [
        Achievement(
          id: 'ach-1',
          title: 'Dean\'s List',
          description: 'Academic excellence for 3 consecutive semesters',
          date: '2022-12',
          category: 'Academic',
        ),
        Achievement(
          id: 'ach-2',
          title: 'Best Project Award',
          description: 'IoT Traffic Monitoring System',
          date: '2023-05',
          category: 'Project',
        ),
      ],
      careerObjective:
          'To become a skilled Industrial Engineer specializing in process optimization and sustainable manufacturing practices, contributing to innovative solutions that improve efficiency and environmental impact.',
    );
  }
}
