// lib/data/app_store.dart
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
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
    try {
      // Load users from database
      final users = await db.query('users');
      _accounts = users.map((json) => UserAccount.fromJson(json)).toList();
      
      // Get current user from SharedPreferences (still use this for session management)
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('currentUserId');
      if (uid != null) {
        final user = _accounts.where((a) => a.id == uid).firstOrNull;
        _currentUser = user ?? (_accounts.isNotEmpty ? _accounts.first : await _createDemoAccount());
      }
      
      // If no users exist, create demo account
      if (_accounts.isEmpty) {
        final demoUser = await _createDemoAccount();
        await db.insert('users', demoUser.toJson());
        _accounts.add(demoUser);
      }
    } catch (e) {
      // Fallback to demo account if database fails
      _accounts.add(await _createDemoAccount());
      _currentUser = _accounts.first;
    }
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
    final dbHelper = DatabaseHelper();
    
    // Try to get user from database first
    final user = await dbHelper.getUserByEmail(email);
    if (user != null && user.password == password) {
      _currentUser = user;
      
      // Update local accounts list
      _accounts = await dbHelper.getAllUsers();
      
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
    final dbHelper = DatabaseHelper();
    
    // Check if user already exists in database
    final existingUser = await dbHelper.getUserByEmail(account.email);
    if (existingUser != null) return false;
    
    // Insert new user into database
    await dbHelper.insertUser(account);
    
    // Update local state but don't auto-login
    _accounts = await dbHelper.getAllUsers();
    
    // Export account information to text file
    await DatabaseExporter.exportUserAccount(account);
    
    notifyListeners();
    return true;
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

  Future<UserAccount> _createDemoAccount() async {
    return UserAccount(
      id: 'demo-001',
      name: 'Maria Sofia Santos',
      email: 'maria.santos@ctu.edu.ph',
      phone: '+63 912 345 6789',
      password: 'password123',
      course: 'BS Industrial Engineering',
      yearLevel: '4th Year',
      studentId: '2023-IE-0001',
      location: 'Cebu City, Philippines',
      avatarInitials: 'MS',
      avatarUrl: '',
      bio:
          'I am a 4th year Industrial Engineering student at Cebu Technological University. I love AutoCAD, simulation tools, and building project portfolios.',
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
