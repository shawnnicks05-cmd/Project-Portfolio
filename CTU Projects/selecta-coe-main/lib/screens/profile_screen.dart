// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId, this.viewOnly = false});

  final String? userId;
  final bool viewOnly;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late UserAccount _displayUser;

  // Picked image file (local, before save)
  File? _pickedImageFile;

  late TextEditingController _name;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _course;
  late TextEditingController _studentId;
  late TextEditingController _location;
  late TextEditingController _bio;
  late TextEditingController _instagramUrl;
  late TextEditingController _facebookUrl;
  late String _yearLevel;

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

  final _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year'];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _displayUser = widget.userId != null
        ? AppStore().getUserById(widget.userId!) ?? AppStore().currentUser!
        : AppStore().currentUser!;

    _name = TextEditingController(text: _displayUser.name);
    _email = TextEditingController(text: _displayUser.email);
    _phone = TextEditingController(text: _displayUser.phone);
    _course = TextEditingController(text: _displayUser.course);
    _studentId = TextEditingController(text: _displayUser.studentId);
    _location = TextEditingController(text: _displayUser.location);
    _bio = TextEditingController(text: _displayUser.bio);
    _instagramUrl = TextEditingController(text: _displayUser.instagramUrl);
    _facebookUrl = TextEditingController(text: _displayUser.facebookUrl);
    _yearLevel = _years.contains(_displayUser.yearLevel)
        ? _displayUser.yearLevel
        : '1st Year';
  }

  void _takeSnapshot() {
    _snapName = _name.text;
    _snapEmail = _email.text;
    _snapPhone = _phone.text;
    _snapCourse = _course.text;
    _snapStudentId = _studentId.text;
    _snapLocation = _location.text;
    _snapBio = _bio.text;
    _snapInstagramUrl = _instagramUrl.text;
    _snapFacebookUrl = _facebookUrl.text;
    _snapYearLevel = _yearLevel;
    _snapPickedImageFile = _pickedImageFile;
  }

  void _restoreSnapshot() {
    _name.text = _snapName;
    _email.text = _snapEmail;
    _phone.text = _snapPhone;
    _course.text = _snapCourse;
    _studentId.text = _snapStudentId;
    _location.text = _snapLocation;
    _bio.text = _snapBio;
    _instagramUrl.text = _snapInstagramUrl;
    _facebookUrl.text = _snapFacebookUrl;
    setState(() {
      _yearLevel = _snapYearLevel;
      _pickedImageFile = _snapPickedImageFile;
    });
  }

  void _startEditing() {
    _takeSnapshot();
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    _restoreSnapshot();
    setState(() => _editing = false);
  }

  /// Show a bottom sheet to choose camera or gallery
  Future<void> _pickImage() async {
    if (!_editing) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choose Profile Photo',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.primary),
                title: const Text('Take a photo',
                    style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.primary),
                title: const Text('Choose from gallery',
                    style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_pickedImageFile != null || _displayUser.avatarUrl.isNotEmpty)
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

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked != null) {
      setState(() => _pickedImageFile = File(picked.path));
    }
  }

  void _saveChanges() {
    // Use picked image path as avatarUrl (local file path).
    // In a production app you would upload to cloud storage and store the URL.
    final newAvatarUrl = _pickedImageFile != null
        ? _pickedImageFile!.path
        : _displayUser.avatarUrl;

    final updatedUser = UserAccount(
      id: _displayUser.id,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _displayUser.password,
      course: _course.text.trim(),
      yearLevel: _yearLevel,
      studentId: _studentId.text.trim(),
      location: _location.text.trim(),
      avatarInitials: _displayUser.avatarInitials,
      avatarUrl: newAvatarUrl,
      bio: _bio.text.trim(),
      instagramUrl: _instagramUrl.text.trim(),
      facebookUrl: _facebookUrl.text.trim(),
      skillCategories: _displayUser.skillCategories,
      projects: _displayUser.projects,
      certifications: _displayUser.certifications,
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
    for (final c in [
      _name,
      _email,
      _phone,
      _course,
      _studentId,
      _location,
      _bio,
      _instagramUrl,
      _facebookUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Avatar widget ────────────────────────────────────────────────────────

  Widget _buildAvatar(UserAccount user) {
    // Priority: newly picked file → existing avatarUrl (local or network) → initials
    Widget avatarChild;

    if (_pickedImageFile != null) {
      avatarChild = Image.file(
        _pickedImageFile!,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      );
    } else if (user.avatarUrl.isNotEmpty) {
      final isLocalFile = user.avatarUrl.startsWith('/');
      avatarChild = isLocalFile
          ? Image.file(
              File(user.avatarUrl),
              fit: BoxFit.cover,
              width: 96,
              height: 96,
              errorBuilder: (_, __, ___) =>
                  _initialsWidget(user.avatarInitials),
            )
          : Image.network(
              user.avatarUrl,
              fit: BoxFit.cover,
              width: 96,
              height: 96,
              errorBuilder: (_, __, ___) =>
                  _initialsWidget(user.avatarInitials),
            );
    } else {
      avatarChild = _initialsWidget(user.avatarInitials);
    }

    return GestureDetector(
      onTap: _editing ? _pickImage : null,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
          // Camera badge — only visible in edit mode
          if (_editing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.surface, width: 2),
                ),
                child:
                    const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _displayUser;
    return Container(
      color: AppTheme.surfaceVariant,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar + name header ───────────────────────────────────────
          Center(
            child: Column(
              children: [
                _buildAvatar(user),
                if (_editing)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Tap photo to change',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ),
                const SizedBox(height: 10),
                if (!_editing) ...[
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text('Cebu Technological University',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${user.course} • ${user.yearLevel}',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(user.studentId,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        user.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Edit / Cancel / Save buttons ───────────────────────────────
          if (!widget.viewOnly) ...[
            if (!_editing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
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
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.border),
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
                        backgroundColor: AppTheme.success,
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

          // ── Personal Information card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Information',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                if (_editing) ...[
                  _editField(_name, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 12),
                  _editField(_email, 'Email', Icons.email_outlined,
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _editField(_phone, 'Phone', Icons.phone_outlined,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 12),
                  _editField(_course, 'Course / Program', Icons.book_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _editField(
                            _studentId, 'Student ID', Icons.badge_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _yearLevel,
                        decoration:
                            const InputDecoration(labelText: 'Year Level'),
                        items: _years
                            .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y,
                                    style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _yearLevel = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _editField(_location, 'Location', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  _editField(_bio, 'Bio', Icons.comment_outlined,
                      keyboard: TextInputType.text, minLines: 1, maxLines: 1),
                  const SizedBox(height: 12),
                  _editField(_instagramUrl, 'Instagram URL', Icons.camera,
                      keyboard: TextInputType.url),
                  const SizedBox(height: 12),
                  _editField(_facebookUrl, 'Facebook URL', Icons.facebook,
                      keyboard: TextInputType.url),
                ] else ...[
                  _infoRow(Icons.email_outlined, 'Email', user.email),
                  _infoRow(Icons.phone_outlined, 'Phone', user.phone),
                  _infoRow(Icons.book_outlined, 'Course', user.course),
                  _infoRow(Icons.school_outlined, 'Year Level', user.yearLevel),
                  _infoRow(Icons.badge_outlined, 'Student ID', user.studentId),
                  _infoRow(
                      Icons.location_on_outlined, 'Location', user.location),
                  _infoRow(Icons.school_outlined, 'School',
                      'Cebu Technological University'),
                  if (user.bio.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text('Bio',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textMuted)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(user.bio,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textPrimary)),
                    ),
                  ],
                  if (user.instagramUrl.isNotEmpty ||
                      user.facebookUrl.isNotEmpty)
                    const Divider(color: AppTheme.border),
                  if (user.instagramUrl.isNotEmpty)
                    _socialLinkRow(
                        const FaIcon(FontAwesomeIcons.instagram,
                            size: 16, color: AppTheme.textMuted),
                        'Instagram',
                        user.instagramUrl),
                  if (user.facebookUrl.isNotEmpty)
                    _socialLinkRow(
                        const Icon(Icons.facebook,
                            size: 16, color: AppTheme.textMuted),
                        'Facebook',
                        user.facebookUrl),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Summary card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                        label: 'Skills',
                        value: '${user.totalSkills}',
                        color: AppTheme.primary),
                    _SummaryItem(
                        label: 'Avg',
                        value: '${user.avgCompetency.round()}%',
                        color: AppTheme.success),
                    _SummaryItem(
                        label: 'Projects',
                        value: '${user.projects.length}',
                        color: AppTheme.warning),
                    _SummaryItem(
                        label: 'Certifications',
                        value: '${user.certifications.length}',
                        color: const Color(0xFFF97316)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────────

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
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
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(url,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary)),
            ],
          ),
        ],
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
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    );
  }
}
