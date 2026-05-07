// lib/utils/database_viewer.dart
import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class DatabaseViewer extends StatefulWidget {
  const DatabaseViewer({super.key});

  @override
  State<DatabaseViewer> createState() => _DatabaseViewerState();
}

class _DatabaseViewerState extends State<DatabaseViewer> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final dbHelper = DatabaseHelper();
    final users = await dbHelper.getAllUsers();
    setState(() {
      _users = users.map((user) => user.toJson()).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: Text(user['email'] ?? 'No email'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${user['id']}'),
                            Text('Phone: ${user['phone']}'),
                            Text('Course: ${user['course']}'),
                            Text('Year Level: ${user['yearLevel']}'),
                            Text('Student ID: ${user['studentId']}'),
                            Text('Location: ${user['location']}'),
                            const SizedBox(height: 8),
                            const Text('Bio:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(user['bio'] ?? 'No bio'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
