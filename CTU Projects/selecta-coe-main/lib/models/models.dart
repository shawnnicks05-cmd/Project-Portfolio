// lib/models/models.dart
import 'dart:convert';

List<String> _parseStringList(dynamic value) {
  if (value == null) return <String>[];

  // Some older data may store arrays as JSON-encoded strings.
  if (value is String) {
    try {
      return _parseStringList(jsonDecode(value));
    } catch (_) {
      return <String>[];
    }
  }

  if (value is Iterable) {
    return value.where((e) => e != null).map((e) => e.toString()).toList();
  }

  return <String>[];
}

class UserAccount {
  String id;
  String name;
  String email;
  String phone;
  String password;
  String userType; // 'Student' or 'Professor'
  String course;
  String yearLevel;
  String studentId;
  String address;
  String department;
  String avatarInitials;
  String avatarUrl;
  String bio;
  String instagramUrl;
  String facebookUrl;
  List<SkillCategory> skillCategories;
  List<Project> projects;
  List<Certification> certifications;
  bool skillsPrivate;
  bool projectsPrivate;
  bool certificationsPrivate;
  bool experiencesPrivate;
  bool achievementsPrivate;
  bool careerObjectivePrivate;
  List<String> approvedViewers; // User IDs that can view private data
  int profileViews;
  int profileLikes;
  List<String> likedBy; // List of user IDs who liked this profile
  List<EducationalAttainment> educationalAttainments;
  List<Experience> experiences;
  List<Achievement> achievements;
  String careerObjective;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.userType,
    this.phone = '',
    this.course = '',
    this.yearLevel = '',
    this.studentId = '',
    this.address = '',
    this.department = '',
    this.avatarInitials = '',
    this.avatarUrl = '',
    this.bio = '',
    this.instagramUrl = '',
    this.facebookUrl = '',
    this.skillCategories = const [],
    this.projects = const [],
    this.certifications = const [],
    this.educationalAttainments = const [],
    this.experiences = const [],
    this.achievements = const [],
    this.careerObjective = '',
    this.skillsPrivate = false,
    this.projectsPrivate = false,
    this.certificationsPrivate = false,
    this.experiencesPrivate = false,
    this.achievementsPrivate = false,
    this.careerObjectivePrivate = false,
    this.approvedViewers = const [],
    this.profileViews = 0,
    this.profileLikes = 0,
    this.likedBy = const [],
  });

  int get totalSkills =>
      skillCategories.fold(0, (sum, cat) => sum + cat.skills.length);

  double get avgCompetency {
    final all = skillCategories.expand((c) => c.skills).toList();
    if (all.isEmpty) return 0;
    return all.fold(0.0, (sum, s) => sum + s.proficiencyPercent) / all.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'userType': userType,
        'course': course,
        'yearLevel': yearLevel,
        'studentId': studentId,
        'address': address,
        'department': department,
        'avatarInitials': avatarInitials,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
        'skillCategories': skillCategories.map((c) => c.toJson()).toList(),
        'projects': projects.map((p) => p.toJson()).toList(),
        'certifications': certifications.map((c) => c.toJson()).toList(),
        'skillsPrivate': skillsPrivate,
        'projectsPrivate': projectsPrivate,
        'certificationsPrivate': certificationsPrivate,
        'experiencesPrivate': experiencesPrivate,
        'achievementsPrivate': achievementsPrivate,
        'careerObjectivePrivate': careerObjectivePrivate,
        'approvedViewers': approvedViewers,
        'profileViews': profileViews,
        'profileLikes': profileLikes,
        'likedBy': likedBy,
        'educationalAttainments':
            educationalAttainments.map((e) => e.toJson()).toList(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'careerObjective': careerObjective,
      };

  /// Firestore **new user** document: account/profile fields only. Portfolio data is
  /// stored in subcollections, not in the main user document.
  Map<String, dynamic> toFirestoreRegistrationMap() => {
        'achievementsPrivate': achievementsPrivate,
        'address': address,
        'approvedViewers': approvedViewers,
        'avatarInitials': avatarInitials,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'careerObjective': careerObjective,
        'careerObjectivePrivate': careerObjectivePrivate,
        'certificationsPrivate': certificationsPrivate,
        'course': course,
        'department': department,
        'email': email,
        'experiencesPrivate': experiencesPrivate,
        'facebookUrl': facebookUrl,
        'id': id,
        'instagramUrl': instagramUrl,
        'likedBy': likedBy,
        'name': name,
        'password': password,
        'phone': phone,
        'profileLikes': profileLikes,
        'profileViews': profileViews,
        'projectsPrivate': projectsPrivate,
        'skillsPrivate': skillsPrivate,
        'studentId': studentId,
        'userType': userType,
        'yearLevel': yearLevel,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      password: json['password']?.toString().trim() ?? '',
      userType: json['userType']?.toString() ?? 'Student',
      course: json['course']?.toString() ?? '',
      yearLevel: json['yearLevel']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      avatarInitials: json['avatarInitials']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      instagramUrl: json['instagramUrl']?.toString() ?? '',
      facebookUrl: json['facebookUrl']?.toString() ?? '',
      skillCategories: (json['skillCategories'] as List<dynamic>?)
              ?.map((e) => SkillCategory.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((e) => Project.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => Certification.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      educationalAttainments: (json['educationalAttainments'] as List<dynamic>?)
              ?.map((e) => EducationalAttainment.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => Experience.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList() ??
          [],
      careerObjective: json['careerObjective']?.toString() ?? '',
      skillsPrivate: json['skillsPrivate'] ?? false,
      projectsPrivate: json['projectsPrivate'] ?? false,
      certificationsPrivate: json['certificationsPrivate'] ?? false,
      experiencesPrivate: json['experiencesPrivate'] ?? false,
      achievementsPrivate: json['achievementsPrivate'] ?? false,
      careerObjectivePrivate: json['careerObjectivePrivate'] ?? false,
      approvedViewers: _parseStringList(json['approvedViewers']),
      profileViews: (json['profileViews'] as int?) ?? 0,
      profileLikes: (json['profileLikes'] as int?) ?? 0,
      likedBy: _parseStringList(json['likedBy']),
    );
  }
}

class SkillCategory {
  String id;
  String name;
  List<Skill> skills;

  SkillCategory({required this.id, required this.name, List<Skill>? skills})
      : skills = skills ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'skills': skills.map((s) => s.toJson()).toList(),
      };

  factory SkillCategory.fromJson(Map<String, dynamic> json) => SkillCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}

class Skill {
  String id;
  String name;
  String level; // Beginner, Intermediate, Advanced, Expert
  double proficiencyPercent;

  Skill({
    required this.id,
    required this.name,
    required this.level,
    required this.proficiencyPercent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'proficiencyPercent': proficiencyPercent,
      };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        level: json['level']?.toString() ?? '',
        proficiencyPercent:
            (json['proficiencyPercent'] as num?)?.toDouble() ?? 0.0,
      );
}

class Project {
  String id;
  String title;
  String description;
  String date;
  int memberCount;
  List<String> tags;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.memberCount,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date,
        'memberCount': memberCount,
        'tags': tags,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t.toString())
                .toList() ??
            <String>[],
      );
}

