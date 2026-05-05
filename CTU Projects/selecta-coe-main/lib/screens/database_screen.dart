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

InputDecoration _darkInput(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _kHintColor),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24)),
      focusedBorder:
          const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
    );

InputDecoration _darkLabelInput(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kLabelColor),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24)),
      focusedBorder:
          const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
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
    _tab = TabController(length: 3, vsync: this);
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
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ))
                .toList(),
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
