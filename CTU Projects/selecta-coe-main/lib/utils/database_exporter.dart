// lib/utils/database_exporter.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../data/database_helper.dart';
import '../models/models.dart';

class DatabaseExporter {
  static Future<void> exportUserAccount(UserAccount user) async {
    try {
      // Use app's internal directory (no permissions needed)
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${appDir.path}/SELECTA_COE_Exports');
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final cleanName = user.name.replaceAll(RegExp(r'[^\w\s-]'), '_');
      final filename = 'Account_${cleanName}_$timestamp.txt';
      final file = File('${directory.path}/$filename');

      // Get database helper and all data
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // Get all users
      final allUsers = await dbHelper.getAllUsers();
      
      // Get all skills, projects, certifications for this user
      final userSkills = await db.query(
        'skills',
        where: 'userId = ?',
        whereArgs: [user.id],
      );
      
      final userProjects = await db.query(
        'projects',
        where: 'userId = ?',
        whereArgs: [user.id],
      );
      
      final userCertifications = await db.query(
        'certifications',
        where: 'userId = ?',
        whereArgs: [user.id],
      );

      // Create export content
      final content = _generateExportContent(
        user: user,
        allUsers: allUsers,
        userSkills: userSkills,
        userProjects: userProjects,
        userCertifications: userCertifications,
      );

      // Write to file
      await file.writeAsString(content);
      
      print('✅ Account exported to: ${file.path}');
      print('📁 Directory: ${directory.path}');
      
    } catch (e) {
      print('❌ Error exporting account: $e');
      print('📍 Stack trace: ${StackTrace.current}');
    }
  }