class EducationalAttainment {
  String id;
  String schoolName;
  String degree;
  String year;
  String address;

  EducationalAttainment({
    required this.id,
    required this.schoolName,
    required this.degree,
    required this.year,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'schoolName': schoolName,
        'degree': degree,
        'year': year,
        'address': address,
      };

  factory EducationalAttainment.fromJson(Map<String, dynamic> json) =>
      EducationalAttainment(
        id: json['id']?.toString() ?? '',
        schoolName: json['schoolName']?.toString() ?? '',
        degree: json['degree']?.toString() ?? '',
        year: json['year']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
      );
}

class Experience {
  String id;
  String company;
  String position;
  String startDate;
  String endDate;
  String description;

  Experience({
    required this.id,
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.description,
    required String title,
    required String dateRange,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'company': company,
        'position': position,
        'startDate': startDate,
        'endDate': endDate,
        'description': description,
      };

  factory Experience.fromJson(Map<String, dynamic> json) => Experience(
        id: json['id']?.toString() ?? '',
        company: json['company']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        title: '',
        dateRange: '',
      );
}

class Achievement {
  String id;
  String title;
  String description;
  String date;
  String category;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'date': date,
        'category': category,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
      );
}

class Certification {
  String id;
  String title;
  String issuer;
  String date;
  String certId;

  Certification({
    required this.id,
    required this.title,
    required this.issuer,
    required this.date,
    required this.certId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'issuer': issuer,
        'date': date,
        'certId': certId,
      };

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        issuer: json['issuer']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        certId: json['certId']?.toString() ?? '',
      );
}
