// lib/models/models.dart

class PermissionRequest {
  String id;
  String requesterId;
  String targetUserId;
  DateTime requestDate;
  String status; // 'pending', 'approved', 'denied'
  String? message;

  PermissionRequest({
    required this.id,
    required this.requesterId,
    required this.targetUserId,
    required this.requestDate,
    required this.status,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterId': requesterId,
      'targetUserId': targetUserId,
      'requestDate': requestDate.toIso8601String(),
      'status': status,
      'message': message,
    };
  }

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['id'],
      requesterId: json['requesterId'],
      targetUserId: json['targetUserId'],
      requestDate: DateTime.parse(json['requestDate']),
      status: json['status'],
      message: json['message'],
    );
  }
}

class UserAccount {
  String id;
  String name;
  String email;
  String phone;
  String password;
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

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.course,
    required this.yearLevel,
    required this.studentId,
    required this.location,
    required this.avatarInitials,
    this.avatarUrl = '',
    this.bio = '',
    this.instagramUrl = '',
    this.facebookUrl = '',
    this.skillsPrivate = false,
    this.projectsPrivate = false,
    this.certificationsPrivate = false,
    List<String>? approvedViewers,
    List<SkillCategory>? skillCategories,
    List<Project>? projects,
    List<Certification>? certifications,
  })  : skillCategories = skillCategories ?? [],
        projects = projects ?? [],
        certifications = certifications ?? [],
        approvedViewers = approvedViewers ?? [];

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
        'skillCategories': skillCategories.map((s) => s.toJson()).toList(),
        'projects': projects.map((p) => p.toJson()).toList(),
        'certifications': certifications.map((c) => c.toJson()).toList(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        password: json['password'] ?? '',
        course: json['course'],
        yearLevel: json['yearLevel'],
        studentId: json['studentId'],
        location: json['location'],
        avatarInitials: json['avatarInitials'],
        avatarUrl: json['avatarUrl'] ?? '',
        bio: json['bio'] ?? '',
        instagramUrl: json['instagramUrl'] ?? '',
        facebookUrl: json['facebookUrl'] ?? '',
        skillCategories: (json['skillCategories'] as List? ?? [])
            .map((s) => SkillCategory.fromJson(s))
            .toList(),
        projects: (json['projects'] as List? ?? [])
            .map((p) => Project.fromJson(p))
            .toList(),
        certifications: (json['certifications'] as List? ?? [])
            .map((c) => Certification.fromJson(c))
            .toList(),
      );
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
        skills: (json['skills'] as List? ?? [])
            .map((s) => Skill.fromJson(s))
            .toList(),
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
