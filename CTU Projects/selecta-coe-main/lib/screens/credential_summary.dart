// lib/screens/database_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';

// ─── Shared dark dialog helpers ───────────────────────────────────────────────

const _kDialogBg = Color(0xFF1E2530);
const _kHintColor = Colors.white38;
const _kLabelColor = Colors.white54;
const _kTextColor = Colors.white;
const _kSubTextColor = Colors.white70;
const _kTextMuted = Colors.white54;
const _kBorder = Colors.white24;

InputDecoration _darkInput(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kHintColor),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primary)),
    );

InputDecoration _darkLabelInput(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kLabelColor),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primary)),
    );

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
          color: AppTheme.surfaceVariant,
          child: TabBar(
            controller: _tab,
            labelColor: AppTheme.primary,
            unselectedLabelColor: const Color.fromARGB(255, 255, 255, 255),
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
            onPressed: () => _showAddCategoryDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'New Skill Category',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: _kTextColor),
          decoration: _darkInput('e.g. Programming Languages'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await AppStore().addSkillCategory(SkillCategory(
                id: const Uuid().v4(),
                name: ctrl.text.trim(),
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(category.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.add, color: AppTheme.primary, size: 20),
                  onPressed: () => _showAddSkillDialog(context),
                  tooltip: 'Add skill',
                ),
              ],
            ),
          ),
          if (category.skills.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text('No skills yet — tap + to add one.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
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

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: _kDialogBg,
          title: const Text(
            'Add Skill',
            style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Skill name'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: level,
                dropdownColor: _kDialogBg,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkLabelInput('Proficiency Level'),
                items: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setSt(() => level = v!),
              ),
              const SizedBox(height: 14),
              Text('Proficiency: ${percent.round()}%',
                  style: const TextStyle(fontSize: 13, color: _kSubTextColor)),
              Slider(
                value: percent,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppTheme.primary,
                onChanged: (v) => setSt(() => percent = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
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
              child: const Text('Add'),
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
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.levelColor(skill.level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(skill.level,
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.levelColor(skill.level),
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  await AppStore().removeSkill(catId, skill.id);
                  onChanged();
                },
                child: const Icon(Icons.close,
                    size: 16, color: AppTheme.textMuted),
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
                    backgroundColor: AppTheme.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.barColor(skill.proficiencyPercent)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${skill.proficiencyPercent.round()}%',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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
            onPressed: () => _showAddDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
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

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: _kDialogBg,
          title: const Text(
            'Add Project',
            style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: const TextStyle(color: _kTextColor),
                  decoration: _darkInput('Project title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: _kTextColor),
                  decoration: _darkInput('Description'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateCtrl,
                  style: const TextStyle(color: _kTextColor),
                  decoration: _darkInput('Date (e.g. Jan 2026)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: tagsCtrl,
                  style: const TextStyle(color: _kTextColor),
                  decoration: _darkInput('Tags (comma separated)'),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  const Text('Members: ',
                      style: TextStyle(fontSize: 13, color: _kSubTextColor)),
                  IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: _kSubTextColor),
                      onPressed: () =>
                          setSt(() => members = (members - 1).clamp(1, 50))),
                  Text('$members',
                      style: const TextStyle(
                          color: _kTextColor, fontWeight: FontWeight.w600)),
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: _kSubTextColor),
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
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final tags = tagsCtrl.text
                    .split(',')
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
              child: const Text('Add'),
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(project.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
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
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
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
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color.fromARGB(255, 8, 15, 26))),
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
                message: 'No education yet.\nAdd your education to get started.')
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
            onPressed: () => _showAddDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Add Education',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: schoolCtrl,
                autofocus: true,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('School Name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: degreeCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Degree'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: yearCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Year'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (schoolCtrl.text.isNotEmpty) {
                final education = EducationalAttainment(
                  id: const Uuid().v4(),
                  schoolName: schoolCtrl.text.trim(),
                  degree: degreeCtrl.text.trim(),
                  year: yearCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                );
                await AppStore().addEducationalAttainment(education);
                Navigator.pop(context);
                _refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Education added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(education.schoolName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.edit, color: AppTheme.primary, size: 20),
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
                  const Text('Degree',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(education.degree,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                ],
                if (education.year.isNotEmpty) ...[
                  const Text('Year',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(education.year,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                ],
                if (education.address.isNotEmpty) ...[
                  const Text('Address',
                      style: TextStyle(
                          fontSize: 10, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(education.address,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Edit Education',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: schoolCtrl,
                autofocus: true,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('School Name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: degreeCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Degree'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: yearCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Year'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: _darkInput('Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (schoolCtrl.text.isNotEmpty) {
                final updatedEducation = EducationalAttainment(
                  id: education.id,
                  schoolName: schoolCtrl.text.trim(),
                  degree: degreeCtrl.text.trim(),
                  year: yearCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                );
                await AppStore().updateEducationalAttainment(updatedEducation);
                Navigator.pop(context);
                onChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Education updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Delete Education',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this education record?',
          style: TextStyle(color: _kSubTextColor),
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
            onPressed: () => _showAddDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Add Certification',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(color: _kTextColor),
              decoration: _darkInput('Certification title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: issuerCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: _darkInput('Issuing organization'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: _darkInput('Date (e.g. March 2026)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: idCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: _darkInput('Certificate ID'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await AppStore().addCertification(Certification(
                id: const Uuid().v4(),
                title: titleCtrl.text.trim(),
                issuer: issuerCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                certId: idCtrl.text.trim(),
              ));
              if (!context.mounted) return;
              Navigator.pop(context);
              _refresh();
            },
            child: const Text('Add'),
          ),
        ],
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
                Text(cert.issuer,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text('${cert.date}  •  ${cert.certId}',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppTheme.danger),
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
          Icon(icon, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 14, height: 1.5)),
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
                message: 'No experience entries yet.\nTap the + button to add your work experience.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: experiences.length,
                itemBuilder: (_, i) => _ExperienceTile(experience: experiences[i]),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddExperienceDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            title: Text(experience.position,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(experience.company,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('${experience.startDate} - ${experience.endDate}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.primary),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit experience',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
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
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Edit Work Experience',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: companyCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: const InputDecoration(
                  labelText: 'Company',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: positionCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: const InputDecoration(
                  labelText: 'Position',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startDateCtrl,
                      style: const TextStyle(color: _kTextColor),
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        labelStyle: TextStyle(color: _kTextMuted),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _kBorder)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endDateCtrl,
                      style: const TextStyle(color: _kTextColor),
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        labelStyle: TextStyle(color: _kTextMuted),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: _kBorder)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.primary)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                style: const TextStyle(color: _kTextColor),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (companyCtrl.text.trim().isEmpty ||
                  positionCtrl.text.trim().isEmpty) {
                return;
              }

              final updatedExperience = Experience(
                id: experience.id,
                company: companyCtrl.text.trim(),
                position: positionCtrl.text.trim(),
                startDate: startDateCtrl.text.trim(),
                endDate: endDateCtrl.text.trim(),
                description: descriptionCtrl.text.trim(),
              );

              await AppStore().updateExperience(updatedExperience);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Delete Experience',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this work experience?',
          style: TextStyle(color: _kSubTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
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

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _kDialogBg,
      title: const Text(
        'Add Work Experience',
        style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: const InputDecoration(
                labelText: 'Company',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: positionCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: const InputDecoration(
                labelText: 'Position',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startDateCtrl,
                    style: const TextStyle(color: _kTextColor),
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      labelStyle: TextStyle(color: _kTextMuted),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: _kBorder)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endDateCtrl,
                    style: const TextStyle(color: _kTextColor),
                    decoration: const InputDecoration(
                      labelText: 'End Date',
                      labelStyle: TextStyle(color: _kTextMuted),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: _kBorder)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.primary)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              style: const TextStyle(color: _kTextColor),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (companyCtrl.text.trim().isEmpty ||
                positionCtrl.text.trim().isEmpty) {
              return;
            }

            final experience = Experience(
              id: const Uuid().v4(),
              company: companyCtrl.text.trim(),
              position: positionCtrl.text.trim(),
              startDate: startDateCtrl.text.trim(),
              endDate: endDateCtrl.text.trim(),
              description: descriptionCtrl.text.trim(),
            );

            await AppStore().addExperience(experience);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// Add Achievement dialog method
void _showAddAchievementDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _kDialogBg,
      title: const Text(
        'Add Achievement',
        style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateCtrl,
              style: const TextStyle(color: _kTextColor),
              decoration: const InputDecoration(
                labelText: 'Date',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              style: const TextStyle(color: _kTextColor),
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: _kTextMuted),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kBorder)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primary)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (titleCtrl.text.trim().isEmpty) {
              return;
            }

            final achievement = Achievement(
              id: const Uuid().v4(),
              title: titleCtrl.text.trim(),
              description: descriptionCtrl.text.trim(),
              date: dateCtrl.text.trim(),
              category: categoryCtrl.text.trim(),
            );

            await AppStore().addAchievement(achievement);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
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
                message: 'No achievements yet.\nTap the + button to add your achievements.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: achievements.length,
                itemBuilder: (_, i) => _AchievementTile(achievement: achievements[i]),
              ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddAchievementDialog(context),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            title: Text(achievement.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimary)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.category,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 4),
                Text(achievement.date,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppTheme.primary),
                  onPressed: () => _showEditDialog(context),
                  tooltip: 'Edit achievement',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
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
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary, height: 1.4)),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: achievement.title);
    final descriptionCtrl = TextEditingController(text: achievement.description);
    final dateCtrl = TextEditingController(text: achievement.date);
    final categoryCtrl = TextEditingController(text: achievement.category);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Edit Achievement',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dateCtrl,
                style: const TextStyle(color: _kTextColor),
                decoration: const InputDecoration(
                  labelText: 'Date',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionCtrl,
                style: const TextStyle(color: _kTextColor),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: _kTextMuted),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) {
                return;
              }

              final updatedAchievement = Achievement(
                id: achievement.id,
                title: titleCtrl.text.trim(),
                description: descriptionCtrl.text.trim(),
                date: dateCtrl.text.trim(),
                category: categoryCtrl.text.trim(),
              );

              await AppStore().updateAchievement(updatedAchievement);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kDialogBg,
        title: const Text(
          'Delete Achievement',
          style: TextStyle(color: _kTextColor, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Are you sure you want to delete this achievement?',
          style: TextStyle(color: _kSubTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppStore().removeAchievement(achievement.id);
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
