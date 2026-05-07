// lib/utils/database_debug.dart
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/database_helper.dart';

class DatabaseDebug extends StatelessWidget {
  const DatabaseDebug({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
      ),
      body: FutureBuilder<String>(
        future: _getDatabasePath(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final path = snapshot.data ?? 'Unknown';
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Database Location:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(path),
                const SizedBox(height: 16),
                const Text(
                  'Instructions:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('1. Copy this path'),
                const Text('2. Open Android Studio Device File Explorer'),
                const Text('3. Navigate to this path'),
                const Text('4. Look for selecta_coe.db file'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final dbHelper = DatabaseHelper();
                      final db = await dbHelper.database;
                      final tables = await db.rawQuery(
                          "SELECT name FROM sqlite_master WHERE type='table'");
                      print('Tables: $tables');
                      await db.close();
                    } catch (e) {
                      print('Database access error: $e');
                    }
                  },
                  child: const Text('Test Database Access'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<String> _getDatabasePath() async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'selecta_coe.db');
  }
}