  static String _generateExportContent({
    required UserAccount user,
    required List<UserAccount> allUsers,
    required List<Map<String, dynamic>> userSkills,
    required List<Map<String, dynamic>> userProjects,
    required List<Map<String, dynamic>> userCertifications,
  }) {
    final buffer = StringBuffer();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    buffer.writeln('=' * 60);
    buffer.writeln('SELECTA-COE STUDENT ELECTRONIC TRACKER');
    buffer.writeln('ACCOUNT CREATION EXPORT REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln('Generated: $timestamp');
    buffer.writeln();

    // New Account Information
    buffer.writeln('📋 NEW ACCOUNT CREATED');
    buffer.writeln('-' * 40);
    buffer.writeln('ID: ${user.id}');
    buffer.writeln('Name: ${user.name}');
    buffer.writeln('Email: ${user.email}');
    buffer.writeln('Phone: ${user.phone}');
    buffer.writeln('Course: ${user.course}');
    buffer.writeln('Year Level: ${user.yearLevel}');
    buffer.writeln('Student ID: ${user.studentId}');
    buffer.writeln('Location: ${user.location}');
    buffer.writeln('Avatar Initials: ${user.avatarInitials}');
    buffer.writeln('Bio: ${user.bio}');
    buffer.writeln();

    // Database Overview
    buffer.writeln('🗄️ DATABASE OVERVIEW');
    buffer.writeln('-' * 40);
    buffer.writeln('Database Name: selecta_coe.db');
    buffer.writeln('Database Version: 1');
    buffer.writeln('Total Users: ${allUsers.length}');
    buffer.writeln();

    // All Users Summary
    buffer.writeln('👥 ALL USERS IN DATABASE');
    buffer.writeln('-' * 40);
    for (int i = 0; i < allUsers.length; i++) {
      final u = allUsers[i];
      buffer.writeln('${i + 1}. ${u.name} (${u.email})');
      buffer.writeln('   Course: ${u.course}');
      buffer.writeln('   Year: ${u.yearLevel}');
      buffer.writeln('   Student ID: ${u.studentId}');
      buffer.writeln();
    }

    // New User's Skills
    if (userSkills.isNotEmpty) {
      buffer.writeln('🎯 SKILLS FOR ${user.name.toUpperCase()}');
      buffer.writeln('-' * 40);
      for (int i = 0; i < userSkills.length; i++) {
        final skill = userSkills[i];
        buffer.writeln('${i + 1}. ${skill['title']}');
        buffer.writeln('   Category: ${skill['category']}');
        buffer.writeln('   Level: ${skill['level']}');
        buffer.writeln('   Description: ${skill['description'] ?? 'N/A'}');
        buffer.writeln();
      }
    }

    // New User's Projects
    if (userProjects.isNotEmpty) {
      buffer.writeln('📁 PROJECTS FOR ${user.name.toUpperCase()}');
      buffer.writeln('-' * 40);
      for (int i = 0; i < userProjects.length; i++) {
        final project = userProjects[i];
        buffer.writeln('${i + 1}. ${project['title']}');
        buffer.writeln('   Description: ${project['description'] ?? 'N/A'}');
        buffer.writeln('   Status: ${project['status'] ?? 'N/A'}');
        buffer.writeln('   Start Date: ${project['startDate'] ?? 'N/A'}');
        buffer.writeln('   End Date: ${project['endDate'] ?? 'N/A'}');
        buffer.writeln();
      }
    }

    // New User's Certifications
    if (userCertifications.isNotEmpty) {
      buffer.writeln('🏆 CERTIFICATIONS FOR ${user.name.toUpperCase()}');
      buffer.writeln('-' * 40);
      for (int i = 0; i < userCertifications.length; i++) {
        final cert = userCertifications[i];
        buffer.writeln('${i + 1}. ${cert['title']}');
        buffer.writeln('   Issuer: ${cert['issuer']}');
        buffer.writeln('   Date: ${cert['date']}');
        buffer.writeln('   Certificate ID: ${cert['certId']}');
        buffer.writeln();
      }
    }

    // Database Schema
    buffer.writeln('🔧 DATABASE SCHEMA');
    buffer.writeln('-' * 40);
    buffer.writeln('Table: users');
    buffer.writeln('  - id (TEXT PRIMARY KEY)');
    buffer.writeln('  - name (TEXT NOT NULL)');
    buffer.writeln('  - email (TEXT UNIQUE NOT NULL)');
    buffer.writeln('  - phone (TEXT)');
    buffer.writeln('  - password (TEXT NOT NULL)');
    buffer.writeln('  - course (TEXT)');
    buffer.writeln('  - yearLevel (TEXT)');
    buffer.writeln('  - studentId (TEXT)');
    buffer.writeln('  - location (TEXT)');
    buffer.writeln('  - avatarInitials (TEXT)');
    buffer.writeln('  - bio (TEXT)');
    buffer.writeln();
    buffer.writeln('Table: skills');
    buffer.writeln('  - id (TEXT PRIMARY KEY)');
    buffer.writeln('  - userId (TEXT)');
    buffer.writeln('  - title (TEXT)');
    buffer.writeln('  - category (TEXT)');
    buffer.writeln('  - level (TEXT)');
    buffer.writeln('  - description (TEXT)');
    buffer.writeln();
    buffer.writeln('Table: projects');
    buffer.writeln('  - id (TEXT PRIMARY KEY)');
    buffer.writeln('  - userId (TEXT)');
    buffer.writeln('  - title (TEXT)');
    buffer.writeln('  - description (TEXT)');
    buffer.writeln('  - status (TEXT)');
    buffer.writeln('  - startDate (TEXT)');
    buffer.writeln('  - endDate (TEXT)');
    buffer.writeln();
    buffer.writeln('Table: certifications');
    buffer.writeln('  - id (TEXT PRIMARY KEY)');
    buffer.writeln('  - userId (TEXT)');
    buffer.writeln('  - title (TEXT)');
    buffer.writeln('  - issuer (TEXT)');
    buffer.writeln('  - date (TEXT)');
    buffer.writeln('  - certId (TEXT)');

    buffer.writeln();
    buffer.writeln('=' * 60);
    buffer.writeln('END OF EXPORT REPORT');
    buffer.writeln('=' * 60);

    return buffer.toString();
  }
}
