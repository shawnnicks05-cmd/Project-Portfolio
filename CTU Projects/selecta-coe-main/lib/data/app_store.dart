// lib/data/app_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
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
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final users = await db.query('users');
      final dbUsers = users.map((json) => UserAccount.fromJson(json)).toList();
      _accounts.addAll(dbUsers);
    } catch (e) {
      print('Error loading database users: $e');
      // Continue with demo account only
    }

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

    // Load notifications from SharedPreferences
    final notificationsJson = prefs.getString('notifications') ?? '[]';
    final notificationsList = jsonDecode(notificationsJson) as List;
    _notifications =
        notificationsList.map((n) => NotificationModel.fromJson(n)).toList();
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
      _accounts.add(account);

      // Export account information to text file
      await DatabaseExporter.exportUserAccount(account);

      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating account: $e');
      return false;
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

  // Permission methods
  Future<bool> requestPermission(String targetUserId, String message) async {
    final dbHelper = DatabaseHelper();
    final currentUser = AppStore().currentUser;

    if (currentUser == null) return false;

    // Check if request already exists
    final existingRequests =
        await dbHelper.getMyPermissionRequests(currentUser.id);
    final hasExistingRequest = existingRequests.any(
        (req) => req.targetUserId == targetUserId && req.status == 'pending');

    if (hasExistingRequest) return false;

    final request = PermissionRequest(
      id: const Uuid().v4(),
      requesterId: currentUser.id,
      targetUserId: targetUserId,
      requestDate: DateTime.now(),
      status: 'pending',
      message: message,
    );

    await dbHelper.insertPermissionRequest(request);

    // Add notification for target user
    await _addNotification(
      targetUserId,
      'New Permission Request',
      '${_getUserName(currentUser.id)} wants to view your profile. Message: $message',
      'request',
    );

    notifyListeners();
    return true;
  }

  Future<List<PermissionRequest>> getPermissionRequests() async {
    final dbHelper = DatabaseHelper();
    final currentUser = AppStore().currentUser;

    if (currentUser == null) return [];

    return await dbHelper.getPermissionRequestsForUser(currentUser.id);
  }

  Future<List<PermissionRequest>> getMyPermissionRequests() async {
    final dbHelper = DatabaseHelper();
    final currentUser = AppStore().currentUser;

    if (currentUser == null) return [];

    return await dbHelper.getMyPermissionRequests(currentUser.id);
  }

  Future<void> approvePermissionRequest(String requestId) async {
    final dbHelper = DatabaseHelper();
    final request = await dbHelper
        .getPermissionRequestsForUser(AppStore().currentUser!.id)
        .then((requests) => requests.firstWhere((req) => req.id == requestId));

    // Update request status
    await dbHelper.updatePermissionRequestStatus(requestId, 'approved');

    // Add to approved viewers
    await dbHelper.addApprovedViewer(request.targetUserId, request.requesterId);

    // Add notification for the requester
    await _addNotification(
      request.requesterId,
      'Permission Request Approved',
      'Your permission request to view ${_getUserName(request.targetUserId)}\'s profile has been approved!',
      'approval',
    );

    notifyListeners();
  }

  Future<void> denyPermissionRequest(String requestId) async {
    final dbHelper = DatabaseHelper();
    final request = await dbHelper
        .getPermissionRequestsForUser(AppStore().currentUser!.id)
        .then((requests) => requests.firstWhere((req) => req.id == requestId));

    // Update request status
    await dbHelper.updatePermissionRequestStatus(requestId, 'denied');

    // Add notification for requester
    await _addNotification(
      request.requesterId,
      'Permission Request Denied',
      'Your permission request to view ${_getUserName(request.targetUserId)}\'s profile has been denied.',
      'denial',
    );

    notifyListeners();
  }

  Future<bool> canViewSkills(String viewerId, String targetUserId) async {
    // Can view if it's their own profile or if they have permission
    if (viewerId == targetUserId) return true;

    final dbHelper = DatabaseHelper();
    final targetUser = await dbHelper.getUserById(targetUserId);

    if (targetUser == null || !targetUser.skillsPrivate) return true;

    return await dbHelper.hasPermission(viewerId, targetUserId);
  }

  Future<bool> canViewProjects(String viewerId, String targetUserId) async {
    if (viewerId == targetUserId) return true;

    final dbHelper = DatabaseHelper();
    final targetUser = await dbHelper.getUserById(targetUserId);

    if (targetUser == null || !targetUser.projectsPrivate) return true;

    return await dbHelper.hasPermission(viewerId, targetUserId);
  }

  Future<bool> canViewCertifications(
      String viewerId, String targetUserId) async {
    if (viewerId == targetUserId) return true;

    final dbHelper = DatabaseHelper();
    final targetUser = await dbHelper.getUserById(targetUserId);

    if (targetUser == null || !targetUser.certificationsPrivate) return true;

    return await dbHelper.hasPermission(viewerId, targetUserId);
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

  // Notification system methods
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  String _getUserName(String userId) {
    final user = _accounts.where((a) => a.id == userId).firstOrNull;
    return user?.name ?? 'Unknown User';
  }

  Future<void> _addNotification(
      String userId, String title, String message, String type) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _notifications.insert(0, notification); // Add to beginning of list

    // Save to SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString('notifications') ?? '[]';
    final notificationsList = jsonDecode(notificationsJson) as List;
    notificationsList.insert(0, notification.toJson());
    await prefs.setString('notifications', jsonEncode(notificationsList));

    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;

      // Update in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString('notifications', notificationsJson);

      notifyListeners();
    }
  }

  Future<void> clearNotifications() async {
    _notifications.clear();

    // Clear from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');

    notifyListeners();
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
