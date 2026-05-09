// lib/data/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  static const String _dbName = 'selecta_coe.db';
  static const int _dbVersion = 9;

  // Table names
  static const String usersTable = 'users';
  static const String skillCategoriesTable = 'skill_categories';
  static const String skillsTable = 'skills';
  static const String projectsTable = 'projects';
  static const String certificationsTable = 'certifications';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE $usersTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        password TEXT NOT NULL,
        userType TEXT NOT NULL,
        course TEXT,
        yearLevel TEXT,
        studentId TEXT,
        location TEXT,
        avatarInitials TEXT,
        avatarUrl TEXT,
        bio TEXT,
        instagramUrl TEXT,
        facebookUrl TEXT,
        skillsPrivate INTEGER DEFAULT 0,
        projectsPrivate INTEGER DEFAULT 0,
        certificationsPrivate INTEGER DEFAULT 0,
        experiencesPrivate INTEGER DEFAULT 0,
        achievementsPrivate INTEGER DEFAULT 0,
        careerObjectivePrivate INTEGER DEFAULT 0,
        approvedViewers TEXT DEFAULT '[]',
        profileViews INTEGER DEFAULT 0,
        profileLikes INTEGER DEFAULT 0,
        likedBy TEXT DEFAULT '[]',
        careerObjective TEXT DEFAULT ''
      )
    ''');

    // Create skill_categories table
    await db.execute('''
      CREATE TABLE $skillCategoriesTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create skills table
    await db.execute('''
      CREATE TABLE $skillsTable (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        proficiencyPercent REAL NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES $skillCategoriesTable (id) ON DELETE CASCADE
      )
    ''');

    // Create projects table
    await db.execute('''
      CREATE TABLE $projectsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT,
        memberCount INTEGER,
        tags TEXT,
        FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create certifications table
    await db.execute('''
      CREATE TABLE $certificationsTable (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        issuer TEXT,
        date TEXT,
        certId TEXT,
        FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create educational_attainments table
    await db.execute('''
      CREATE TABLE educational_attainments (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        schoolName TEXT NOT NULL,
        degree TEXT,
        year TEXT,
        address TEXT,
        FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create experiences table
    await db.execute('''
      CREATE TABLE experiences (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        company TEXT NOT NULL,
        position TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT,
        description TEXT,
        FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create achievements table
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT,
        category TEXT,
        FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_email ON $usersTable(email)');
    await db.execute(
        'CREATE INDEX idx_skill_categories_user ON $skillCategoriesTable(userId)');
    await db.execute(
        'CREATE INDEX idx_skills_category ON $skillsTable(categoryId)');
    await db
        .execute('CREATE INDEX idx_projects_user ON $projectsTable(userId)');
    await db.execute(
        'CREATE INDEX idx_certifications_user ON $certificationsTable(userId)');
    await db.execute(
        'CREATE INDEX idx_educational_attainments_user ON educational_attainments(userId)');
    await db
        .execute('CREATE INDEX idx_experiences_user ON experiences(userId)');
    await db
        .execute('CREATE INDEX idx_achievements_user ON achievements(userId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Database upgrade: oldVersion=$oldVersion, newVersion=$newVersion');
    // Handle database migrations here when upgrading versions
    if (oldVersion < 2) {
      print('Adding userType column to existing database...');
      // Add userType column to existing users table
      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN userType TEXT DEFAULT \'Student\'');
        print('userType column added successfully');
      } catch (e) {
        print('Error adding userType column: $e');
        // Try alternative approach
        await db.execute('ALTER TABLE $usersTable ADD COLUMN userType TEXT');
        print('userType column added with alternative approach');
      }
    }

    if (oldVersion < 3) {
      print('Adding profile views and likes columns...');
      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN profileViews INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN profileLikes INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN likedBy TEXT DEFAULT \'[]\'');
        print('Profile views and likes columns added successfully');
      } catch (e) {
        print('Error adding profile views and likes columns: $e');
      }
    }

    if (oldVersion < 4) {
      print('Adding education columns...');
      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN schoolName TEXT DEFAULT \'\'');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN degree TEXT DEFAULT \'\'');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN year TEXT DEFAULT \'\'');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN address_EA TEXT DEFAULT \'\'');
        print('Education columns added successfully');
      } catch (e) {
        print('Error adding education columns: $e');
      }
    }

    if (oldVersion < 5) {
      print('Adding educational_attainments table...');
      try {
        await db.execute('''
          CREATE TABLE educational_attainments (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            schoolName TEXT NOT NULL,
            degree TEXT,
            year TEXT,
            address TEXT,
            FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_educational_attainments_user ON educational_attainments(userId)');
        print('Educational attainments table created successfully');
      } catch (e) {
        print('Error creating educational_attainments table: $e');
      }
    }

    if (oldVersion < 6) {
      print('Adding experience and achievements tables...');
      try {
        await db.execute('''
          CREATE TABLE experiences (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            company TEXT NOT NULL,
            position TEXT NOT NULL,
            startDate TEXT,
            endDate TEXT,
            description TEXT,
            FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_experiences_user ON experiences(userId)');

        await db.execute('''
          CREATE TABLE achievements (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            date TEXT,
            category TEXT,
            FOREIGN KEY (userId) REFERENCES $usersTable (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_achievements_user ON achievements(userId)');

        // Add careerObjective column to users table
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN careerObjective TEXT DEFAULT \'\'');

        // Add privacy columns for new features
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN experiencesPrivate INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN achievementsPrivate INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN careerObjectivePrivate INTEGER DEFAULT 0');

        print('Experience and achievements tables created successfully');
      } catch (e) {
        print('Error creating experience and achievements tables: $e');
      }
    }

    if (oldVersion < 7) {
      print('Adding careerObjective column if missing...');
      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN careerObjective TEXT DEFAULT \'\'');
        print('careerObjective column added successfully');
      } catch (e) {
        print('Error adding careerObjective column (may already exist): $e');
      }

      // Safety check: ensure all privacy columns exist
      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN experiencesPrivate INTEGER DEFAULT 0');
        print('experiencesPrivate column added successfully');
      } catch (e) {
        print('experiencesPrivate column may already exist: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN achievementsPrivate INTEGER DEFAULT 0');
        print('achievementsPrivate column added successfully');
      } catch (e) {
        print('achievementsPrivate column may already exist: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN careerObjectivePrivate INTEGER DEFAULT 0');
        print('careerObjectivePrivate column added successfully');
      } catch (e) {
        print('careerObjectivePrivate column may already exist: $e');
      }
    }

    if (oldVersion < 8) {
      print('Version 8 upgrade: Ensuring all privacy columns exist...');
      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN experiencesPrivate INTEGER DEFAULT 0');
        print('experiencesPrivate column added in v8 upgrade');
      } catch (e) {
        print('experiencesPrivate column already exists: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN achievementsPrivate INTEGER DEFAULT 0');
        print('achievementsPrivate column added in v8 upgrade');
      } catch (e) {
        print('achievementsPrivate column already exists: $e');
      }

      try {
        await db.execute(
            'ALTER TABLE $usersTable ADD COLUMN careerObjectivePrivate INTEGER DEFAULT 0');
        print('careerObjectivePrivate column added in v8 upgrade');
      } catch (e) {
        print('careerObjectivePrivate column already exists: $e');
      }
    }

    if (oldVersion < 9) {
      print('Version 9 upgrade: Adding userId column to skills table...');
      try {
        await db.execute('ALTER TABLE $skillsTable ADD COLUMN userId TEXT');
        print('userId column added to skills table in v9 upgrade');
      } catch (e) {
        print('userId column already exists in skills table: $e');
      }
    }
  }

  // User operations
  Future<int> insertUser(UserAccount user) async {
    final db = await database;
    final userId = await db.insert(usersTable, _userToMap(user));

    // Save related data (skills, projects, certifications)
    await _saveRelatedData(user);

    return userId;
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
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(usersTable);

    List<UserAccount> users = [];
    for (var userMap in maps) {
      final user = _mapToUser(userMap);

      // Load related data
      user.skillCategories = await getSkillCategoriesForUser(user.id);
      user.projects = await getProjectsForUser(user.id);
      user.certifications = await getCertificationsForUser(user.id);
      user.educationalAttainments =
          await getEducationalAttainmentsForUser(user.id);
      user.experiences = await getExperiencesForUser(user.id);
      user.achievements = await getAchievementsForUser(user.id);

      users.add(user);
    }
    return users;
  }

  Future<UserAccount?> getUserByEmail(String email) async {
    print('Querying database for email: $email');
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        usersTable,
        where: 'email = ?',
        whereArgs: [email],
      );
      print('Query returned ${maps.length} results');

      if (maps.isEmpty) return null;

      final user = _mapToUser(maps.first);

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
      print('Error in getUserByEmail: $e');
      return null;
    }
  }

  Future<UserAccount?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final user = _mapToUser(maps.first);

    // Load related data
    user.skillCategories = await getSkillCategoriesForUser(user.id);
    user.projects = await getProjectsForUser(user.id);
    user.certifications = await getCertificationsForUser(user.id);
    user.educationalAttainments =
        await getEducationalAttainmentsForUser(user.id);
    user.experiences = await getExperiencesForUser(user.id);
    user.achievements = await getAchievementsForUser(user.id);

    return user;
  }

  Future<int> updateUser(UserAccount user) async {
    final db = await database;

// ...
    // Update user
    await db.update(
      usersTable,
      _userToMap(user),
      where: 'id = ?',
      whereArgs: [user.id],
    );

    // Update related data
    await _updateSkillCategories(user);
    await _updateProjects(user);
    await _updateCertifications(user);
    await _updateEducationalAttainments(user);
    await _updateExperiences(user);
    await _updateAchievements(user);

    return 1;
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db.delete(
      usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Skill Category operations
  Future<List<SkillCategory>> getSkillCategoriesForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      skillCategoriesTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );

    List<SkillCategory> categories = [];
    for (var map in maps) {
      final category = _mapToSkillCategory(map);
      category.skills = await getSkillsForCategory(category.id);
      categories.add(category);
    }
    return categories;
  }

  Future<int> insertSkillCategory(SkillCategory category, String userId) async {
    final db = await database;
    final map = _skillCategoryToMap(category);
    map['userId'] = userId;
    return await db.insert(skillCategoriesTable, map);
  }

  // Skill operations
  Future<List<Skill>> getSkillsForCategory(String categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      skillsTable,
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return maps.map((map) => _mapToSkill(map)).toList();
  }

  Future<int> insertSkill(Skill skill, String categoryId, String userId) async {
    final db = await database;
    final map = _skillToMap(skill);
    map['categoryId'] = categoryId;
    map['userId'] = userId;

    try {
      return await db.insert(skillsTable, map);
    } catch (e) {
      // If duplicate ID error, generate new ID
      if (e.toString().contains('UNIQUE constraint failed')) {
        final newSkill = Skill(
          id: 's${DateTime.now().millisecondsSinceEpoch}',
          name: skill.name,
          level: skill.level,
          proficiencyPercent: skill.proficiencyPercent,
        );
        final newMap = _skillToMap(newSkill);
        newMap['categoryId'] = categoryId;
        newMap['userId'] = userId;
        return await db.insert(skillsTable, newMap);
      }
      rethrow;
    }
  }

  // Project operations
  Future<List<Project>> getProjectsForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      projectsTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => _mapToProject(map)).toList();
  }

  Future<int> insertProject(Project project, String userId) async {
    final db = await database;
    final map = _projectToMap(project);
    map['userId'] = userId;
    return await db.insert(projectsTable, map);
  }

  // Certification operations
  Future<List<Certification>> getCertificationsForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      certificationsTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => _mapToCertification(map)).toList();
  }

  Future<int> insertCertification(
      Certification certification, String userId) async {
    final db = await database;
    final map = _certificationToMap(certification);
    map['userId'] = userId;
    return await db.insert(certificationsTable, map);
  }

  // Educational Attainment operations
  Future<List<EducationalAttainment>> getEducationalAttainmentsForUser(
      String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'educational_attainments',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'year DESC',
    );
    return maps.map((map) => _mapToEducationalAttainment(map)).toList();
  }

  Future<int> insertEducationalAttainment(
      EducationalAttainment education, String userId) async {
    final db = await database;
    final map = _educationalAttainmentToMap(education);
    map['userId'] = userId;
    return await db.insert('educational_attainments', map);
  }

  Future<int> updateEducationalAttainment(
      EducationalAttainment education) async {
    final db = await database;
    return await db.update(
      'educational_attainments',
      _educationalAttainmentToMap(education),
      where: 'id = ?',
      whereArgs: [education.id],
    );
  }

  Future<int> deleteEducationalAttainment(String id) async {
    final db = await database;
    return await db.delete(
      'educational_attainments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Experience operations
  Future<List<Experience>> getExperiencesForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'experiences',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startDate DESC',
    );
    return maps.map((map) => _mapToExperience(map)).toList();
  }

  Future<int> insertExperience(Experience experience, String userId) async {
    final db = await database;
    final map = _experienceToMap(experience);
    map['userId'] = userId;
    return await db.insert('experiences', map);
  }

  Future<int> updateExperience(Experience experience) async {
    final db = await database;
    return await db.update(
      'experiences',
      _experienceToMap(experience),
      where: 'id = ?',
      whereArgs: [experience.id],
    );
  }

  Future<int> deleteExperience(String id) async {
    final db = await database;
    return await db.delete(
      'experiences',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Achievement operations
  Future<List<Achievement>> getAchievementsForUser(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'achievements',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => _mapToAchievement(map)).toList();
  }

  Future<int> insertAchievement(Achievement achievement, String userId) async {
    final db = await database;
    final map = _achievementToMap(achievement);
    map['userId'] = userId;
    return await db.insert('achievements', map);
  }

  Future<int> updateAchievement(Achievement achievement) async {
    final db = await database;
    return await db.update(
      'achievements',
      _achievementToMap(achievement),
      where: 'id = ?',
      whereArgs: [achievement.id],
    );
  }

  Future<int> deleteAchievement(String id) async {
    final db = await database;
    return await db.delete(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods for conversions
  Map<String, dynamic> _userToMap(UserAccount user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'password': user.password.trim(),
      'userType': user.userType,
      'course': user.course,
      'yearLevel': user.yearLevel,
      'studentId': user.studentId,
      'location': user.address,
      'avatarInitials': user.avatarInitials,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
      'instagramUrl': user.instagramUrl,
      'facebookUrl': user.facebookUrl,
      'skillsPrivate': user.skillsPrivate ? 1 : 0,
      'projectsPrivate': user.projectsPrivate ? 1 : 0,
      'certificationsPrivate': user.certificationsPrivate ? 1 : 0,
      'experiencesPrivate': user.experiencesPrivate ? 1 : 0,
      'achievementsPrivate': user.achievementsPrivate ? 1 : 0,
      'careerObjectivePrivate': user.careerObjectivePrivate ? 1 : 0,
      'approvedViewers': json.encode(user.approvedViewers),
      'profileViews': user.profileViews,
      'profileLikes': user.profileLikes,
      'likedBy': json.encode(user.likedBy),
      'careerObjective': user.careerObjective,
    };
  }

  UserAccount _mapToUser(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'] ?? '',
      password: map['password']?.toString().trim() ?? '',
      userType: map['userType'] ?? 'Student',
      course: map['course'] ?? '',
      yearLevel: map['yearLevel'] ?? '',
      studentId: map['studentId'] ?? '',
      address: map['location'] ?? '',
      avatarInitials: map['avatarInitials'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      bio: map['bio'] ?? '',
      instagramUrl: map['instagramUrl'] ?? '',
      facebookUrl: map['facebookUrl'] ?? '',
      skillsPrivate: (map['skillsPrivate'] as int? ?? 0) == 1,
      projectsPrivate: (map['projectsPrivate'] as int? ?? 0) == 1,
      certificationsPrivate: (map['certificationsPrivate'] as int? ?? 0) == 1,
      experiencesPrivate: (map['experiencesPrivate'] as int? ?? 0) == 1,
      achievementsPrivate: (map['achievementsPrivate'] as int? ?? 0) == 1,
      careerObjectivePrivate: (map['careerObjectivePrivate'] as int? ?? 0) == 1,
      approvedViewers: map['approvedViewers'] != null
          ? map['approvedViewers'] is String
              ? List<String>.from(jsonDecode(map['approvedViewers']))
              : List<String>.from(map['approvedViewers'])
          : <String>[],
      profileViews: (map['profileViews'] as int?) ?? 0,
      profileLikes: (map['profileLikes'] as int?) ?? 0,
      likedBy: map['likedBy'] != null
          ? map['likedBy'] is String
              ? List<String>.from(jsonDecode(map['likedBy']))
              : List<String>.from(map['likedBy'])
          : <String>[],
      educationalAttainments: const [], // Will be loaded separately
      experiences: const [], // Will be loaded separately
      achievements: const [], // Will be loaded separately
      careerObjective: map['careerObjective'] ?? '',
    );
  }

  Map<String, dynamic> _skillCategoryToMap(SkillCategory category) {
    return {
      'id': category.id,
      'name': category.name,
    };
  }

  SkillCategory _mapToSkillCategory(Map<String, dynamic> map) {
    return SkillCategory(
      id: map['id'],
      name: map['name'],
    );
  }

  Map<String, dynamic> _skillToMap(Skill skill) {
    return {
      'id': skill.id,
      'name': skill.name,
      'level': skill.level,
      'proficiencyPercent': skill.proficiencyPercent,
    };
  }

  Skill _mapToSkill(Map<String, dynamic> map) {
    return Skill(
      id: map['id'],
      name: map['name'],
      level: map['level'],
      proficiencyPercent: map['proficiencyPercent'].toDouble(),
    );
  }

  Map<String, dynamic> _projectToMap(Project project) {
    return {
      'id': project.id,
      'title': project.title,
      'description': project.description,
      'date': project.date,
      'memberCount': project.memberCount,
      'tags': project.tags.join(','),
    };
  }

  Project _mapToProject(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      tags: (map['tags'] as String? ?? '')
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  Map<String, dynamic> _certificationToMap(Certification certification) {
    return {
      'id': certification.id,
      'title': certification.title,
      'issuer': certification.issuer,
      'date': certification.date,
      'certId': certification.certId,
    };
  }

  Certification _mapToCertification(Map<String, dynamic> map) {
    return Certification(
      id: map['id'],
      title: map['title'],
      issuer: map['issuer'] ?? '',
      date: map['date'] ?? '',
      certId: map['certId'] ?? '',
    );
  }

  Map<String, dynamic> _educationalAttainmentToMap(
      EducationalAttainment education) {
    return {
      'id': education.id,
      'schoolName': education.schoolName,
      'degree': education.degree,
      'year': education.year,
      'address': education.address,
    };
  }

  EducationalAttainment _mapToEducationalAttainment(Map<String, dynamic> map) {
    return EducationalAttainment(
      id: map['id'],
      schoolName: map['schoolName'],
      degree: map['degree'] ?? '',
      year: map['year'] ?? '',
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> _experienceToMap(Experience experience) {
    return {
      'id': experience.id,
      'company': experience.company,
      'position': experience.position,
      'startDate': experience.startDate,
      'endDate': experience.endDate,
      'description': experience.description,
    };
  }

  Experience _mapToExperience(Map<String, dynamic> map) {
    return Experience(
      id: map['id'],
      company: map['company'],
      position: map['position'],
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> _achievementToMap(Achievement achievement) {
    return {
      'id': achievement.id,
      'title': achievement.title,
      'description': achievement.description,
      'date': achievement.date,
      'category': achievement.category,
    };
  }

  Achievement _mapToAchievement(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      category: map['category'] ?? '',
    );
  }

  // Private methods for updating related data
  Future<void> _updateSkillCategories(UserAccount user) async {
    final db = await database;

    // Delete existing categories
    await db.delete(
      skillCategoriesTable,
      where: 'userId = ?',
      whereArgs: [user.id],
    );

    // Insert new categories and skills
    for (final category in user.skillCategories) {
      await insertSkillCategory(category, user.id);

      // Insert skills for this category
      for (final skill in category.skills) {
        await insertSkill(skill, category.id, user.id);
      }
    }
  }

  Future<void> _updateProjects(UserAccount user) async {
    final db = await database;

    // Delete existing projects
    await db.delete(
      projectsTable,
      where: 'userId = ?',
      whereArgs: [user.id],
    );

    // Insert new projects
    for (final project in user.projects) {
      await insertProject(project, user.id);
    }
  }

  Future<void> _updateCertifications(UserAccount user) async {
    final db = await database;

    // Delete existing certifications
    await db.delete(
      certificationsTable,
      where: 'userId = ?',
      whereArgs: [user.id],
    );

    // Insert new certifications
    for (final certification in user.certifications) {
      await insertCertification(certification, user.id);
    }
  }

  Future<void> _updateEducationalAttainments(UserAccount user) async {
    final db = await database;

    // Delete existing educational attainments
    await db.delete(
      'educational_attainments',
      where: 'userId = ?',
      whereArgs: [user.id],
    );

    // Insert new educational attainments
    for (final education in user.educationalAttainments) {
      await insertEducationalAttainment(education, user.id);
    }
  }

  Future<void> _updateExperiences(UserAccount user) async {
    final db = await database;

    // Delete existing experiences
    await db.delete(
      'experiences',
      where: 'userId = ?',
      whereArgs: [user.id],
    );

    // Insert new experiences
    for (final experience in user.experiences) {
      await insertExperience(experience, user.id);
    }
  }

  Future<void> _updateAchievements(UserAccount user) async {
    final db = await database;

    // Delete existing achievements
    await db.delete(
      'achievements',
      where: 'userId = ?',
      whereArgs: [user.id],
    );

    // Insert new achievements
    for (final achievement in user.achievements) {
      await insertAchievement(achievement, user.id);
    }
  }

  // Search functionality
  Future<List<Map<String, dynamic>>> searchRecords(String query) async {
    final users = await getAllUsers();

    final results = <Map<String, dynamic>>[];
    final q = query.toLowerCase();

    for (final user in users) {
      // User profile
      if (_matchesQuery(user.name, q) ||
          _matchesQuery(user.course, q) ||
          _matchesQuery(user.yearLevel, q) ||
          _matchesQuery(user.studentId, q) ||
          _matchesQuery(user.address, q) ||
          _matchesQuery(user.bio, q)) {
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

      // Skills
      for (final cat in user.skillCategories) {
        for (final skill in cat.skills) {
          if (_matchesQuery(skill.name, q) ||
              _matchesQuery(skill.level, q) ||
              _matchesQuery(cat.name, q)) {
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
      }

      // Projects
      for (final project in user.projects) {
        if (_matchesQuery(project.title, q) ||
            _matchesQuery(project.description, q) ||
            project.tags.any((tag) => _matchesQuery(tag, q))) {
          results.add({
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

      // Certifications
      for (final cert in user.certifications) {
        if (_matchesQuery(cert.title, q) || _matchesQuery(cert.issuer, q)) {
          results.add({
            'type': 'certification',
            'user': user.name,
            'userId': user.id,
            'name': cert.title,
            'issuer': cert.issuer,
            'date': cert.date,
          });
        }
      }
    }

    return results;
  }

  bool _matchesQuery(String text, String query) {
    return text.toLowerCase().contains(query.toLowerCase());
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
