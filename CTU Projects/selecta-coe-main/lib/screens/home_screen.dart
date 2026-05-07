// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';
import '../utils/database_debug_final.dart';
import 'database_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _sidebarOpen = false;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  // NOTE: Pages are NOT const so they rebuild when AppStore notifies.
  List<Widget> get _pages => const [
        _DashboardTab(),
        DatabaseScreen(),
        SearchScreen(),
        ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    // ── Listen to AppStore so the whole shell rebuilds on profile changes ──
    AppStore().addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppStore().removeListener(_onStoreChanged);
    _animController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() => _sidebarOpen = !_sidebarOpen);
    if (_sidebarOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _closeSidebar() {
    if (_sidebarOpen) {
      setState(() => _sidebarOpen = false);
      _animController.reverse();
    }
  }

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
    _closeSidebar();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 26),
          onPressed: _toggleSidebar,
          tooltip: 'Menu',
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/LOGO.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'SELECTA-COE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DatabaseDebug()),
              );
            },
            tooltip: 'View Database Location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          pages[_selectedIndex],

          // Dim overlay when sidebar is open
          if (_sidebarOpen)
            GestureDetector(
              onTap: _closeSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),

          // Sliding sidebar — reads fresh currentUser on every build
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: _SideDrawer(
              selectedIndex: _selectedIndex,
              onSelect: _selectIndex,
              user: AppStore().currentUser,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared avatar helper (local file + network + initials fallback) ──────────

Widget _buildAvatarCircle({
  required double size,
  required String avatarUrl,
  required String initials,
}) {
  final double fontSize = size * 0.35;

  Widget child;
  if (avatarUrl.isNotEmpty) {
    final isLocal = avatarUrl.startsWith('/');
    child = isLocal
        ? Image.file(
            File(avatarUrl),
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _initialsText(initials, fontSize),
          )
        : Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _initialsText(initials, fontSize),
          );
  } else {
    child = _initialsText(initials, fontSize);
  }

  return Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppTheme.primary,
    ),
    child: ClipOval(child: child),
  );
}

Widget _initialsText(String initials, double fontSize) {
  return Center(
    child: Text(
      initials,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
      ),
    ),
  );
}

// ── Side drawer ──────────────────────────────────────────────────────────────

class _SideDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final UserAccount? user;

  const _SideDrawer({
    required this.selectedIndex,
    required this.onSelect,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User info header ──
            Container(
              color: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              width: double.infinity,
              child: Row(
                children: [
                  // Avatar — shows photo if available
                  _buildAvatarCircle(
                    size: 44,
                    avatarUrl: user?.avatarUrl ?? '',
                    initials: user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),

            _NavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              isSelected: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
            _NavItem(
              icon: Icons.storage_outlined,
              activeIcon: Icons.storage,
              label: 'Credential Summary',
              isSelected: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
            _NavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search,
              label: 'Search',
              isSelected: selectedIndex == 2,
              onTap: () => onSelect(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              isSelected: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  await AppStore().logout();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard tab — now a StatefulWidget so it rebuilds on AppStore changes
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    AppStore().addListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppStore().removeListener(_onStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore();
    final user = store.currentUser;

    // If user is null (logged out), redirect to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: AppTheme.surfaceVariant,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          _StatsRow(user: user),
          const SizedBox(height: 20),
          if (user.skillCategories.isNotEmpty) ...[
            const _SectionHeader(title: 'Top Competencies'),
            const SizedBox(height: 10),
            ...user.skillCategories
                .take(2)
                .map((cat) => _CompetencyCard(category: cat)),
          ],
          const SizedBox(height: 20),
          if (user.projects.isNotEmpty) ...[
            const _SectionHeader(title: 'Recent Projects'),
            const SizedBox(height: 10),
            ...user.projects.take(2).map((p) => _ProjectCard(project: p)),
          ],
          const SizedBox(height: 20),
          if (user.certifications.isNotEmpty) ...[
            const _SectionHeader(title: 'Certifications'),
            const SizedBox(height: 10),
            _CertGrid(certs: user.certifications),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── _ProfileCard — uses shared avatar helper ─────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final UserAccount user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // ── Avatar — handles local file, network URL, and initials ──
          _buildAvatarCircle(
            size: 54,
            avatarUrl: user.avatarUrl,
            initials: user.avatarInitials,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                const Text('Cebu Technological University',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('${user.course} • ${user.yearLevel}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.email_outlined,
                      size: 12, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(user.email,
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final UserAccount user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          value: '${user.totalSkills}',
          label: 'Total Skills',
          icon: Icons.workspace_premium_outlined,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${user.avgCompetency.round()}%',
          label: 'Avg Competency',
          icon: Icons.trending_up,
          color: AppTheme.success,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${user.projects.length}',
          label: 'Projects',
          icon: Icons.folder_outlined,
          color: AppTheme.warning,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${user.certifications.length}',
          label: 'Certs',
          icon: Icons.military_tech_outlined,
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary));
  }
}

class _CompetencyCard extends StatelessWidget {
  final SkillCategory category;
  const _CompetencyCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary)),
              const Icon(Icons.add_circle_outline,
                  size: 18, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          ...category.skills.map((skill) => _SkillRow(skill: skill)),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  final Skill skill;
  const _SkillRow({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(skill.name,
                  style: const TextStyle(
                      fontSize: 15, color: AppTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.levelColor(skill.level).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(skill.level,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.levelColor(skill.level),
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: skill.proficiencyPercent / 100,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.barColor(skill.proficiencyPercent)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(project.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
              ),
              const Icon(Icons.open_in_new,
                  size: 16, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 6),
          Text(project.description,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(project.date,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(width: 12),
              const Icon(Icons.people_outline,
                  size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text('${project.memberCount} members',
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: project.tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Edit Project',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertGrid extends StatelessWidget {
  final List<Certification> certs;
  const _CertGrid({required this.certs});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: certs.length,
      itemBuilder: (_, i) => _CertTile(cert: certs[i]),
    );
  }
}

class _CertTile extends StatelessWidget {
  final Certification cert;
  const _CertTile({required this.cert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.military_tech,
                    size: 16, color: Color(0xFFF97316)),
              ),
              const Spacer(),
              const Icon(Icons.open_in_new,
                  size: 14, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 6),
          Text(cert.title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(cert.issuer,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
