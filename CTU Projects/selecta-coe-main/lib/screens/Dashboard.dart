import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';
import '../theme_provider.dart';
import 'credential_summary.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../widgets/pill_header.dart';

// ─── Theme helper functions ───────────────────────────────────────────────

Color _getTextColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
}

Color _getTextMuted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? Colors.white54
      : Colors.grey.shade600;
}

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
      appBar: PillHeader(
        title: 'SELECTA-COE',
        leadingIcon: Icons.menu,
        onLeadingTap: _toggleSidebar,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: themeProvider.toggleTheme,
                tooltip: themeProvider.isDarkMode
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: Icon(themeProvider.isDarkMode
                    ? Icons.light_mode
                    : Icons.dark_mode),
              );
            },
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
  required BuildContext context,
  required double size,
  required String avatarUrl,
  required String initials,
}) {
  final double fontSize = size * 0.35;

  Widget child;
  if (avatarUrl.isNotEmpty) {
    final isDataUri = avatarUrl.startsWith('data:image');
    final isLocal = avatarUrl.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:\\').hasMatch(avatarUrl);
    child = isDataUri
        ? Image.memory(
            base64Decode(avatarUrl.split(',').last),
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (_, __, ___) => _initialsText(initials, fontSize),
          )
        : isLocal
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
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppTheme.getPrimary(context),
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
        color: Theme.of(context).colorScheme.surface,
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
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              width: double.infinity,
              child: Row(
                children: [
                  // Avatar — shows photo if available
                  _buildAvatarCircle(
                    context: context,
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
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
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

    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PillHeader(
            title: 'Dashboard',
            leadingIcon: Icons.menu,
            onLeadingTap: null,
            actions: const [Icon(Icons.more_vert)],
            useSafeArea: false,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: scheme.outline.withOpacity(0.25)),
              ),
              child: _StatsRow(user: user),
            ),
          ),
          const SizedBox(height: 20),
          if (user.skillCategories.isNotEmpty) ...[
            const _SectionHeader(title: 'Top Competencies'),
            const SizedBox(height: 10),
            ...user.skillCategories
                .map((cat) => _CompetencyCard(category: cat)),
          ],
          const SizedBox(height: 20),
          if (user.projects.isNotEmpty) ...[
            const _SectionHeader(title: 'Recent Projects'),
            const SizedBox(height: 10),
            ...user.projects.map((p) => _ProjectCard(project: p)),
          ],
          const SizedBox(height: 20),
          if (user.certifications.isNotEmpty) ...[
            const _SectionHeader(title: 'Certifications'),
            const SizedBox(height: 10),
            _CertGrid(certs: user.certifications),
          ],
          const SizedBox(height: 20),
          if (user.educationalAttainments.isNotEmpty) ...[
            const _SectionHeader(title: 'Education'),
            const SizedBox(height: 10),
            _EducationGrid(education: user.educationalAttainments),
          ],
          const SizedBox(height: 20),
          if (user.experiences.isNotEmpty) ...[
            const _SectionHeader(title: 'Experience'),
            const SizedBox(height: 10),
            _ExperienceGrid(experiences: user.experiences),
          ],
          const SizedBox(height: 20),
          if (user.achievements.isNotEmpty) ...[
            const _SectionHeader(title: 'Achievements'),
            const SizedBox(height: 10),
            _AchievementGrid(achievements: user.achievements),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── _ProfileCard — uses shared avatar helper ─────────────────────────────────

class _ProfileCard extends StatefulWidget {
  final UserAccount user;
  const _ProfileCard({required this.user});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final store = AppStore();
    final isLiked = await store.isProfileLiked(widget.user.id);
    print('DEBUG: Checking like status for user ${widget.user.id}: $isLiked');
    if (mounted) {
      setState(() {
        _isLiked = isLiked;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final store = AppStore();
    print(
        'DEBUG: Toggling like for user ${widget.user.id}, current user: ${store.currentUser?.id}');

    // For demo purposes, allow liking own profile for testing
    // In production, you might want to hide the like button for own profile
    final newLikeStatus = await store.toggleProfileLike(widget.user.id);
    print('DEBUG: Toggle result: $newLikeStatus');

    if (mounted) {
      setState(() {
        _isLiked = newLikeStatus;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // ── Avatar — handles local file, network URL, and initials ──
          _buildAvatarCircle(
            context: context,
            size: 54,
            avatarUrl: widget.user.avatarUrl,
            initials: widget.user.avatarInitials,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _getTextColor(context))),
                const SizedBox(height: 2),
                Text('Cebu Technological University',
                    style:
                        TextStyle(fontSize: 11, color: _getTextMuted(context))),
                const SizedBox(height: 4),
                Text('${widget.user.course} • ${widget.user.yearLevel}',
                    style:
                        TextStyle(fontSize: 12, color: _getTextMuted(context))),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.email_outlined,
                      size: 12, color: _getTextMuted(context)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(widget.user.email,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ],
            ),
          ),
          // ── Like button ──
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isLiked
                    ? Colors.pink.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLiked
                      ? Colors.pink
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isLiked
                              ? Colors.pink
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                        ),
                      ),
                    )
                  : Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked
                          ? Colors.pink
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  final UserAccount user;
  const _StatsRow({required this.user});

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
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
    final currentUser = store.currentUser;

    // Get updated user data from store to reflect like changes
    final displayUser =
        currentUser?.id == widget.user.id ? currentUser : widget.user;

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            key: const ValueKey('skills'),
            child: _StatCard(
              value: displayUser?.skillsPrivate == true
                  ? 'Private'
                  : '${displayUser?.totalSkills ?? 0}',
              label: 'Total Skills',
              icon: Icons.workspace_premium_outlined,
              color: AppTheme.getPrimary(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            key: const ValueKey('avg'),
            child: _StatCard(
              value: displayUser?.skillsPrivate == true
                  ? 'Private'
                  : '${displayUser?.avgCompetency.round() ?? 0}%',
              label: 'Avg Competency',
              icon: Icons.trending_up,
              color: const Color.fromARGB(255, 53, 200, 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            key: const ValueKey('projects'),
            child: _StatCard(
              value: displayUser?.projectsPrivate == true
                  ? 'Private'
                  : '${displayUser?.projects.length ?? 0}',
              label: 'Projects',
              icon: Icons.folder_outlined,
              color: AppTheme.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            key: const ValueKey('certifications'),
            child: _StatCard(
              value: displayUser?.certificationsPrivate == true
                  ? 'Private'
                  : '${displayUser?.certifications.length ?? 0}',
              label: 'Certs',
              icon: Icons.military_tech_outlined,
              color: const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            key: const ValueKey('likes'),
            child: _StatCard(
              value: '${displayUser?.profileLikes ?? 0}',
              label: 'Likes',
              icon: Icons.favorite,
              color: Colors.pink,
            ),
          ),
        ],
      ),
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
//sera
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  color: scheme.onSurface.withOpacity(0.72))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          height: 16,
          width: 4,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.85),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _getTextColor(context))),
        ),
      ],
    );
  }
}

