// lib/data/app_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

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
    final raw = prefs.getString('accounts');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _accounts = list.map((e) => UserAccount.fromJson(e)).toList();
    }
    final uid = prefs.getString('currentUserId');
    if (uid != null) {
      _currentUser = _accounts.firstWhere(
        (a) => a.id == uid,
        orElse: () => _accounts.isNotEmpty ? _accounts.first : _demoAccount(),
      );
    }
    if (_accounts.isEmpty) {
      _accounts.add(_demoAccount());
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList()));
    if (_currentUser != null) {
      await prefs.setString('currentUserId', _currentUser!.id);
    }
  }

  Future<bool> login(String email, String password) async {
    // Match by email and password
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
    final exists = _accounts
        .any((a) => a.email.toLowerCase() == account.email.toLowerCase());
    if (exists) return false;
    _accounts.add(account);
    _currentUser = account;
    await _save();
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

  UserAccount? getUserById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
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
  List<Map<String, dynamic>> getAllRecords() {
    final results = <Map<String, dynamic>>[];
    for (final user in _accounts) {
      // user profile records
      results.add({
        'type': 'profile',
        'user': user.name,
        'userId': user.id,
        'name': user.name,
        'course': user.course,
        'yearLevel': user.yearLevel,
        'studentId': user.studentId,
        'location': user.location,
        'bio': user.bio,
        'avatarUrl': user.avatarUrl,
        'instagramUrl': user.instagramUrl,
        'facebookUrl': user.facebookUrl,
      });
      // skills
      for (final cat in user.skillCategories) {
        for (final skill in cat.skills) {
          results.add({
            'type': 'skill',
            'user': user.name,
            'userId': user.id,
            'category': cat.name,
            'name': skill.name,
            'level': skill.level,
            'percent': skill.proficiencyPercent,
          });
        }
      }
      // projects
      for (final p in user.projects) {
        results.add({
          'type': 'project',
          'user': user.name,
          'userId': user.id,
          'name': p.title,
          'description': p.description,
          'date': p.date,
          'tags': p.tags,
        });
      }
      // certifications
      for (final c in user.certifications) {
        results.add({
          'type': 'certification',
          'user': user.name,
          'userId': user.id,
          'name': c.title,
          'issuer': c.issuer,
          'date': c.date,
        });
      }
    }
    return results;
  }

  List<Map<String, dynamic>> search(String query) {
    if (query.trim().isEmpty) return getAllRecords();
    final q = query.toLowerCase();
    return getAllRecords().where((r) {
      return (r['name'] as String? ?? '').toLowerCase().contains(q) ||
          (r['user'] as String? ?? '').toLowerCase().contains(q) ||
          (r['course'] as String? ?? '').toLowerCase().contains(q) ||
          (r['yearLevel'] as String? ?? '').toLowerCase().contains(q) ||
          (r['studentId'] as String? ?? '').toLowerCase().contains(q) ||
          (r['location'] as String? ?? '').toLowerCase().contains(q) ||
          (r['bio'] as String? ?? '').toLowerCase().contains(q) ||
          (r['category'] as String? ?? '').toLowerCase().contains(q) ||
          (r['level'] as String? ?? '').toLowerCase().contains(q) ||
          (r['description'] as String? ?? '').toLowerCase().contains(q) ||
          (r['issuer'] as String? ?? '').toLowerCase().contains(q) ||
          (r['tags'] as List? ?? [])
              .any((t) => t.toString().toLowerCase().contains(q));
    }).toList();
  }

  UserAccount _demoAccount() {
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
