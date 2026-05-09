// lib/screens/database_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';

// ─── Shared theme-aware dialog helpers ───────────────────────────────────────────────

Color _getDialogBg(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? const Color(0xFF1E2530)
      : const Color(0xFFF8FAFC);
}

Color _getTextColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
}

Color _getSubTextColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.white70
      : Colors.grey.shade800;
}

Color _getTextMuted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.white54
      : Colors.grey.shade600;
}

Color _getBorder(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.white24
      : Colors.grey.shade300;
}

InputDecoration _darkInput(String hint, BuildContext context) =>
    InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
    );

InputDecoration _darkLabelInput(String label, BuildContext context) =>
    InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
    );

const int _maxSummaryItems = 15;

void _showLimitReached(BuildContext context, String sectionName) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Maximum of $_maxSummaryItems items allowed for $sectionName.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class DatabaseScreen extends StatefulWidget {
  const DatabaseScreen({super.key});

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tab,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: AppTheme.getTextSecondary(context),
            indicatorColor: AppTheme.primary,
            tabs: const [
              Tab(text: 'Skills'),
              Tab(text: 'Projects'),
              Tab(text: 'Certifications'),
              Tab(text: 'Education'),
              Tab(text: 'Experience'),
              Tab(text: 'Achievements'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _SkillsTab(),
              _ProjectsTab(),
              _CertificationsTab(),
              _EducationTab(),
              _ExperienceTab(),
              _AchievementsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Skills Tab ───────────────────────────────────────────────────────────────

class _SkillsTab extends StatefulWidget {
  const _SkillsTab();

  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = AppStore().currentUser!;
    return Stack(
      children: [
        user.skillCategories.isEmpty
            ? const _EmptyState(
                icon: Icons.workspace_premium_outlined,
                message: 'No skills yet.\nAdd a category to get started.')
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: user.skillCategories
                    .map((cat) =>
                        _CategoryCard(category: cat, onChanged: _refresh))
                    .toList(),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (user.skillCategories.length >= _maxSummaryItems) {
                _showLimitReached(context, 'Skills');
                return;
              }
              _showAddCategoryDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final ctrl = TextEditingController();
    bool isSubmitting = false;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setSt) => AlertDialog(
          backgroundColor: _getDialogBg(context),
          title: Text(
            'New Skill Category',
            style: TextStyle(
                color: _getTextColor(context), fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: TextStyle(color: _getTextColor(context)),
            decoration: _darkInput('e.g. Programming Languages', context),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      if (AppStore().currentUser!.skillCategories.length >=
                          _maxSummaryItems) {
                        _showLimitReached(context, 'Skills');
                        return;
                      }
                      setSt(() => isSubmitting = true);
                      await AppStore().addSkillCategory(SkillCategory(
                        id: const Uuid().v4(),
                        name: ctrl.text.trim(),
                      ));
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      setState(() {});
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final SkillCategory category;
  final VoidCallback onChanged;
  const _CategoryCard({required this.category, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _getTextColor(context)),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  onPressed: () {
                    if (category.skills.length >= _maxSummaryItems) {
                      _showLimitReached(context, 'Skills');
                      return;
                    }
                    _showAddSkillDialog(context);
                  },
                  tooltip: 'Add skill',
                ),
              ],
            ),
          ),
          if (category.skills.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text('No skills yet — tap + to add one.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontStyle: FontStyle.italic)),
            )
          else
            ...category.skills.map((skill) => _SkillTile(
                  skill: skill,
                  catId: category.id,
                  onChanged: onChanged,
                )),
        ],
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String level = 'Intermediate';
    double percent = 50;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: _getDialogBg(context),
          title: Text(
            'Add Skill',
            style: TextStyle(
                color: _getTextColor(context), fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkLabelInput('Skill name', context),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: level,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: _darkLabelInput('Proficiency Level', context),
                items: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setSt(() => level = v!),
              ),
              const SizedBox(height: 14),
              Text('Proficiency: ${percent.round()}%',
                  style: TextStyle(
                      fontSize: 13, color: _getSubTextColor(context))),
              Slider(
                value: percent,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setSt(() => percent = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      if (category.skills.length >= _maxSummaryItems) {
                        _showLimitReached(context, 'Skills');
                        return;
                      }
                      setSt(() => isSubmitting = true);
                      await AppStore().addSkillToCategory(
                        category.id,
                        Skill(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          level: level,
                          proficiencyPercent: percent,
                        ),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      onChanged();
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        );
      }),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final Skill skill;
  final String catId;
  final VoidCallback onChanged;
  const _SkillTile(
      {required this.skill, required this.catId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(skill.name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(skill.level,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  await AppStore().removeSkill(catId, skill.id);
                  onChanged();
                },
                child: Icon(Icons.close,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: skill.proficiencyPercent / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${skill.proficiencyPercent.round()}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Projects Tab ─────────────────────────────────────────────────────────────

class _ProjectsTab extends StatefulWidget {
  const _ProjectsTab();

  @override
  State<_ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<_ProjectsTab> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = AppStore().currentUser!;
    return Stack(
      children: [
        user.projects.isEmpty
            ? const _EmptyState(
                icon: Icons.folder_outlined, message: 'No projects yet.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: user.projects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ProjectTile(
                    project: user.projects[i], onChanged: _refresh),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (user.projects.length >= _maxSummaryItems) {
                _showLimitReached(context, 'Projects');
                return;
              }
              _showAddDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Project'),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    int members = 1;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: _getDialogBg(context),
          title: Text(
            'Add Project',
            style: TextStyle(
                color: _getTextColor(context), fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Project title', context),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Description', context),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateCtrl,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Date (e.g. Jan 2026)', context),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagsCtrl,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Tags (space separated)', context),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Text('Members: ',
                      style: TextStyle(
                          fontSize: 13, color: _getSubTextColor(context))),
                  IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: _getSubTextColor(context)),
                      onPressed: () =>
                          setSt(() => members = (members - 1).clamp(1, 50))),
                  Text('$members',
                      style: TextStyle(
                          color: _getTextColor(context),
                          fontWeight: FontWeight.w600)),
                  IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: _getSubTextColor(context)),
                      onPressed: () => setSt(() => members++)),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      if (AppStore().currentUser!.projects.length >=
                          _maxSummaryItems) {
                        _showLimitReached(context, 'Projects');
                        return;
                      }
                      setSt(() => isSubmitting = true);
                      final tags = tagsCtrl.text
                          .split(' ')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      await AppStore().addProject(Project(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        date: dateCtrl.text.trim(),
                        memberCount: members,
                        tags: tags,
                      ));
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _refresh();
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        );
      }),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  final VoidCallback onChanged;
  const _ProjectTile({required this.project, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(project.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _getTextColor(context))),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: AppTheme.danger),
                onPressed: () async {
                  await AppStore().removeProject(project.id);
                  onChanged();
                },
              ),
            ],
          ),
          if (project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(project.description,
                style: TextStyle(
                    fontSize: 12, color: _getTextColor(context), height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: project.tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 11, color: _getTextColor(context))),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Education Tab ───────────────────────────────────────────────────────────────

class _EducationTab extends StatefulWidget {
  const _EducationTab();

  @override
  State<_EducationTab> createState() => _EducationTabState();
}

class _EducationTabState extends State<_EducationTab> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = AppStore().currentUser!;
    return Stack(
      children: [
        user.educationalAttainments.isEmpty
            ? const _EmptyState(
                icon: Icons.school_outlined,
                message:
                    'No education yet.\nAdd your education to get started.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: user.educationalAttainments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _EducationTile(
                    education: user.educationalAttainments[i],
                    onChanged: _refresh),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (user.educationalAttainments.length >= _maxSummaryItems) {
                _showLimitReached(context, 'Education');
                return;
              }
              _showAddDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Education'),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final schoolCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setSt) => AlertDialog(
          backgroundColor: _getDialogBg(context),
          title: Text(
            'Add Education',
            style: TextStyle(
                color: _getTextColor(context), fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: schoolCtrl,
                  autofocus: true,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('School Name', context),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: degreeCtrl,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Degree', context),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: yearCtrl,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Year', context),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: addressCtrl,
                  textAlign: TextAlign.left,
                  style: TextStyle(color: _getTextColor(context)),
                  decoration: _darkInput('Address', context),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (schoolCtrl.text.isEmpty) return;
                      if (AppStore().currentUser!.educationalAttainments.length >=
                          _maxSummaryItems) {
                        _showLimitReached(context, 'Education');
                        return;
                      }
                      setSt(() => isSubmitting = true);
                      final education = EducationalAttainment(
                        id: const Uuid().v4(),
                        schoolName: schoolCtrl.text.trim(),
                        degree: degreeCtrl.text.trim(),
                        year: yearCtrl.text.trim(),
                        address: addressCtrl.text.trim(),
                      );
                      await AppStore().addEducationalAttainment(education);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _refresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Education added successfully')),
                      );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Education Tile Widget ───────────────────────────────────────────────────────

class _EducationTile extends StatelessWidget {
  final EducationalAttainment education;
  final VoidCallback onChanged;

  const _EducationTile({required this.education, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(education.schoolName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _getTextColor(context))),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: AppTheme.primary, size: 20),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit education',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'Delete education',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (education.degree.isNotEmpty) ...[
                  Text('Degree',
                      style:
                          TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  SizedBox(
                      width: double.infinity,
                      child: Text(education.degree,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary))),
                  const SizedBox(height: 8),
                ],
                if (education.year.isNotEmpty) ...[
                  Text('Year',
                      style:
                          TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  SizedBox(
                      width: double.infinity,
                      child: Text(education.year,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary))),
                  const SizedBox(height: 8),
                ],
                if (education.address.isNotEmpty) ...[
                  Text('Address',
                      style:
                          TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  SizedBox(
                      width: double.infinity,
                      child: Text(education.address,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final schoolCtrl = TextEditingController(text: education.schoolName);
    final degreeCtrl = TextEditingController(text: education.degree);
    final yearCtrl = TextEditingController(text: education.year);
    final addressCtrl = TextEditingController(text: education.address);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setSt) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Edit Education',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: schoolCtrl,
                autofocus: true,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('School Name', context),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: degreeCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Degree', context),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: yearCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Year', context),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Address', context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
              if (schoolCtrl.text.isNotEmpty) {
                setSt(() => isSubmitting = true);
                final updatedEducation = EducationalAttainment(
                  id: education.id,
                  schoolName: schoolCtrl.text.trim(),
                  degree: degreeCtrl.text.trim(),
                  year: yearCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                );
                await AppStore().updateEducationalAttainment(updatedEducation);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                onChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Education updated successfully')),
                );
              }
            },
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Delete Education',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this education record?',
          style: TextStyle(color: _getSubTextColor(context)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await AppStore().removeEducationalAttainment(education.id);
              Navigator.pop(context);
              onChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Education deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Certifications Tab ───────────────────────────────────────────────────────

class _CertificationsTab extends StatefulWidget {
  const _CertificationsTab();

  @override
  State<_CertificationsTab> createState() => _CertificationsTabState();
}

class _CertificationsTabState extends State<_CertificationsTab> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final user = AppStore().currentUser!;
    return Stack(
      children: [
        user.certifications.isEmpty
            ? const _EmptyState(
                icon: Icons.military_tech_outlined,
                message: 'No certifications yet.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: user.certifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _CertTile(
                    cert: user.certifications[i], onChanged: _refresh),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (user.certifications.length >= _maxSummaryItems) {
                _showLimitReached(context, 'Certifications');
                return;
              }
              _showAddDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Certification'),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setSt) => AlertDialog(
          backgroundColor: _getDialogBg(context),
          title: Text(
            'Add Certification',
            style: TextStyle(
                color: _getTextColor(context), fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Certification title', context),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: issuerCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Issuing organization', context),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Date (e.g. March 2026)', context),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: idCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: _darkInput('Certification ID', context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      if (AppStore().currentUser!.certifications.length >=
                          _maxSummaryItems) {
                        _showLimitReached(context, 'Certifications');
                        return;
                      }
                      setSt(() => isSubmitting = true);
                      await AppStore().addCertification(Certification(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        issuer: issuerCtrl.text.trim(),
                        date: dateCtrl.text.trim(),
                        certId: idCtrl.text.trim(),
                      ));
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _refresh();
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  final Certification cert;
  final VoidCallback onChanged;
  const _CertTile({required this.cert, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.military_tech,
                size: 20, color: Color(0xFFF97316)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cert.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _getTextColor(context))),
                Text(cert.issuer,
                    style:
                        TextStyle(fontSize: 11, color: _getTextColor(context))),
                Text('${cert.date}  •  ${cert.certId}',
                    style:
                        TextStyle(fontSize: 10, color: _getTextMuted(context))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
            onPressed: () async {
              await AppStore().removeCertification(cert.id);
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppTheme.getTextMuted(context)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _getTextMuted(context), fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Experience Tab ─────────────────────────────────────────────────────────────

class _ExperienceTab extends StatefulWidget {
  const _ExperienceTab();

  @override
  State<_ExperienceTab> createState() => _ExperienceTabState();
}

class _ExperienceTabState extends State<_ExperienceTab> {
  @override
  Widget build(BuildContext context) {
    final user = AppStore().currentUser!;
    final experiences = user.experiences;

    return Stack(
      children: [
        experiences.isEmpty
            ? const _EmptyState(
                icon: Icons.work_outline,
                message:
                    'No experience entries yet.\nTap the + button to add your work experience.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: experiences.length,
                itemBuilder: (_, i) =>
                    _ExperienceTile(experience: experiences[i]),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (experiences.length >= _maxSummaryItems) {
                _showLimitReached(context, 'Experience');
                return;
              }
              _showAddExperienceDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Experience'),
          ),
        ),
      ],
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final Experience experience;
  const _ExperienceTile({required this.experience});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            title: Text(experience.position,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _getTextColor(context))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(experience.company,
                    style:
                        TextStyle(fontSize: 13, color: _getTextColor(context))),
                const SizedBox(height: 4),
                Text('${experience.startDate} - ${experience.endDate}',
                    style:
                        TextStyle(fontSize: 11, color: _getTextMuted(context))),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.primary),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit experience',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.danger),
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'Delete experience',
                ),
              ],
            ),
          ),
          if (experience.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(experience.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: _getTextColor(context),
                      height: 1.4)),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final companyCtrl = TextEditingController(text: experience.company);
    final positionCtrl = TextEditingController(text: experience.position);
    final startDateCtrl = TextEditingController(text: experience.startDate);
    final endDateCtrl = TextEditingController(text: experience.endDate);
    final descriptionCtrl = TextEditingController(text: experience.description);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setSt) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Edit Work Experience',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Company',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: positionCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startDateCtrl,
                      style: TextStyle(color: _getTextColor(context)),
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        labelStyle: TextStyle(color: _getTextMuted(context)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _getBorder(context))),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endDateCtrl,
                      style: TextStyle(color: _getTextColor(context)),
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        labelStyle: TextStyle(color: _getTextMuted(context)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _getBorder(context))),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                style: TextStyle(color: _getTextColor(context)),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
              if (companyCtrl.text.trim().isEmpty ||
                  positionCtrl.text.trim().isEmpty) {
                return;
              }
              setSt(() => isSubmitting = true);

              final updatedExperience = Experience(
                id: experience.id,
                company: companyCtrl.text.trim(),
                position: positionCtrl.text.trim(),
                startDate: startDateCtrl.text.trim(),
                endDate: endDateCtrl.text.trim(),
                description: descriptionCtrl.text.trim(),
                title: '',
                dateRange: '',
              );

              await AppStore().updateExperience(updatedExperience);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Delete Experience',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this work experience?',
          style: TextStyle(color: _getSubTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppStore().removeExperience(experience.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Add Experience dialog method
void _showAddExperienceDialog(BuildContext context) {
  final companyCtrl = TextEditingController();
  final positionCtrl = TextEditingController();
  final startDateCtrl = TextEditingController();
  final endDateCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setSt) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Add Work Experience',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Company',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: positionCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startDateCtrl,
                      style: TextStyle(color: _getTextColor(context)),
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        labelStyle: TextStyle(color: _getTextMuted(context)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _getBorder(context))),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endDateCtrl,
                      style: TextStyle(color: _getTextColor(context)),
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        labelStyle: TextStyle(color: _getTextMuted(context)),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _getBorder(context))),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                style: TextStyle(color: _getTextColor(context)),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                isSubmitting ? null : () => Navigator.pop(dialogContext),
            child:
                Text('Cancel', style: TextStyle(color: _getTextMuted(context))),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    if (companyCtrl.text.trim().isEmpty ||
                        positionCtrl.text.trim().isEmpty) {
                      return;
                    }
                    if (AppStore().currentUser!.experiences.length >=
                        _maxSummaryItems) {
                      _showLimitReached(context, 'Experience');
                      return;
                    }
                    setSt(() => isSubmitting = true);

                    final experience = Experience(
                      id: const Uuid().v4(),
                      company: companyCtrl.text.trim(),
                      position: positionCtrl.text.trim(),
                      startDate: startDateCtrl.text.trim(),
                      endDate: endDateCtrl.text.trim(),
                      description: descriptionCtrl.text.trim(),
                      title: '',
                      dateRange: '',
                    );

                    await AppStore().addExperience(experience);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// Add Achievement dialog method
void _showAddAchievementDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  bool isSubmitting = false;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setSt) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Add Achievement',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Date',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                style: TextStyle(color: _getTextColor(context)),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                isSubmitting ? null : () => Navigator.pop(dialogContext),
            child:
                Text('Cancel', style: TextStyle(color: _getTextMuted(context))),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      return;
                    }
                    if (AppStore().currentUser!.achievements.length >=
                        _maxSummaryItems) {
                      _showLimitReached(context, 'Achievements');
                      return;
                    }
                    setSt(() => isSubmitting = true);

                    final achievement = Achievement(
                      id: const Uuid().v4(),
                      title: titleCtrl.text.trim(),
                      description: descriptionCtrl.text.trim(),
                      date: dateCtrl.text.trim(),
                      category: categoryCtrl.text.trim(),
                    );

                    await AppStore().addAchievement(achievement);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// ─── Achievements Tab ───────────────────────────────────────────────────────────

class _AchievementsTab extends StatefulWidget {
  const _AchievementsTab();

  @override
  State<_AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<_AchievementsTab> {
  @override
  Widget build(BuildContext context) {
    final user = AppStore().currentUser!;
    final achievements = user.achievements;

    return Stack(
      children: [
        achievements.isEmpty
            ? const _EmptyState(
                icon: Icons.emoji_events_outlined,
                message:
                    'No achievements yet.\nTap the + button to add your achievements.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: achievements.length,
                itemBuilder: (_, i) =>
                    _AchievementTile(achievement: achievements[i]),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (achievements.length >= _maxSummaryItems) {
                _showLimitReached(context, 'Achievements');
                return;
              }
              _showAddAchievementDialog(context);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Achievement'),
          ),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            title: Text(achievement.title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.category,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(achievement.date,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.primary),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit achievement',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.danger),
                  onPressed: () => _showDeleteDialog(context),
                  tooltip: 'Delete achievement',
                ),
              ],
            ),
          ),
          if (achievement.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(achievement.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4)),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: achievement.title);
    final descriptionCtrl =
        TextEditingController(text: achievement.description);
    final dateCtrl = TextEditingController(text: achievement.date);
    final categoryCtrl = TextEditingController(text: achievement.category);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setSt) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Edit Achievement',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                style: TextStyle(color: _getTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Date',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).primaryColor)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                style: TextStyle(color: _getTextColor(context)),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: _getTextMuted(context)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getBorder(context))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _getTextColor(context))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
            child:
                Text('Cancel', style: TextStyle(color: _getTextMuted(context))),
          ),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
              if (titleCtrl.text.trim().isEmpty) {
                return;
              }
              setSt(() => isSubmitting = true);

              final updatedAchievement = Achievement(
                id: achievement.id,
                title: titleCtrl.text.trim(),
                description: descriptionCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                category: categoryCtrl.text.trim(),
              );

              await AppStore().updateAchievement(updatedAchievement);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _getDialogBg(context),
        title: Text(
          'Delete Achievement',
          style: TextStyle(
              color: _getTextColor(context), fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this achievement?',
          style: TextStyle(color: _getSubTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppStore().removeAchievement(achievement.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
