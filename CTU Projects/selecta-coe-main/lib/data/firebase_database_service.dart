// lib/data/firebase_database_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance =
      FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  // Main users collection
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  final CollectionReference _educationalAttainmentsCollection =
      FirebaseFirestore.instance.collection('educational_attainments');
  final CollectionReference _experiencesCollection =
      FirebaseFirestore.instance.collection('experiences');
  final CollectionReference _achievementsCollection =
      FirebaseFirestore.instance.collection('achievements');
  final CollectionReference _profileViewsCollection =
      FirebaseFirestore.instance.collection('profile_views');
  final CollectionReference _profileLikesCollection =
      FirebaseFirestore.instance.collection('profile_likes');

  // Helper method to get user-specific subcollections
  CollectionReference _getUserCollection(String userId, String collectionName) {
    return _usersCollection.doc(userId).collection(collectionName);
  }

  // User operations
  Future<void> insertUser(UserAccount user) async {
    try {
      // Slim parent doc (matches create-account fields only); no nested portfolio maps.
      await _usersCollection.doc(user.id).set(user.toFirestoreRegistrationMap());

      // Portfolio rows only under users/{id}/... subcollections (skipped when lists empty).
      await _saveRelatedData(user);

      print(
          'User account created successfully in Firebase with all collections');
    } catch (e) {
      print('Error inserting user to Firebase: $e');
      throw Exception('Failed to save user to Firebase');
    }
  }

  Future<void> _saveRelatedData(UserAccount user) async {
    // Save skill categories and skills to user-specific subcollection
    for (final category in user.skillCategories) {
      await insertSkillCategory(category, user.id);

      for (final skill in category.skills) {
        await insertSkill(skill, category.id, user.id);
      }
    }

    // Save projects to user-specific subcollection
    for (final project in user.projects) {
      await insertProject(project, user.id);
    }

    // Save certifications to user-specific subcollection
    for (final certification in user.certifications) {
      await insertCertification(certification, user.id);
    }

    // Save educational attainments to user-specific subcollection
    for (final education in user.educationalAttainments) {
      await insertEducationalAttainment(education, user.id);
    }

    // Save experiences to user-specific subcollection
    for (final experience in user.experiences) {
      await insertExperience(experience, user.id);
    }

    // Save achievements to user-specific subcollection
    for (final achievement in user.achievements) {
      await insertAchievement(achievement, user.id);
    }
  }

  Future<List<UserAccount>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await _usersCollection.get();
      print(
          'Firebase getAllUsers: Found ${snapshot.docs.length} users in database');

      List<UserAccount> users = [];
      for (var doc in snapshot.docs) {
        final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);
        print('Loading user: ${user.name} (${user.id})');

        // Load related data from user-specific subcollections
        user.skillCategories = await getSkillCategoriesForUser(user.id);
        user.projects = await getProjectsForUser(user.id);
        user.certifications = await getCertificationsForUser(user.id);
        user.educationalAttainments =
            await getEducationalAttainmentsForUser(user.id);
        user.experiences = await getExperiencesForUser(user.id);
        user.achievements = await getAchievementsForUser(user.id);

        users.add(user);
      }
      print('Firebase getAllUsers: Returning ${users.length} users');
      return users;
    } catch (e) {
      print('Error getting all users from Firebase: $e');
      throw Exception('Firebase database not available');
    }
  }

  Future<UserAccount?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot snapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);

      // Load related data
      user.skillCategories = await getSkillCategoriesForUser(user.id);
      user.projects = await getProjectsForUser(user.id);
      user.certifications = await getCertificationsForUser(user.id);
      user.educationalAttainments =
          await getEducationalAttainmentsForUser(user.id);
      user.experiences = await getExperiencesForUser(user.id);
      user.achievements = await getAchievementsForUser(user.id);

      return user;
    } catch (e) {
      print('Error getting user by email from Firebase: $e');
      return null;
    }
  }

  Future<UserAccount?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;

      final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);

      // Load related data from user-specific subcollections
      user.skillCategories = await getSkillCategoriesForUser(user.id);
      user.projects = await getProjectsForUser(user.id);
      user.certifications = await getCertificationsForUser(user.id);
      user.educationalAttainments =
          await getEducationalAttainmentsForUser(user.id);
      user.experiences = await getExperiencesForUser(user.id);
      user.achievements = await getAchievementsForUser(user.id);

      return user;
    } catch (e) {
      print('Error getting user by ID from Firebase: $e');
      return null;
    }
  }

  Future<void> updateUser(UserAccount user) async {
    try {
      await _usersCollection.doc(user.id).update(user.toJson());

      // Incremental sync: update/add changed docs, delete only removed docs.
      // This avoids full delete/reinsert on every save and improves latency.
      await _syncSkillData(user);
      await _syncProjects(user);
      await _syncCertifications(user);
      await _syncEducationalAttainments(user);
      await _syncExperiences(user);
      await _syncAchievements(user);
    } catch (e) {
      print('Error updating user in Firebase: $e');
      throw Exception('Failed to update user in Firebase');
    }
  }

  Future<void> deleteUser(String id) async {
    // Delete user and all related data
    await _usersCollection.doc(id).delete();

    // Delete related collections
    await _deleteRelatedData(id);
  }

  Future<void> _deleteRelatedData(String userId) async {
    // Related data is stored under per-user subcollections, so delete there.
    // (Firestore has no single-call recursive delete in client SDK.)
    Future<void> deleteAllDocs(String collectionName) async {
      final collection = _getUserCollection(userId, collectionName);
      final snapshot = await collection.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snapshot.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }

    await deleteAllDocs('skills');
    await deleteAllDocs('skill_categories');
    await deleteAllDocs('projects');
    await deleteAllDocs('certifications');
    await deleteAllDocs('educational_attainments');
    await deleteAllDocs('experiences');
    await deleteAllDocs('achievements');
  }

  // Skill Category operations
  Future<List<SkillCategory>> getSkillCategoriesForUser(String userId) async {
    try {
      // Categories are stored per-user under: users/{userId}/skill_categories
      final QuerySnapshot snapshot =
          await _getUserCollection(userId, 'skill_categories').get();

      List<SkillCategory> categories = [];
      for (var doc in snapshot.docs) {
        final category =
            SkillCategory.fromJson(doc.data() as Map<String, dynamic>);
        category.skills = await getSkillsForCategory(userId, category.id);
        categories.add(category);
      }
      return categories;
    } catch (e) {
      print('Error getting skill categories from Firebase: $e');
      return [];
    }
  }

  Future<void> insertSkillCategory(
      SkillCategory category, String userId) async {
    final categoryData = category.toJson();
    categoryData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'skill_categories')
        .doc(category.id)
        .set(categoryData);
    print('Skill category saved to Firebase for user $userId');
  }

  // Skill operations
  Future<List<Skill>> getSkillsForCategory(
      String userId, String categoryId) async {
    try {
      final QuerySnapshot snapshot = await _getUserCollection(userId, 'skills')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      return snapshot.docs
          .map((doc) => Skill.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting skills from Firebase: $e');
      return [];
    }
  }

  Future<void> insertSkill(
      Skill skill, String categoryId, String userId) async {
    final skillData = skill.toJson();
    skillData['categoryId'] = categoryId;
    skillData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'skills').doc(skill.id).set(skillData);
    print('Skill saved to Firebase for user $userId');
  }

  // Project operations
  Future<List<Project>> getProjectsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(userId, 'projects').get();

      return snapshot.docs
          .map((doc) => Project.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting projects from Firebase: $e');
      return [];
    }
  }

  Future<void> insertProject(Project project, String userId) async {
    final projectData = project.toJson();
    projectData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'projects')
        .doc(project.id)
        .set(projectData);
    print('Project saved to Firebase for user $userId');
  }

  // Certification operations
  Future<List<Certification>> getCertificationsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(userId, 'certifications').get();

      return snapshot.docs
          .map((doc) =>
              Certification.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting certifications from Firebase: $e');
      return [];
    }
  }

  Future<void> insertCertification(
      Certification certification, String userId) async {
    final certData = certification.toJson();
    certData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'certifications')
        .doc(certification.id)
        .set(certData);
    print('Certification saved to Firebase for user $userId');
  }

  // Educational Attainment operations
  Future<List<EducationalAttainment>> getEducationalAttainmentsForUser(
      String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(userId, 'educational_attainments').get();

      return snapshot.docs
          .map((doc) => EducationalAttainment.fromJson(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting educational attainments from Firebase: $e');
      return [];
    }
  }

  Future<void> insertEducationalAttainment(
      EducationalAttainment education, String userId) async {
    final eduData = education.toJson();
    eduData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'educational_attainments')
        .doc(education.id)
        .set(eduData);
    print('Educational attainment saved to Firebase for user $userId');
  }

  Future<void> updateEducationalAttainment(
      EducationalAttainment education) async {
    await _educationalAttainmentsCollection
        .doc(education.id)
        .update(education.toJson());
  }

  Future<void> deleteEducationalAttainment(String id) async {
    await _educationalAttainmentsCollection.doc(id).delete();
  }

  // Experience operations
  Future<List<Experience>> getExperiencesForUser(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(userId, 'experiences').get();

      return snapshot.docs
          .map((doc) => Experience.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting experiences from Firebase: $e');
      return [];
    }
  }

  Future<void> insertExperience(Experience experience, String userId) async {
    final expData = experience.toJson();
    expData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'experiences')
        .doc(experience.id)
        .set(expData);
    print('Experience saved to Firebase for user $userId');
  }

  Future<void> updateExperience(Experience experience) async {
    await _experiencesCollection.doc(experience.id).update(experience.toJson());
  }

  Future<void> deleteExperience(String id) async {
    await _experiencesCollection.doc(id).delete();
  }

  // Achievement operations
  Future<List<Achievement>> getAchievementsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _getUserCollection(userId, 'achievements').get();

      return snapshot.docs
          .map(
              (doc) => Achievement.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting achievements from Firebase: $e');
      return [];
    }
  }

  Future<void> insertAchievement(Achievement achievement, String userId) async {
    final achData = achievement.toJson();
    achData['userId'] = userId;
    // Save to user-specific subcollection
    await _getUserCollection(userId, 'achievements')
        .doc(achievement.id)
        .set(achData);
    print('Achievement saved to Firebase for user $userId');
  }

  // Profile views and likes operations
  Future<void> recordProfileView(String viewerId, String profileId) async {
    try {
      await _profileViewsCollection.add({
        'viewerId': viewerId,
        'profileId': profileId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update profile view count
      await _usersCollection.doc(profileId).update({
        'profileViews': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error recording profile view: $e');
    }
  }

  Future<void> likeProfile(String likerId, String profileId) async {
    try {
      await _profileLikesCollection.add({
        'likerId': likerId,
        'profileId': profileId,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update profile like count and add to likedBy list
      await _usersCollection.doc(profileId).update({
        'profileLikes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([likerId]),
      });
    } catch (e) {
      print('Error liking profile: $e');
    }
  }

  Future<void> unlikeProfile(String likerId, String profileId) async {
    try {
      // Find and remove the like document
      final snapshot = await _profileLikesCollection
          .where('likerId', isEqualTo: likerId)
          .where('profileId', isEqualTo: profileId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Update profile like count and remove from likedBy list
      await _usersCollection.doc(profileId).update({
        'profileLikes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([likerId]),
      });
    } catch (e) {
      print('Error unliking profile: $e');
    }
  }

  Future<bool> isProfileLiked(String likerId, String profileId) async {
    try {
      final snapshot = await _profileLikesCollection
          .where('likerId', isEqualTo: likerId)
          .where('profileId', isEqualTo: profileId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if profile is liked: $e');
      return false;
    }
  }

  Future<void> updateAchievement(Achievement achievement) async {
    await _achievementsCollection
        .doc(achievement.id)
        .update(achievement.toJson());
  }

  Future<void> deleteAchievement(String id) async {
    await _achievementsCollection.doc(id).delete();
  }

  // Incremental sync helpers
  Future<void> _syncProjects(UserAccount user) async {
    await _syncById(
      userId: user.id,
      collectionName: 'projects',
      items: user.projects,
      idOf: (p) => p.id,
      toJson: (p) => p.toJson(),
    );
  }

  Future<void> _syncCertifications(UserAccount user) async {
    await _syncById(
      userId: user.id,
      collectionName: 'certifications',
      items: user.certifications,
      idOf: (c) => c.id,
      toJson: (c) => c.toJson(),
    );
  }

  Future<void> _syncEducationalAttainments(UserAccount user) async {
    await _syncById(
      userId: user.id,
      collectionName: 'educational_attainments',
      items: user.educationalAttainments,
      idOf: (e) => e.id,
      toJson: (e) => e.toJson(),
    );
  }

  Future<void> _syncExperiences(UserAccount user) async {
    await _syncById(
      userId: user.id,
      collectionName: 'experiences',
      items: user.experiences,
      idOf: (e) => e.id,
      toJson: (e) => e.toJson(),
    );
  }

  Future<void> _syncAchievements(UserAccount user) async {
    await _syncById(
      userId: user.id,
      collectionName: 'achievements',
      items: user.achievements,
      idOf: (a) => a.id,
      toJson: (a) => a.toJson(),
    );
  }

  Future<void> _syncSkillData(UserAccount user) async {
    await _syncById(
      userId: user.id,
      collectionName: 'skill_categories',
      items: user.skillCategories,
      idOf: (c) => c.id,
      toJson: (c) => c.toJson(),
    );

    final allSkills = <Map<String, dynamic>>[];
    for (final category in user.skillCategories) {
      for (final skill in category.skills) {
        final json = skill.toJson();
        json['categoryId'] = category.id;
        allSkills.add(json);
      }
    }

    await _syncById<Map<String, dynamic>>(
      userId: user.id,
      collectionName: 'skills',
      items: allSkills,
      idOf: (s) => (s['id'] ?? '').toString(),
      toJson: (s) => s,
    );
  }

  Future<void> _syncById<T>({
    required String userId,
    required String collectionName,
    required List<T> items,
    required String Function(T item) idOf,
    required Map<String, dynamic> Function(T item) toJson,
  }) async {
    final collection = _getUserCollection(userId, collectionName);
    final snapshot = await collection.get();
    final existingIds = snapshot.docs.map((d) => d.id).toSet();
    final desiredIds = items.map(idOf).toSet();

    final batch = FirebaseFirestore.instance.batch();

    for (final item in items) {
      final id = idOf(item);
      final data = toJson(item);
      data['userId'] = userId;
      batch.set(collection.doc(id), data, SetOptions(merge: true));
    }

    for (final id in existingIds.difference(desiredIds)) {
      batch.delete(collection.doc(id));
    }

    await batch.commit();
  }

  // Search functionality - Optimized for better performance
  Future<List<Map<String, dynamic>>> searchRecords(String query) async {
    try {
      final q = query.trim().toLowerCase();
      print('Firebase searchRecords: Searching for "$q"');

      final QuerySnapshot snapshot = await _usersCollection.get();
      print(
          'Firebase searchRecords: Loaded ${snapshot.docs.length} users for filtering');

      final perUserResults = await Future.wait(snapshot.docs.map((doc) async {
        final userResults = <Map<String, dynamic>>[];
        final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);

        final matchesProfile = q.isEmpty ||
            _matchesQuery(user.name, q) ||
            _matchesQuery(user.course, q) ||
            _matchesQuery(user.yearLevel, q) ||
            _matchesQuery(user.studentId, q) ||
            _matchesQuery(user.address, q) ||
            _matchesQuery(user.bio, q) ||
            _matchesQuery(user.email, q);

        if (matchesProfile) {
          userResults.add({
            'type': 'profile',
            'user': user.name,
            'userId': user.id,
            'name': user.name,
            'course': user.course,
            'yearLevel': user.yearLevel,
            'studentId': user.studentId,
            'location': user.address,
            'bio': user.bio,
            'avatarUrl': user.avatarUrl,
            'instagramUrl': user.instagramUrl,
            'facebookUrl': user.facebookUrl,
          });
        }

        // Load all related collections in parallel for faster search.
        final related = await Future.wait([
          getSkillCategoriesForUser(user.id),
          getProjectsForUser(user.id),
          getCertificationsForUser(user.id),
          getEducationalAttainmentsForUser(user.id),
          getExperiencesForUser(user.id),
          getAchievementsForUser(user.id),
        ]);

        final skillCategories = related[0] as List<SkillCategory>;
        final projects = related[1] as List<Project>;
        final certs = related[2] as List<Certification>;
        final education = related[3] as List<EducationalAttainment>;
        final experiences = related[4] as List<Experience>;
        final achievements = related[5] as List<Achievement>;

        for (final cat in skillCategories) {
          for (final skill in cat.skills) {
            final matchesSkill = q.isEmpty ||
                _matchesQuery(skill.name, q) ||
                _matchesQuery(skill.level, q) ||
                _matchesQuery(cat.name, q);
            if (matchesSkill) {
              userResults.add({
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
        }

        for (final project in projects) {
          final matchesProject = q.isEmpty ||
              _matchesQuery(project.title, q) ||
              _matchesQuery(project.description, q) ||
              project.tags.any((t) => _matchesQuery(t, q));
          if (matchesProject) {
            userResults.add({
              'type': 'project',
              'user': user.name,
              'userId': user.id,
              'name': project.title,
              'description': project.description,
              'date': project.date,
              'tags': project.tags,
            });
          }
        }

        for (final cert in certs) {
          final matchesCert = q.isEmpty ||
              _matchesQuery(cert.title, q) ||
              _matchesQuery(cert.issuer, q) ||
              _matchesQuery(cert.certId, q);
          if (matchesCert) {
            userResults.add({
              'type': 'certification',
              'user': user.name,
              'userId': user.id,
              'name': cert.title,
              'issuer': cert.issuer,
              'date': cert.date,
              'certId': cert.certId,
            });
          }
        }

        for (final edu in education) {
          final matchesEdu = q.isEmpty ||
              _matchesQuery(edu.schoolName, q) ||
              _matchesQuery(edu.degree, q) ||
              _matchesQuery(edu.year, q) ||
              _matchesQuery(edu.address, q);
          if (matchesEdu) {
            userResults.add({
              'type': 'education',
              'user': user.name,
              'userId': user.id,
              'name': edu.schoolName,
              'degree': edu.degree,
              'year': edu.year,
              'address': edu.address,
            });
          }
        }

        for (final exp in experiences) {
          final matchesExp = q.isEmpty ||
              _matchesQuery(exp.company, q) ||
              _matchesQuery(exp.position, q) ||
              _matchesQuery(exp.description, q) ||
              _matchesQuery(exp.startDate, q) ||
              _matchesQuery(exp.endDate, q);
          if (matchesExp) {
            userResults.add({
              'type': 'experience',
              'user': user.name,
              'userId': user.id,
              'name': exp.position,
              'company': exp.company,
              'startDate': exp.startDate,
              'endDate': exp.endDate,
              'description': exp.description,
            });
          }
        }

        for (final ach in achievements) {
          final matchesAch = q.isEmpty ||
              _matchesQuery(ach.title, q) ||
              _matchesQuery(ach.category, q) ||
              _matchesQuery(ach.description, q) ||
              _matchesQuery(ach.date, q);
          if (matchesAch) {
            userResults.add({
              'type': 'achievement',
              'user': user.name,
              'userId': user.id,
              'name': ach.title,
              'category': ach.category,
              'date': ach.date,
              'description': ach.description,
            });
          }
        }
        return userResults;
      }));

      final results = perUserResults.expand((e) => e).toList();

      print('Firebase searchRecords: Found ${results.length} matching results');
      return results;
    } catch (e) {
      print('Error searching Firebase records: $e');
      return [];
    }
  }

  bool _matchesQuery(String text, String query) {
    return text.toLowerCase().contains(query);
  }

  // Helper method to create test data
  Future<void> createTestData() async {
    try {
      // Create demo user if missing
      final existingDemoUser = await getUserByEmail('maria.santos@ctu.edu.ph');
      if (existingDemoUser == null) {
        final demoUser = UserAccount(
          id: 'maria_sofia_santos',
          name: 'Maria Sofia Santos',
          email: 'maria.santos@ctu.edu.ph',
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
          instagramUrl: '',
          facebookUrl: '',
          profileViews: 0,
          profileLikes: 0,
          skillsPrivate: true,
          projectsPrivate: true,
          certificationsPrivate: true,
          experiencesPrivate: false,
          achievementsPrivate: false,
          careerObjectivePrivate: false,
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
              ],
            ),
            SkillCategory(
              id: 'cat-2',
              name: 'Tools & Frameworks',
              skills: [
                Skill(
                    id: 's5',
                    name: 'AutoCAD',
                    level: 'Advanced',
                    proficiencyPercent: 85),
                Skill(
                    id: 's6',
                    name: 'Microsoft Excel',
                    level: 'Expert',
                    proficiencyPercent: 95),
                Skill(
                    id: 's7',
                    name: 'MATLAB',
                    level: 'Intermediate',
                    proficiencyPercent: 62),
                Skill(
                    id: 's8',
                    name: 'Simio',
                    level: 'Intermediate',
                    proficiencyPercent: 58),
              ],
            ),
          ],
          projects: [
            Project(
              id: 'p1',
              title: 'Process Optimization Project',
              description:
                  'A study on production line optimization using simulation tools.',
              date: 'May 2024',
              memberCount: 3,
              tags: ['Simulation', 'Lean', 'Optimization'],
            ),
            Project(
              id: 'p2',
              title: 'Inventory Management System',
              description:
                  'A data-driven inventory control project for reducing waste.',
              date: 'August 2024',
              memberCount: 2,
              tags: ['Analytics', 'Inventory', 'Automation'],
            ),
          ],
          certifications: [
            Certification(
              id: 'c1',
              title: 'Certified Supply Chain Professional',
              issuer: 'CSCMP',
              date: 'December 2023',
              certId: 'ID: CSCMP-2023-001',
            ),
            Certification(
              id: 'c2',
              title: 'AWS Certified Cloud Practitioner',
              issuer: 'Amazon Web Services',
              date: 'March 2024',
              certId: 'ID: AWS-CCP-2024-12345',
            ),
          ],
          educationalAttainments: [
            EducationalAttainment(
              id: 'edu-1',
              schoolName: 'Cebu Technological University',
              degree: 'BS Industrial Engineering',
              year: '2021-2025',
              address: 'Cebu City',
            ),
          ],
          experiences: [
            Experience(
              id: 'exp-1',
              title: 'Internship at XYZ Manufacturing',
              company: 'XYZ Manufacturing',
              dateRange: 'June 2024 - August 2024',
              description:
                  'Assisted in process improvement projects and performed time studies.', position: '', startDate: '', endDate: '',
            ),
            Experience(
              id: 'exp-2',
              title: 'Research Assistant',
              company: 'CTU Research Center',
              dateRange: 'September 2024 - Present',
              description:
                  'Supported research on production efficiency and workflow analysis.', position: '', startDate: '', endDate: '',
            ),
          ],
          achievements: [
            Achievement(
              id: 'ach-1',
              title: 'Dean’s List',
              description: 'Recognized for academic excellence in 2023.', date: '', category: '',
            ),
            Achievement(
              id: 'ach-2',
              title: 'Best Capstone Proposal',
              description:
                  'Awarded for an innovative project proposal on logistics optimization.', date: '', category: '',
            ),
          ],
          careerObjective:
              'To become a skilled industrial engineer who leverages data-driven decisions to improve operations.',
        );
        await insertUser(demoUser);
        print('Demo user created successfully in Firebase');
      } else {
        print('Demo user already exists in Firebase');
      }

      // Create test user if missing
      final existingTestUser = await getUserByEmail('test.user@ctu.edu.ph');
      if (existingTestUser == null) {
        final testUser = UserAccount(
          id: 'test-user-001',
          name: 'Test User',
          email: 'test.user@ctu.edu.ph',
          password: 'password123',
          userType: 'student',
          course: 'Bachelor of Science in Information Technology',
          yearLevel: '3rd Year',
          studentId: '2021-12345',
          address: 'Cebu City, Philippines',
          bio: 'Test user for demonstration purposes',
          avatarUrl: '',
          instagramUrl: '',
          facebookUrl: '',
          profileViews: 0,
          profileLikes: 0,
          skillsPrivate: false,
          projectsPrivate: false,
          certificationsPrivate: false,
          experiencesPrivate: false,
          achievementsPrivate: false,
          careerObjectivePrivate: false,
          skillCategories: [
            SkillCategory(
              id: 'cat-001',
              name: 'Programming',
              skills: [
                Skill(
                    id: 'skill-001',
                    name: 'Flutter',
                    level: 'Intermediate',
                    proficiencyPercent: 75),
                Skill(
                    id: 'skill-002',
                    name: 'Firebase',
                    level: 'Beginner',
                    proficiencyPercent: 40),
              ],
            ),
          ],
          projects: [
            Project(
              id: 'proj-001',
              title: 'Mobile Portfolio App',
              description: 'A Flutter-based portfolio application',
              date: 'January 2024',
              memberCount: 2,
              tags: ['Flutter', 'Firebase', 'Mobile'],
            ),
          ],
          certifications: [
            Certification(
              id: 'cert-001',
              title: 'Flutter Development Certificate',
              issuer: 'Flutter Institute',
              date: 'December 2023',
              certId: '',
            ),
          ],
          educationalAttainments: [
            EducationalAttainment(
              id: 'edu-001',
              schoolName: 'Cebu Technological University',
              degree: 'BS in Information Technology',
              year: '2021-2025',
              address: 'Cebu City',
            ),
          ],
          experiences: [],
          achievements: [],
          careerObjective: 'To become a skilled software developer',
        );

        await insertUser(testUser);
        print('Test user created successfully in Firebase');
      } else {
        print('Test user already exists');
      }
    } catch (e) {
      print('Error creating test data: $e');
    }
  }
}
