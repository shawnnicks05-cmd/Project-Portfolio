import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'lib/data/database_helper.dart';

void main() async {
  print('Testing database schema fix...');
  
  try {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
    // Get table info
    final tableInfo = await db.rawQuery("PRAGMA table_info(${DatabaseHelper.usersTable})");
    
    print('\nUsers table columns:');
    for (final column in tableInfo) {
      print('  ${column['name']}: ${column['type']}');
    }
    
    // Check if experiencesPrivate column exists
    final hasExperiencesPrivate = tableInfo.any((col) => col['name'] == 'experiencesPrivate');
    final hasAchievementsPrivate = tableInfo.any((col) => col['name'] == 'achievementsPrivate');
    final hasCareerObjectivePrivate = tableInfo.any((col) => col['name'] == 'careerObjectivePrivate');
    
    print('\nSchema check results:');
    print('  experiencesPrivate column exists: $hasExperiencesPrivate');
    print('  achievementsPrivate column exists: $hasAchievementsPrivate');
    print('  careerObjectivePrivate column exists: $hasCareerObjectivePrivate');
    
    if (hasExperiencesPrivate && hasAchievementsPrivate && hasCareerObjectivePrivate) {
      print('\n✅ All required privacy columns are present!');
      print('The database schema fix should resolve the insertion error.');
    } else {
      print('\n❌ Some privacy columns are missing.');
      print('The database upgrade may not have run correctly.');
    }
    
    await db.close();
    
  } catch (e) {
    print('Error testing database: $e');
  }
}
