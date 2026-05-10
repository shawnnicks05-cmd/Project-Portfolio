// lib/screens/profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';

class SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const SummaryItem(
      {super.key,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId, this.viewOnly = false});

  final String? userId;
  final bool viewOnly;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  UserAccount? _displayUser;
  bool _canEdit = false; // New variable to track if editing is allowed
  bool _isLiked = false; // Track like status to avoid async issues

  // Picked image file (local, before save)
  File? _pickedImageFile;

  TextEditingController? _name;
  TextEditingController? _email;
  TextEditingController? _phone;
  TextEditingController? _course;
  TextEditingController? _studentId;
  TextEditingController? _location;
  TextEditingController? _bio;
  TextEditingController? _instagramUrl;
  TextEditingController? _facebookUrl;
  TextEditingController? _yearLevelController;

  // Snapshot for cancel support
  late String _snapName;
  late String _snapEmail;
  late String _snapPhone;
  late String _snapCourse;
  late String _snapStudentId;
  late String _snapLocation;
  late String _snapBio;
  late String _snapInstagramUrl;
  late String _snapFacebookUrl;
  late String _snapYearLevel;
  File? _snapPickedImageFile;

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    '5th Year',
  ];

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    final displayUser = widget.userId != null
        ? await AppStore().getUserById(widget.userId!) ?? AppStore().currentUser
        : AppStore().currentUser;

    // Record profile view if viewing someone else's profile
    if (widget.userId != null && displayUser != null) {
      final currentUser = AppStore().currentUser;
      if (currentUser != null && widget.userId != currentUser.id) {
        await AppStore().recordProfileView(widget.userId!);
      }
    }

    // Load like status if viewing someone else's profile
    if (widget.userId != null && displayUser != null) {
      final currentUser = AppStore().currentUser;
      if (currentUser != null && widget.userId != currentUser.id) {
        _isLiked = await AppStore().isProfileLiked(widget.userId!);
      }
    }

    setState(() {
      _displayUser = displayUser;
      // Only allow editing if it's user's own profile and not in viewOnly mode
      final currentUser = AppStore().currentUser;
      _canEdit = (widget.userId == null ||
              (currentUser != null && widget.userId == currentUser.id)) &&
          !widget.viewOnly;

      if (_displayUser != null) {
        _name = TextEditingController(text: _displayUser!.name);
        _email = TextEditingController(text: _displayUser!.email);
        _phone = TextEditingController(text: _displayUser!.phone);
        _course = TextEditingController(text: _displayUser!.course);
        _studentId = TextEditingController(text: _displayUser!.studentId);
        _location = TextEditingController(text: _displayUser!.address);
        _bio = TextEditingController(text: _displayUser!.bio);
        _instagramUrl = TextEditingController(text: _displayUser!.instagramUrl);
        _facebookUrl = TextEditingController(text: _displayUser!.facebookUrl);
        _yearLevelController = TextEditingController(
            text: _years.contains(_displayUser!.yearLevel)
                ? _displayUser!.yearLevel
                : '1st Year');
      }
    });
  }

  void _takeSnapshot() {
    _snapName = _name?.text ?? '';
    _snapEmail = _email?.text ?? '';
    _snapPhone = _phone?.text ?? '';
    _snapCourse = _course?.text ?? '';
    _snapStudentId = _studentId?.text ?? '';
    _snapLocation = _location?.text ?? '';
    _snapBio = _bio?.text ?? '';
    _snapInstagramUrl = _instagramUrl?.text ?? '';
    _snapFacebookUrl = _facebookUrl?.text ?? '';
    _snapPickedImageFile = _pickedImageFile;
    _snapYearLevel = _yearLevelController?.text ?? '1st Year';
  }

  void _restoreSnapshot() {
    _name?.text = _snapName;
    _email?.text = _snapEmail;
    _phone?.text = _snapPhone;
    _course?.text = _snapCourse;
    _studentId?.text = _snapStudentId;
    _location?.text = _snapLocation;
    _bio?.text = _snapBio;
    _instagramUrl?.text = _snapInstagramUrl;
    _facebookUrl?.text = _snapFacebookUrl;
    _yearLevelController?.text = _snapYearLevel;
    setState(() {
      _pickedImageFile = _snapPickedImageFile;
    });
  }

  void _startEditing() {
    if (!_canEdit) return;
    _takeSnapshot();
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _restoreSnapshot();
    setState(() => _editing = false);
  }

  /// Show a bottom sheet to choose camera or gallery
  Future<void> _pickImage() async {
    if (!_editing || !_canEdit) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: Theme.of(context).colorScheme.primary),
                title: Text('Take Photo',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: Theme.of(context).colorScheme.primary),
                title: Text('Choose from gallery',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_pickedImageFile != null ||
                  (_displayUser != null &&
                      _displayUser!.avatarUrl.isNotEmpty == true))
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remove photo',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    setState(() => _pickedImageFile = null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() => _pickedImageFile = File(picked.path));
      }
    }
  }

  void _saveChanges() {
    // Persist image data in DB-friendly format (data URI) when a new photo is picked.
    String newAvatarUrl = _displayUser?.avatarUrl ?? '';
    if (_pickedImageFile != null) {
      try {
        final bytes = _pickedImageFile!.readAsBytesSync();
        final encoded = base64Encode(bytes);
        newAvatarUrl = 'data:image/jpeg;base64,$encoded';
      } catch (_) {
        // Fallback to local path if encoding fails.
        newAvatarUrl = _pickedImageFile!.path;
      }
    }

    final existing = _displayUser!;
    final updatedUser = UserAccount(
      id: existing.id,
      name: _name?.text.trim() ?? '',
      email: _email?.text.trim() ?? '',
      phone: _phone?.text.trim() ?? '',
      password: existing.password,
      userType: existing.userType,
      course: _course?.text.trim() ?? '',
      yearLevel: _yearLevelController?.text.trim() ?? '1st Year',
      studentId: _studentId?.text.trim() ?? '',
      address: _location?.text.trim() ?? '',
      department: existing.department,
      avatarInitials: existing.avatarInitials,
      avatarUrl: newAvatarUrl,
      bio: _bio?.text.trim() ?? '',
      instagramUrl: _instagramUrl?.text.trim() ?? '',
      facebookUrl: _facebookUrl?.text.trim() ?? '',
      skillCategories: existing.skillCategories,
      projects: existing.projects,
      certifications: existing.certifications,
      educationalAttainments: existing.educationalAttainments,
      experiences: existing.experiences,
      achievements: existing.achievements,
      careerObjective: existing.careerObjective,
      skillsPrivate: existing.skillsPrivate,
      projectsPrivate: existing.projectsPrivate,
      certificationsPrivate: existing.certificationsPrivate,
      experiencesPrivate: existing.experiencesPrivate,
      achievementsPrivate: existing.achievementsPrivate,
      careerObjectivePrivate: existing.careerObjectivePrivate,
      approvedViewers: existing.approvedViewers,
      profileViews: existing.profileViews,
      profileLikes: existing.profileLikes,
      likedBy: existing.likedBy,
    );

    AppStore().updateCurrentUser(updatedUser);

    setState(() {
      _displayUser = AppStore().currentUser!;
      _pickedImageFile = null;
      _editing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers only if they are initialized
    _name?.dispose();
    _email?.dispose();
    _phone?.dispose();
    _course?.dispose();
    _studentId?.dispose();
    _location?.dispose();
    _bio?.dispose();
    _instagramUrl?.dispose();
    _facebookUrl?.dispose();
    _yearLevelController?.dispose();
    super.dispose();
  }

  //  Avatar widget

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _editField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    int minLines = 1,
    int maxLines = 1,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.7)),
        labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.5)),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6))),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _educationTile(EducationalAttainment education) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Match Dashboard inner-card styling
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school,
                  size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  education.schoolName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (education.degree.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 24), // Align with school name text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Degree',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        education.degree,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (education.year.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 24), // Align with school name text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        education.year,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (education.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 24), // Align with school name text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        education.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _experienceTile(Experience experience) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Match Dashboard inner-card styling
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, size: 16, color: AppTheme.getSuccess(context)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  experience.position,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 24), // Align with position text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Company',
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      experience.company,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 24), // Align with position text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${experience.startDate} - ${experience.endDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (experience.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 24), // Align with position text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        experience.description,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _achievementTile(Achievement achievement) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Match Dashboard inner-card styling
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  size: 16, color: Color(0xFFF97316)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 24), // Align with title text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 24), // Align with title text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (achievement.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const SizedBox(width: 24), // Align with title text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        achievement.description,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _socialLinkRow(Widget icon, String label, String url) {
    if (url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6))),
              Text(url,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserAccount user) {
    // Priority: newly picked file  existing avatarUrl (local or network)  initials
    Widget avatarChild;

    if (_pickedImageFile != null) {
      avatarChild = Image.file(
        _pickedImageFile!,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      );
    } else if (user.avatarUrl.isNotEmpty) {
      final isDataUri = user.avatarUrl.startsWith('data:image');
      final isLocalFile = user.avatarUrl.startsWith('/') ||
          RegExp(r'^[a-zA-Z]:\\').hasMatch(user.avatarUrl);
      avatarChild = isDataUri
          ? Image.memory(
              base64Decode(user.avatarUrl.split(',').last),
              fit: BoxFit.cover,
              width: 96,
              height: 96,
              errorBuilder: (_, __, ___) =>
                  _initialsWidget(user.avatarInitials),
            )
          : isLocalFile
              ? Image.file(
                  File(user.avatarUrl),
                  fit: BoxFit.cover,
                  width: 96,
                  height: 96,
                  errorBuilder: (_, __, ___) =>
                      _initialsWidget(user.avatarInitials),
                )
              : (Uri.tryParse(user.avatarUrl)?.hasAbsolutePath ?? false)
                  ? Image.network(
                      user.avatarUrl,
                      fit: BoxFit.cover,
                      width: 96,
                      height: 96,
                      errorBuilder: (_, __, ___) =>
                          _initialsWidget(user.avatarInitials),
                    )
                  : _initialsWidget(user.avatarInitials);
    } else {
      avatarChild = _initialsWidget(user.avatarInitials);
    }

    return GestureDetector(
      onTap: (_editing && _canEdit) ? _pickImage : null,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(48),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: avatarChild,
            ),
          ),
          // Camera badge  only visible in edit mode and user can edit
          if (_editing && _canEdit)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.surface, width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_displayUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = _displayUser!;
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          color: scheme.surface,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + name header
              Center(
                child: Column(
                  children: [
                    _buildAvatar(user),
                    if (_editing && _canEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Tap photo to change',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getTextMuted(context)),
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (!_editing) ...[
                      Text(user.name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Cebu Technological University',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                      const SizedBox(height: 4),
                      Text('${user.course}  ${user.yearLevel}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                      const SizedBox(height: 4),
                      Text(user.studentId,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            user.bio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Profile stats and like button (only show when viewing other users)
              if (widget.viewOnly && _displayUser != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.outline.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Views counter
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.visibility_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                                size: 20),
                            const SizedBox(height: 4),
                            Text(
                              _displayUser!.profileViews.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Views',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Like button
                      GestureDetector(
                        onTap: () async {
                          final appStore = AppStore();
                          final newLikeStatus = await appStore
                              .toggleProfileLike(_displayUser!.id);

                          // Update local state
                          if (mounted) {
                            setState(() {
                              _isLiked = newLikeStatus;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(newLikeStatus
                                    ? 'Profile liked!'
                                    : 'Profile unliked'),
                                backgroundColor: newLikeStatus
                                    ? Colors.pink
                                    : scheme.surfaceContainerHighest,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? Colors.pink.withOpacity(0.1)
                                : scheme.surfaceContainerHighest
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isLiked
                                  ? Colors.pink.withOpacity(0.3)
                                  : scheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    _isLiked ? Colors.pink : scheme.onSurface,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _displayUser!.profileLikes.toString(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _isLiked ? Colors.pink : scheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              //  Edit / Cancel / Save buttons
              if (!widget.viewOnly && _canEdit) ...[
                if (!_editing)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _cancelEditing,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],

              //  Privacy Settings card
              if (_canEdit) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 16),

                      // Master toggle for all profile sections
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Make Profile Private',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Switch(
                            value: _displayUser?.skillsPrivate == true &&
                                _displayUser?.projectsPrivate == true &&
                                _displayUser?.certificationsPrivate == true &&
                                _displayUser?.experiencesPrivate == true &&
                                _displayUser?.achievementsPrivate == true &&
                                _displayUser?.careerObjectivePrivate == true,
                            onChanged: (value) async {
                              await AppStore().toggleProfilePrivacy('all');
                              await _initControllers(); // Refresh display
                            },
                            activeThumbColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Individual section toggles
                      _buildPrivacyToggle('Skills',
                          _displayUser?.skillsPrivate == true, 'skills'),
                      const SizedBox(height: 8),
                      _buildPrivacyToggle('Projects',
                          _displayUser?.projectsPrivate == true, 'projects'),
                      const SizedBox(height: 8),
                      _buildPrivacyToggle(
                          'Certifications',
                          _displayUser?.certificationsPrivate == true,
                          'certifications'),
                      const SizedBox(height: 8),
                      _buildPrivacyToggle(
                          'Experience',
                          _displayUser?.experiencesPrivate == true,
                          'experiences'),
                      const SizedBox(height: 8),
                      _buildPrivacyToggle(
                          'Achievements',
                          _displayUser?.achievementsPrivate == true,
                          'achievements'),
                      const SizedBox(height: 8),
                      _buildPrivacyToggle(
                          'Career Objective',
                          _displayUser?.careerObjectivePrivate == true,
                          'careerObjective'),

                      const SizedBox(height: 12),
                      Text(
                        'Private sections are only visible to you. Public sections can be seen by everyone.',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              //  Personal Information card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Personal Information',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 16),
                    if (_editing && _canEdit) ...[
                      if (_name != null)
                        _editField(_name!, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      if (_email != null)
                        _editField(_email!, 'Email', Icons.email_outlined,
                            keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      if (_phone != null)
                        _editField(_phone!, 'Phone', Icons.phone_outlined,
                            keyboard: TextInputType.phone),
                      const SizedBox(height: 12),
                      if (_course != null)
                        _editField(
                            _course!, 'Course / Program', Icons.book_outlined),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _studentId != null
                                ? _editField(_studentId!, 'Student ID',
                                    Icons.badge_outlined)
                                : Container()),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _yearLevelController != null
                                ? _editField(_yearLevelController!,
                                    'Year Level', Icons.school_outlined)
                                : Container()),
                      ]),
                      const SizedBox(height: 12),
                      if (_location != null)
                        _editField(
                            _location!, 'Location', Icons.location_on_outlined),
                      const SizedBox(height: 12),
                      if (_bio != null)
                        _editField(_bio!, 'Bio', Icons.comment_outlined,
                            keyboard: TextInputType.text,
                            minLines: 1,
                            maxLines: 1),
                      const SizedBox(height: 12),
                      if (_instagramUrl != null)
                        _editField(
                            _instagramUrl!, 'Instagram URL', Icons.camera,
                            keyboard: TextInputType.url),
                      const SizedBox(height: 12),
                      if (_facebookUrl != null)
                        _editField(
                            _facebookUrl!, 'Facebook URL', Icons.facebook,
                            keyboard: TextInputType.url),
                    ] else ...[
                      _infoRow(Icons.email_outlined, 'Email', user.email),
                      _infoRow(Icons.phone_outlined, 'Phone', user.phone),
                      _infoRow(Icons.book_outlined, 'Course', user.course),
                      _infoRow(
                          Icons.school_outlined, 'Year Level', user.yearLevel),
                      _infoRow(
                          Icons.badge_outlined, 'Student ID', user.studentId),
                      _infoRow(
                          Icons.location_on_outlined, 'Location', user.address),
                      if (user.bio.isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('Bio',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6))),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(user.bio,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ),
                      ],
                      if (user.instagramUrl.isNotEmpty ||
                          user.facebookUrl.isNotEmpty)
                        Divider(color: Theme.of(context).colorScheme.outline),
                      if (user.instagramUrl.isNotEmpty)
                        _socialLinkRow(
                            Icon(Icons.camera_alt,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            'Instagram',
                            user.instagramUrl),
                      if (user.facebookUrl.isNotEmpty)
                        _socialLinkRow(
                            Icon(Icons.facebook,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            'Facebook',
                            user.facebookUrl),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Career Objective section
              if (user.careerObjective.isNotEmpty &&
                  (!user.careerObjectivePrivate || _canEdit)) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20),
                          SizedBox(width: 8),
                          Text('Career Objective',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(user.careerObjective,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Consistent spacing between section boxes
              const SizedBox(height: 12),

              //  Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const SizedBox(width: 20),
                          SummaryItem(
                              label: 'Skills',
                              value: '${user.totalSkills}',
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          SummaryItem(
                              label: 'Avg',
                              value: '${user.avgCompetency.round()}%',
                              color: const Color.fromARGB(255, 16, 200, 62)),
                          const SizedBox(width: 12),
                          SummaryItem(
                              label: 'Projects',
                              value: '${user.projects.length}',
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          SummaryItem(
                              label: 'Certifications',
                              value: '${user.certifications.length}',
                              color: const Color(0xFFF97316)),
                          const SizedBox(width: 12),
                          SummaryItem(
                              label: 'Experience',
                              value: '${user.experiences.length}',
                              color: Colors.purple),
                          const SizedBox(width: 12),
                          SummaryItem(
                              label: 'Achievements',
                              value: '${user.achievements.length}',
                              color: Colors.amber),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Space between Summary and next section box
              const SizedBox(height: 16),

              // Experience section
              if (!user.experiencesPrivate || _canEdit) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.work,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20),
                          SizedBox(width: 8),
                          Text('Work Experience',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          if (!user.experiencesPrivate && !_canEdit) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Public',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (user.experiences.isEmpty)
                        Text('No work experience added yet.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)))
                      else
                        ...user.experiences
                            .map((experience) => _experienceTile(experience)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Education section
              if (user.educationalAttainments.isNotEmpty || _canEdit) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20),
                          SizedBox(width: 8),
                          Text('Education',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (user.educationalAttainments.isEmpty)
                        Text('No educational attainment added yet.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)))
                      else
                        ...user.educationalAttainments
                            .map((education) => _educationTile(education)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Achievements section
              if (!user.achievementsPrivate || _canEdit) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Color(0xFFF97316), size: 20),
                          SizedBox(width: 8),
                          Text('Achievements',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface)),
                          if (!user.achievementsPrivate && !_canEdit) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Public',
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (user.achievements.isEmpty)
                        Text('No achievements added yet.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.getTextSecondary(context)))
                      else
                        ...user.achievements.map(
                            (achievement) => _achievementTile(achievement)),
                    ],
                  ),
                ),
              ],

              // Space between Achievements and following boxes (Skills/Projects/Certs)
              const SizedBox(height: 16),

              // Add skills section if not private or viewing own profile
              if (!user.skillsPrivate || _canEdit) ...[
                _buildSkillsSection(user),
                const SizedBox(height: 16),
              ],

              // Add projects section if not private or viewing own profile
              if (!user.projectsPrivate || _canEdit) ...[
                _buildProjectsSection(user),
                const SizedBox(height: 16),
              ],

              // Add certifications section if not private or viewing own profile
              if (!user.certificationsPrivate || _canEdit) ...[
                _buildCertificationsSection(user),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(UserAccount user) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.psychology, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Skills',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              if (!user.skillsPrivate && !_canEdit) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Public',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (user.skillCategories.isEmpty)
            Text('No skills added yet',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 14))
          else ...[
            for (final category in user.skillCategories) ...[
              Text(category.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: category.skills
                    .map((skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(skill.name,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                              Text(
                                  '${skill.level} • ${skill.proficiencyPercent}%',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProjectsSection(UserAccount user) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Projects',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              if (!user.projectsPrivate && !_canEdit) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Public',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (user.projects.isEmpty)
            Text('No projects added yet',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 14))
          else ...[
            for (final project in user.projects) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  // Match Dashboard inner-card styling
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface)),
                    if (project.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(project.description,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                    ],
                    if (project.date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(project.date,
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCertificationsSection(UserAccount user) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified,
                  color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Certifications',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface)),
              if (!user.certificationsPrivate && !_canEdit) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Public',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (user.certifications.isEmpty)
            Text('No certifications added yet',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                    fontSize: 14))
          else ...[
            for (final certification in user.certifications) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  // Match Dashboard inner-card styling
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(certification.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface)),
                    if (certification.issuer.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(certification.issuer,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
                    ],
                    if (certification.date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(certification.date,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.getTextMuted(context))),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(String title, bool isPrivate, String type) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppTheme.getTextPrimary(context),
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isPrivate
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrivate
                  ? Colors.red.withOpacity(0.3)
                  : Colors.green.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPrivate ? Icons.lock : Icons.public,
                size: 14,
                color: isPrivate ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                isPrivate ? 'Private' : 'Public',
                style: TextStyle(
                  color: isPrivate ? Colors.red : Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isPrivate,
          onChanged: (value) async {
            await AppStore().toggleProfilePrivacy(type);
            await _initControllers(); // Refresh display
          },
          activeThumbColor: AppTheme.primary,
        ),
      ],
    );
  }
}
