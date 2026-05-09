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

  // Additional collections for compatibility
  final CollectionReference _skillCategoriesCollection =
      FirebaseFirestore.instance.collection('skill_categories');
  final CollectionReference _skillsCollection =
      FirebaseFirestore.instance.collection('skills');
  final CollectionReference _projectsCollection =
      FirebaseFirestore.instance.collection('projects');
  final CollectionReference _certificationsCollection =
      FirebaseFirestore.instance.collection('certifications');
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
      // Initialize user data with default values
      final userData = user.toJson();

      // Ensure all required fields have default values
      userData['profileViews'] = userData['profileViews'] ?? 0;
      userData['profileLikes'] = userData['profileLikes'] ?? 0;
      userData['likedBy'] = userData['likedBy'] ?? [];
      userData['approvedViewers'] = userData['approvedViewers'] ?? [];
      userData['skillsPrivate'] = userData['skillsPrivate'] ?? false;
      userData['projectsPrivate'] = userData['projectsPrivate'] ?? false;
      userData['certificationsPrivate'] =
          userData['certificationsPrivate'] ?? false;
      userData['experiencesPrivate'] = userData['experiencesPrivate'] ?? false;
      userData['achievementsPrivate'] =
          userData['achievementsPrivate'] ?? false;
      userData['careerObjectivePrivate'] =
          userData['careerObjectivePrivate'] ?? false;
      userData['skillCategories'] = userData['skillCategories'] ?? [];
      userData['projects'] = userData['projects'] ?? [];
      userData['certifications'] = userData['certifications'] ?? [];
      userData['educationalAttainments'] =
          userData['educationalAttainments'] ?? [];
      userData['experiences'] = userData['experiences'] ?? [];
      userData['achievements'] = userData['achievements'] ?? [];
      userData['careerObjective'] = userData['careerObjective'] ?? '';

      await _usersCollection.doc(user.id).set(userData);

      // Save related data to user-specific subcollections
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

      // Update related data
      await _updateSkillCategories(user);
      await _updateProjects(user);
      await _updateCertifications(user);
      await _updateEducationalAttainments(user);
      await _updateExperiences(user);
      await _updateAchievements(user);
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
    // Delete skill categories and skills
    final skillCategoriesSnapshot = await _skillCategoriesCollection
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in skillCategoriesSnapshot.docs) {
      // Delete skills in this category
      await _skillsCollection.where('categoryId', isEqualTo: doc.id).get().then(
          (snapshot) =>
              snapshot.docs.forEach((skillDoc) => skillDoc.reference.delete()));

      // Delete the category
      await doc.reference.delete();
    }

    // Delete projects
    final projectsSnapshot =
        await _projectsCollection.where('userId', isEqualTo: userId).get();
    for (var doc in projectsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete certifications
    final certificationsSnapshot = await _certificationsCollection
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in certificationsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete educational attainments
    final educationSnapshot = await _educationalAttainmentsCollection
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in educationSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete experiences
    final experiencesSnapshot =
        await _experiencesCollection.where('userId', isEqualTo: userId).get();
    for (var doc in experiencesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete achievements
    final achievementsSnapshot =
        await _achievementsCollection.where('userId', isEqualTo: userId).get();
    for (var doc in achievementsSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Skill Category operations
  Future<List<SkillCategory>> getSkillCategoriesForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _skillCategoriesCollection
          .where('userId', isEqualTo: userId)
          .get();

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
          await _getUserCollection(userId, 'educational_attainments')
              .orderBy('year', descending: true)
              .get();

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
          await _getUserCollection(userId, 'experiences')
              .orderBy('startDate', descending: true)
              .get();

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
          await _getUserCollection(userId, 'achievements')
              .orderBy('date', descending: true)
              .get();

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

  // Update helper methods
  Future<void> _updateSkillCategories(UserAccount user) async {
    // Delete existing categories and skills
    await _deleteSkillCategoriesForUser(user.id);

    // Insert new categories and skills
    for (final category in user.skillCategories) {
      await insertSkillCategory(category, user.id);
      for (final skill in category.skills) {
        await insertSkill(skill, category.id, user.id);
      }
    }
  }

  Future<void> _deleteSkillCategoriesForUser(String userId) async {
    final snapshot = await _skillCategoriesCollection
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      // Delete skills in this category
      await _skillsCollection.where('categoryId', isEqualTo: doc.id).get().then(
          (skillSnapshot) => skillSnapshot.docs
              .forEach((skillDoc) => skillDoc.reference.delete()));

      // Delete the category
      await doc.reference.delete();
    }
  }

  Future<void> _updateProjects(UserAccount user) async {
    // Delete existing projects
    final snapshot =
        await _projectsCollection.where('userId', isEqualTo: user.id).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Insert new projects
    for (final project in user.projects) {
      await insertProject(project, user.id);
    }
  }

  Future<void> _updateCertifications(UserAccount user) async {
    // Delete existing certifications
    final snapshot = await _certificationsCollection
        .where('userId', isEqualTo: user.id)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Insert new certifications
    for (final certification in user.certifications) {
      await insertCertification(certification, user.id);
    }
  }

  Future<void> _updateEducationalAttainments(UserAccount user) async {
    // Delete existing educational attainments
    final snapshot = await _educationalAttainmentsCollection
        .where('userId', isEqualTo: user.id)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Insert new educational attainments
    for (final education in user.educationalAttainments) {
      await insertEducationalAttainment(education, user.id);
    }
  }

  Future<void> _updateExperiences(UserAccount user) async {
    // Delete existing experiences
    final snapshot =
        await _experiencesCollection.where('userId', isEqualTo: user.id).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Insert new experiences
    for (final experience in user.experiences) {
      await insertExperience(experience, user.id);
    }
  }

  Future<void> _updateAchievements(UserAccount user) async {
    // Delete existing achievements
    final snapshot =
        await _achievementsCollection.where('userId', isEqualTo: user.id).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Insert new achievements
    for (final achievement in user.achievements) {
      await insertAchievement(achievement, user.id);
    }
  }

  // Search functionality - Optimized for better performance
  Future<List<Map<String, dynamic>>> searchRecords(String query) async {
    try {
      final results = <Map<String, dynamic>>[];
      final q = query.trim().toLowerCase();
      print('Firebase searchRecords: Searching for "$q"');

      final QuerySnapshot snapshot = await _usersCollection.get();
      print(
          'Firebase searchRecords: Loaded ${snapshot.docs.length} users for filtering');

      for (final doc in snapshot.docs) {
        final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);

        if (q.isEmpty ||
            _matchesQuery(user.name, q) ||
            _matchesQuery(user.course, q) ||
            _matchesQuery(user.yearLevel, q) ||
            _matchesQuery(user.studentId, q) ||
            _matchesQuery(user.address, q) ||
            _matchesQuery(user.bio, q) ||
            _matchesQuery(user.email, q)) {
          results.add({
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
      }

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
