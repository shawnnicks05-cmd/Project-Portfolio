// lib/data/firebase_database_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _skillCategoriesCollection = FirebaseFirestore.instance.collection('skill_categories');
  final CollectionReference _skillsCollection = FirebaseFirestore.instance.collection('skills');
  final CollectionReference _projectsCollection = FirebaseFirestore.instance.collection('projects');
  final CollectionReference _certificationsCollection = FirebaseFirestore.instance.collection('certifications');
  final CollectionReference _educationalAttainmentsCollection = FirebaseFirestore.instance.collection('educational_attainments');
  final CollectionReference _experiencesCollection = FirebaseFirestore.instance.collection('experiences');
  final CollectionReference _achievementsCollection = FirebaseFirestore.instance.collection('achievements');

  // User operations
  Future<void> insertUser(UserAccount user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
      
      // Save related data
      await _saveRelatedData(user);
    } catch (e) {
      print('Error inserting user to Firebase: $e');
      throw Exception('Failed to save user to Firebase');
    }
  }

  Future<void> _saveRelatedData(UserAccount user) async {
    // Save skill categories and skills
    for (final category in user.skillCategories) {
      await insertSkillCategory(category, user.id);
      
      for (final skill in category.skills) {
        await insertSkill(skill, category.id, user.id);
      }
    }

    // Save projects
    for (final project in user.projects) {
      await insertProject(project, user.id);
    }

    // Save certifications
    for (final certification in user.certifications) {
      await insertCertification(certification, user.id);
    }

    // Save educational attainments
    for (final education in user.educationalAttainments) {
      await insertEducationalAttainment(education, user.id);
    }

    // Save experiences
    for (final experience in user.experiences) {
      await insertExperience(experience, user.id);
    }

    // Save achievements
    for (final achievement in user.achievements) {
      await insertAchievement(achievement, user.id);
    }
  }

  Future<List<UserAccount>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await _usersCollection.get();
      
      List<UserAccount> users = [];
      for (var doc in snapshot.docs) {
        final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);
        
        // Load related data
        user.skillCategories = await getSkillCategoriesForUser(user.id);
        user.projects = await getProjectsForUser(user.id);
        user.certifications = await getCertificationsForUser(user.id);
        user.educationalAttainments = await getEducationalAttainmentsForUser(user.id);
        user.experiences = await getExperiencesForUser(user.id);
        user.achievements = await getAchievementsForUser(user.id);
        
        users.add(user);
      }
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
      user.educationalAttainments = await getEducationalAttainmentsForUser(user.id);
      user.experiences = await getExperiencesForUser(user.id);
      user.achievements = await getAchievementsForUser(user.id);

      return user;
    } catch (e) {
      print('Error getting user by email from Firebase: $e');
      return null;
    }
  }

  Future<UserAccount?> getUserById(String id) async {
    try {
      final DocumentSnapshot doc = await _usersCollection.doc(id).get();

      if (!doc.exists) return null;

      final user = UserAccount.fromJson(doc.data() as Map<String, dynamic>);

      // Load related data
      user.skillCategories = await getSkillCategoriesForUser(user.id);
      user.projects = await getProjectsForUser(user.id);
      user.certifications = await getCertificationsForUser(user.id);
      user.educationalAttainments = await getEducationalAttainmentsForUser(user.id);
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
      await _skillsCollection
          .where('categoryId', isEqualTo: doc.id)
          .get()
          .then((snapshot) => snapshot.docs.forEach((skillDoc) => skillDoc.reference.delete()));
      
      // Delete the category
      await doc.reference.delete();
    }

    // Delete projects
    final projectsSnapshot = await _projectsCollection
        .where('userId', isEqualTo: userId)
        .get();
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
    final experiencesSnapshot = await _experiencesCollection
        .where('userId', isEqualTo: userId)
        .get();
    for (var doc in experiencesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete achievements
    final achievementsSnapshot = await _achievementsCollection
        .where('userId', isEqualTo: userId)
        .get();
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
        final category = SkillCategory.fromJson(doc.data() as Map<String, dynamic>);
        category.skills = await getSkillsForCategory(category.id);
        categories.add(category);
      }
      return categories;
    } catch (e) {
      print('Error getting skill categories from Firebase: $e');
      return [];
    }
  }

  Future<void> insertSkillCategory(SkillCategory category, String userId) async {
    final categoryData = category.toJson();
    categoryData['userId'] = userId;
    await _skillCategoriesCollection.doc(category.id).set(categoryData);
  }

  // Skill operations
  Future<List<Skill>> getSkillsForCategory(String categoryId) async {
    try {
      final QuerySnapshot snapshot = await _skillsCollection
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

  Future<void> insertSkill(Skill skill, String categoryId, String userId) async {
    final skillData = skill.toJson();
    skillData['categoryId'] = categoryId;
    skillData['userId'] = userId;
    await _skillsCollection.doc(skill.id).set(skillData);
  }

  // Project operations
  Future<List<Project>> getProjectsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _projectsCollection
          .where('userId', isEqualTo: userId)
          .get();

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
    await _projectsCollection.doc(project.id).set(projectData);
  }

  // Certification operations
  Future<List<Certification>> getCertificationsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _certificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => Certification.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting certifications from Firebase: $e');
      return [];
    }
  }

  Future<void> insertCertification(Certification certification, String userId) async {
    final certificationData = certification.toJson();
    certificationData['userId'] = userId;
    await _certificationsCollection.doc(certification.id).set(certificationData);
  }

  // Educational Attainment operations
  Future<List<EducationalAttainment>> getEducationalAttainmentsForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _educationalAttainmentsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('year', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EducationalAttainment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting educational attainments from Firebase: $e');
      return [];
    }
  }

  Future<void> insertEducationalAttainment(EducationalAttainment education, String userId) async {
    final educationData = education.toJson();
    educationData['userId'] = userId;
    await _educationalAttainmentsCollection.doc(education.id).set(educationData);
  }

  Future<void> updateEducationalAttainment(EducationalAttainment education) async {
    await _educationalAttainmentsCollection.doc(education.id).update(education.toJson());
  }

  Future<void> deleteEducationalAttainment(String id) async {
    await _educationalAttainmentsCollection.doc(id).delete();
  }

  // Experience operations
  Future<List<Experience>> getExperiencesForUser(String userId) async {
    try {
      final QuerySnapshot snapshot = await _experiencesCollection
          .where('userId', isEqualTo: userId)
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
    final experienceData = experience.toJson();
    experienceData['userId'] = userId;
    await _experiencesCollection.doc(experience.id).set(experienceData);
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
      final QuerySnapshot snapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Achievement.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting achievements from Firebase: $e');
      return [];
    }
  }

  Future<void> insertAchievement(Achievement achievement, String userId) async {
    final achievementData = achievement.toJson();
    achievementData['userId'] = userId;
    await _achievementsCollection.doc(achievement.id).set(achievementData);
  }

  Future<void> updateAchievement(Achievement achievement) async {
    await _achievementsCollection.doc(achievement.id).update(achievement.toJson());
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
      await _skillsCollection
          .where('categoryId', isEqualTo: doc.id)
          .get()
          .then((skillSnapshot) => skillSnapshot.docs.forEach((skillDoc) => skillDoc.reference.delete()));
      
      // Delete the category
      await doc.reference.delete();
    }
  }

  Future<void> _updateProjects(UserAccount user) async {
    // Delete existing projects
    final snapshot = await _projectsCollection
        .where('userId', isEqualTo: user.id)
        .get();
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
    final snapshot = await _experiencesCollection
        .where('userId', isEqualTo: user.id)
        .get();
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
    final snapshot = await _achievementsCollection
        .where('userId', isEqualTo: user.id)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    
    // Insert new achievements
    for (final achievement in user.achievements) {
      await insertAchievement(achievement, user.id);
    }
  }
}