class _CompetencyCard extends StatelessWidget {
  final SkillCategory category;
  const _CompetencyCard({required this.category});
//nwash
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _getTextColor(context))),
              Icon(Icons.add_circle_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary),
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
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor(context))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(skill.level,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(project.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _getTextColor(context))),
              ),
              Icon(Icons.open_in_new,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 6),
          Text(project.description,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.85),
                  height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(project.date,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6))),
              const SizedBox(width: 12),
              Icon(Icons.people_outline,
                  size: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text('${project.memberCount} members',
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: project.tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.25)),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary)),
                    ))
                .toList(),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: scheme.outline.withOpacity(0.25)),
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
              Icon(Icons.open_in_new, size: 14, color: _getTextMuted(context)),
            ],
          ),
          const SizedBox(height: 6),
          Text(cert.title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextPrimary(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(cert.date,
              style: TextStyle(
                  fontSize: 10, color: AppTheme.getTextMuted(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _EducationGrid extends StatelessWidget {
  final List<EducationalAttainment> education;
  const _EducationGrid({required this.education});

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
      itemCount: education.length,
      itemBuilder: (_, i) => _EducationTile(education: education[i]),
    );
  }
}

class _EducationTile extends StatelessWidget {
  final EducationalAttainment education;
  const _EducationTile({required this.education});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showEducationDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.getPrimary(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.school,
                      size: 16, color: AppTheme.getPrimary(context)),
                ),
                const Spacer(),
                Icon(Icons.open_in_new,
                    size: 14, color: _getTextMuted(context)),
              ],
            ),
            const SizedBox(height: 3),
            Text(education.schoolName,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (education.degree.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(education.degree,
                  style: TextStyle(
                      fontSize: 10, color: AppTheme.getTextSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            if (education.year.isNotEmpty) ...[
              Text(education.year,
                  style: TextStyle(
                      fontSize: 10, color: AppTheme.getTextSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }

  void _showEducationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: Row(
          children: [
            Icon(Icons.school, color: AppTheme.getPrimary(context), size: 20),
            SizedBox(width: 8),
            Text('Education Details',
                style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'School Name', education.schoolName),
            if (education.degree.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Degree', education.degree),
            ],
            if (education.year.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Year', education.year),
            ],
            if (education.address.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Address', education.address),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 12, color: AppTheme.getTextMuted(context))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, color: AppTheme.getTextPrimary(context))),
      ],
    );
  }
}

class _ExperienceGrid extends StatelessWidget {
  final List<Experience> experiences;
  const _ExperienceGrid({required this.experiences});

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
      itemCount: experiences.length,
      itemBuilder: (_, i) => _ExperienceTile(experience: experiences[i]),
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  final Experience experience;
  const _ExperienceTile({required this.experience});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showExperienceDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.25)),
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
                    color: AppTheme.getSuccess(context).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.work,
                      size: 16, color: AppTheme.getSuccess(context)),
                ),
                const Spacer(),
                Icon(Icons.open_in_new,
                    size: 14, color: AppTheme.getTextMuted(context)),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(experience.position,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextPrimary(context)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 2),
            Text(experience.company,
                style: TextStyle(
                    fontSize: 10, color: AppTheme.getTextSecondary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text('${experience.startDate} - ${experience.endDate}',
                style: TextStyle(
                    fontSize: 10, color: AppTheme.getTextSecondary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _showExperienceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: Row(
          children: [
            Icon(Icons.work, color: AppTheme.getSuccess(context), size: 20),
            SizedBox(width: 8),
            Text('Experience Details',
                style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Position', experience.position),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Company', experience.company),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Duration',
                '${experience.startDate} - ${experience.endDate}'),
            if (experience.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Description', experience.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 12, color: AppTheme.getTextMuted(context))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, color: AppTheme.getTextPrimary(context))),
      ],
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  const _AchievementGrid({required this.achievements});

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
      itemCount: achievements.length,
      itemBuilder: (_, i) => _AchievementTile(achievement: achievements[i]),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showAchievementDialog(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withOpacity(0.25)),
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
                  child: const Icon(Icons.emoji_events,
                      size: 16, color: Color(0xFFF97316)),
                ),
                const Spacer(),
                Icon(Icons.open_in_new,
                    size: 14, color: AppTheme.getTextMuted(context)),
              ],
            ),
            const SizedBox(height: 6),
            Text(achievement.title,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextPrimary(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Text(achievement.category,
                style: TextStyle(
                    fontSize: 10, color: AppTheme.getTextSecondary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(achievement.date,
                style: TextStyle(
                    fontSize: 10, color: AppTheme.getTextSecondary(context)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _showAchievementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFF97316), size: 20),
            SizedBox(width: 8),
            Text('Achievement Details',
                style: TextStyle(
                    color: AppTheme.getTextPrimary(context),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Title', achievement.title),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Category', achievement.category),
            const SizedBox(height: 12),
            _buildDetailRow(context, 'Date', achievement.date),
            if (achievement.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Description', achievement.description),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(fontSize: 12, color: AppTheme.getTextMuted(context))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, color: AppTheme.getTextPrimary(context))),
      ],
    );
  }
}
