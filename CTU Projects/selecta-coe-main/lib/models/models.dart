// lib/models/models.dart

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
  String location;
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
  List<String> approvedViewers; // User IDs that can view private data
  int profileViews;
  int profileLikes;
  List<String> likedBy; // List of user IDs who liked this profile

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
    this.location = '',
    this.avatarInitials = '',
    this.avatarUrl = '',
    this.bio = '',
    this.instagramUrl = '',
    this.facebookUrl = '',
    this.skillCategories = const [],
    this.projects = const [],
    this.certifications = const [],
    this.skillsPrivate = false,
    this.projectsPrivate = false,
    this.certificationsPrivate = false,
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
        'phone': phone,
        'password': password,
        'userType': userType,
        'course': course,
        'yearLevel': yearLevel,
        'studentId': studentId,
        'location': location,
        'avatarInitials': avatarInitials,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'instagramUrl': instagramUrl,
        'facebookUrl': facebookUrl,
        'skillsPrivate': skillsPrivate,
        'projectsPrivate': projectsPrivate,
        'certificationsPrivate': certificationsPrivate,
        'approvedViewers': approvedViewers,
        'profileViews': profileViews,
        'profileLikes': profileLikes,
        'likedBy': likedBy,
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      password: json['password'],
      userType: json['userType'] ?? 'Student',
      course: json['course'] ?? '',
      yearLevel: json['yearLevel'] ?? '',
      studentId: json['studentId'] ?? '',
      location: json['location'] ?? '',
      avatarInitials: json['avatarInitials'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      bio: json['bio'] ?? '',
      instagramUrl: json['instagramUrl'] ?? '',
      facebookUrl: json['facebookUrl'] ?? '',
      skillCategories: (json['skillCategories'] as List<dynamic>?)
              ?.map((e) => SkillCategory.fromJson(e))
              .toList() ??
          [],
      projects: (json['projects'] as List<dynamic>?)
              ?.map((e) => Project.fromJson(e))
              .toList() ??
          [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => Certification.fromJson(e))
              .toList() ??
          [],
      skillsPrivate: json['skillsPrivate'] ?? false,
      projectsPrivate: json['projectsPrivate'] ?? false,
      certificationsPrivate: json['certificationsPrivate'] ?? false,
      approvedViewers: (json['approvedViewers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      profileViews: (json['profileViews'] as int?) ?? 0,
      profileLikes: (json['profileLikes'] as int?) ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
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
        id: json['id'],
        name: json['name'],
        skills: (json['skills'] as List<dynamic>?)
                ?.map((e) => Skill.fromJson(e))
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
        id: json['id'],
        name: json['name'],
        level: json['level'],
        proficiencyPercent: (json['proficiencyPercent'] as num).toDouble(),
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
        id: json['id'],
        title: json['title'],
        description: json['description'],
        date: json['date'],
        memberCount: json['memberCount'],
        tags: List<String>.from(json['tags'] ?? []),
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
        id: json['id'],
        title: json['title'],
        issuer: json['issuer'],
        date: json['date'],
        certId: json['certId'],
      );
}
