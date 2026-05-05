// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../screens/profile_screen.dart';
import '../theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _filter = 'All'; // All, Users, Skills, Projects, Certifications
  String _sort = 'Name'; // Name, Type, User

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _results {
    var all = AppStore().search(_query);
    // Filter by type
    if (_filter != 'All') {
      final typeMap = {
        'Users': 'profile',
        'Skills': 'skill',
        'Projects': 'project',
        'Certifications': 'certification',
      };
      final type = typeMap[_filter] ?? _filter.toLowerCase();
      all = all.where((r) => (r['type'] as String) == type).toList();
    }
    // Sort
    all.sort((a, b) {
      if (_sort == 'Type') {
        return (a['type'] as String).compareTo(b['type'] as String);
      } else if (_sort == 'User') {
        return (a['user'] as String).compareTo(b['user'] as String);
      }
      return (a['name'] as String).compareTo(b['name'] as String);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Container(
      color: AppTheme.surfaceVariant,
      child: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users, skills, projects, certifications...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon:
                    const Icon(Icons.search, size: 20, color: Colors.white54),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.white54),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filters
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // Type filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Users',
                        'Skills',
                        'Projects',
                        'Certifications'
                      ]
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(f),
                                  selected: _filter == f,
                                  onSelected: (_) =>
                                      setState(() => _filter = f),
                                  selectedColor:
                                      AppTheme.primary.withOpacity(0.12),
                                  checkmarkColor: AppTheme.primary,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: _filter == f
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                    fontWeight: _filter == f
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                // Sort dropdown
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() => _sort = v),
                  itemBuilder: (_) => ['Name', 'Type', 'User']
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                if (_sort == s)
                                  const Icon(Icons.check,
                                      size: 16, color: AppTheme.primary)
                                else
                                  const SizedBox(width: 16),
                                const SizedBox(width: 8),
                                Text(s),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(_sort,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Text(
                  '${results.length} result${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Results list
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off,
                            size: 40, color: AppTheme.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          _query.isEmpty
                              ? 'Nothing in the database yet.'
                              : 'No results for "$_query"',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _showRecordDetails(context, results[i]),
                        child: _ResultTile(record: results[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> record;
  const _ResultTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final type = record['type'] as String;
    final name = record['name'] as String? ?? '';
    final user = record['user'] as String? ?? '';

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (type) {
      case 'skill':
        typeColor = AppTheme.primary;
        typeIcon = Icons.workspace_premium_outlined;
        typeLabel = 'Skill';
        break;
      case 'project':
        typeColor = AppTheme.warning;
        typeIcon = Icons.folder_outlined;
        typeLabel = 'Project';
        break;
      case 'profile':
        typeColor = AppTheme.accent;
        typeIcon = Icons.person_outline;
        typeLabel = 'Student';
        break;
      default:
        typeColor = const Color(0xFFF97316);
        typeIcon = Icons.military_tech_outlined;
        typeLabel = 'Certification';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(typeIcon, size: 18, color: typeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                _subtitle(record),
                const SizedBox(height: 3),
                Text('by $user',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(typeLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: typeColor,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _subtitle(Map<String, dynamic> r) {
    final type = r['type'];
    if (type == 'skill') {
      final pct = (r['percent'] as num?)?.toInt() ?? 0;
      return Row(
        children: [
          Text('${r['category'] ?? ''} • ${r['level'] ?? ''}  $pct%',
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      );
    } else if (type == 'project') {
      final tags = (r['tags'] as List? ?? []).take(3).join(', ');
      return Text(tags,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary));
    } else if (type == 'profile') {
      return Text('${r['course'] ?? ''} • ${r['yearLevel'] ?? ''}',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary));
    } else {
      return Text(r['issuer'] ?? '',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary));
    }
  }
}

void _showRecordDetails(BuildContext context, Map<String, dynamic> record) {
  final type = record['type'] as String;
  final name = record['name'] as String? ?? '';
  final user = record['user'] as String? ?? '';
  final description = type == 'skill'
      ? '${record['category'] ?? ''} • ${record['level'] ?? ''}'
      : type == 'project'
          ? record['description'] ?? ''
          : type == 'certification'
              ? 'Issued by ${record['issuer'] ?? ''}'
              : record['bio'] ?? '';

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surfaceVariant,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('by $user',
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            if (type == 'profile') ...[
              Text('Course: ${record['course'] ?? ''}',
                  style: const TextStyle(color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Year Level: ${record['yearLevel'] ?? ''}',
                  style: const TextStyle(color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Student ID: ${record['studentId'] ?? ''}',
                  style: const TextStyle(color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text('Location: ${record['location'] ?? ''}',
                  style: const TextStyle(color: AppTheme.textPrimary)),
              if ((record['bio'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                const Text('Bio',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(record['bio'] as String,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ]
            ] else ...[
              Text(description,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 12),
              if (type == 'skill')
                Text('Skill percent: ${record['percent']?.toInt() ?? 0}%',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      if (type == 'profile') {
                        // ── Wrap in Scaffold so the profile renders correctly ──
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => Scaffold(
                            backgroundColor: AppTheme.surfaceVariant,
                            appBar: AppBar(
                              backgroundColor: AppTheme.primary,
                              elevation: 0,
                              leading: const BackButton(color: Colors.white),
                              title: Text(
                                record['name'] as String? ?? 'Profile',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            body: ProfileScreen(
                              userId: record['userId'] as String,
                              viewOnly: true,
                            ),
                          ),
                        ));
                      }
                    },
                    child: Text(type == 'profile' ? 'View Profile' : 'Close'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}
