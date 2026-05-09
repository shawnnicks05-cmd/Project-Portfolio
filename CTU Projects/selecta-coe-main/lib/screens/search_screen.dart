// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../screens/profile_screen.dart';
import '../theme.dart';
import '../widgets/pill_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _filter = 'All'; // All, Users, Skills, Projects, Certifications, ...
  String _sort = 'Name'; // Name, Type, User

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> get _results async {
    var all = await AppStore().search(_query);
    // Filter by type
    if (_filter != 'All') {
      final typeMap = {
        'Users': 'profile',
        'Skills': 'skill',
        'Projects': 'project',
        'Certifications': 'certification',
        'Education': 'education',
        'Experience': 'experience',
        'Achievements': 'achievement',
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
    return Scaffold(
      appBar: PillHeader(
        title: 'Search',
        leadingIcon: Icons.search,
        onLeadingTap: null,
        actions: const [Icon(Icons.more_vert)],
      ),
      body: Container(
        color: AppTheme.getSurfaceVariant(context),
        child: Column(
          children: [
          // Search bar
          Container(
            color: AppTheme.getSurface(context),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: AppTheme.getTextPrimary(context)),
              decoration: InputDecoration(
                hintText: 'Search users, skills, projects, certifications...',
                hintStyle: TextStyle(color: AppTheme.getTextMuted(context)),
                prefixIcon: Icon(
                      Icons.search, 
                      size: 20,
                      color: AppTheme.getTextMuted(context),
                    ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            size: 18,
                            color: AppTheme.getTextMuted(context)),
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
            color: AppTheme.getSurface(context),
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
                        'Certifications',
                        'Education',
                        'Experience',
                        'Achievements',
                      ]
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  label: Text(f),
                                  selected: _filter == f,
                                  onSelected: (_) =>
                                      setState(() => _filter = f),
                                  selectedColor:
                                      AppTheme.getPrimary(context).withOpacity(0.12),
                                  checkmarkColor: AppTheme.getPrimary(context),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: _filter == f
                                        ? AppTheme.getPrimary(context)
                                        : AppTheme.getTextSecondary(context),
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
                                  Icon(Icons.check,
                                      size: 16, color: AppTheme.getPrimary(context))
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
                      border: Border.all(color: AppTheme.getBorder(context)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort,
                            size: 14, color: AppTheme.getTextSecondary(context)),
                        const SizedBox(width: 4),
                        Text(_sort,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.getTextSecondary(context))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Results count and list
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final results = snapshot.data ?? [];

                return Column(
                  children: [
                    // Results count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Row(
                        children: [
                          Text(
                            '${results.length} result${results.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.getTextMuted(context),
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
                                  Icon(Icons.search_off,
                                      size: 40, color: AppTheme.getTextMuted(context)),
                                  const SizedBox(height: 10),
                                  Text(
                                    _query.isEmpty
                                        ? 'Nothing in the database yet.'
                                        : 'No results for "$_query"',
                                    style: TextStyle(
                                        color: AppTheme.getTextMuted(context),
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) => GestureDetector(
                                  onTap: () =>
                                      _showRecordDetails(context, results[i]),
                                  child: _ResultTile(record: results[i])),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
        ),
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
        typeColor = AppTheme.getPrimary(context);
        typeIcon = Icons.workspace_premium_outlined;
        typeLabel = 'Skill';
        break;
      case 'project':
        typeColor = AppTheme.getWarning(context);
        typeIcon = Icons.folder_outlined;
        typeLabel = 'Project';
        break;
      case 'education':
        typeColor = AppTheme.getPrimary(context);
        typeIcon = Icons.school_outlined;
        typeLabel = 'Education';
        break;
      case 'experience':
        typeColor = AppTheme.getSuccess(context);
        typeIcon = Icons.work_outline;
        typeLabel = 'Experience';
        break;
      case 'achievement':
        typeColor = const Color(0xFFF97316);
        typeIcon = Icons.emoji_events_outlined;
        typeLabel = 'Achievement';
        break;
      case 'profile':
        typeColor = AppTheme.getAccent(context);
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
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorder(context)),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.getTextPrimary(context))),
                const SizedBox(height: 2),
                _subtitle(context, record),
                const SizedBox(height: 3),
                Text('by $user',
                    style: TextStyle(fontSize: 11, color: AppTheme.getTextMuted(context))),
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

  Widget _subtitle(BuildContext context, Map<String, dynamic> r) {
    final type = r['type'];
    if (type == 'skill') {
      final pct = (r['percent'] as num?)?.toInt() ?? 0;
      return Row(
        children: [
          Text('${r['category'] ?? ''} • ${r['level'] ?? ''}  $pct%',
              style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context))),
        ],
      );
    } else if (type == 'project') {
      final tags = (r['tags'] as List? ?? []).take(3).join(', ');
      return Text(tags,
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)));
    } else if (type == 'profile') {
      return Text('${r['course'] ?? ''} • ${r['yearLevel'] ?? ''}',
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)));
    } else if (type == 'education') {
      final degree = (r['degree'] as String?) ?? '';
      final year = (r['year'] as String?) ?? '';
      final text = [degree, year].where((s) => s.trim().isNotEmpty).join(' • ');
      return Text(text,
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)));
    } else if (type == 'experience') {
      final company = (r['company'] as String?) ?? '';
      return Text(company,
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)));
    } else if (type == 'achievement') {
      final cat = (r['category'] as String?) ?? '';
      return Text(cat,
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)));
    } else {
      return Text(r['issuer'] ?? '',
          style: TextStyle(fontSize: 11, color: AppTheme.getTextSecondary(context)));
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
              : type == 'education'
                  ? '${record['degree'] ?? ''} ${record['year'] ?? ''}'.trim()
                  : type == 'experience'
                      ? '${record['company'] ?? ''} • ${record['startDate'] ?? ''}-${record['endDate'] ?? ''}'
                      : type == 'achievement'
                          ? '${record['category'] ?? ''} • ${record['date'] ?? ''}'
              : record['bio'] ?? '';

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
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
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('by $user',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 16),
            if (type == 'profile') ...[
              Text('Course: ${record['course'] ?? ''}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Year Level: ${record['yearLevel'] ?? ''}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Student ID: ${record['studentId'] ?? ''}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Location: ${record['location'] ?? ''}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              if ((record['bio'] as String?)?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text('Bio',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(record['bio'] as String,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 14)),
              ]
            ] else ...[
              Text(description,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 12),
              if (type == 'skill')
                Text('Skill percent: ${record['percent']?.toInt() ?? 0}%',
                    style:
                        TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
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
                            backgroundColor: AppTheme.getSurfaceVariant(context),
                            appBar: PillHeader(
                              title: record['name'] as String? ?? 'Profile',
                              leadingIcon: Icons.arrow_back,
                              onLeadingTap: () => Navigator.of(context).pop(),
                              actions: const [Icon(Icons.more_vert)],
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
