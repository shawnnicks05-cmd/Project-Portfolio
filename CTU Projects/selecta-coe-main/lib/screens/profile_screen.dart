// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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

    setState(() {
      _displayUser = displayUser;
      // Only allow editing if it's the user's own profile and not in viewOnly mode
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
        _location = TextEditingController(text: _displayUser!.location);
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
      backgroundColor: AppTheme.surface,
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
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.primary),
                title: const Text('Take Photo',
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
      final picked = await _picker.getImage(source: source);
      if (picked != null) {
        setState(() => _pickedImageFile = File(picked.path));
      }
    }
  }

  void _saveChanges() {
    // Use picked image path as avatarUrl (local file path).
    // In a production app you would upload to cloud storage and store the URL.
    final newAvatarUrl = _pickedImageFile != null
        ? _pickedImageFile!.path
        : _displayUser?.avatarUrl ?? '';

    final updatedUser = UserAccount(
      id: _displayUser!.id,
      name: _name?.text.trim() ?? '',
      email: _email?.text.trim() ?? '',
      phone: _phone?.text.trim() ?? '',
      password: _displayUser!.password,
      userType: _displayUser!.userType,
      course: _course?.text.trim() ?? '',
      yearLevel: _yearLevelController?.text.trim() ?? '1st Year',
      studentId: _studentId?.text.trim() ?? '',
      location: _location?.text.trim() ?? '',
      avatarInitials: _displayUser!.avatarInitials,
      avatarUrl: newAvatarUrl,
      bio: _bio?.text.trim() ?? '',
      instagramUrl: _instagramUrl?.text.trim() ?? '',
      facebookUrl: _facebookUrl?.text.trim() ?? '',
      skillCategories: _displayUser!.skillCategories,
      projects: _displayUser!.projects,
      certifications: _displayUser!.certifications,
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

  void _showRequestPermissionDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Request Permission',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a permission request to view ${_displayUser!.name}\'s private profile information.',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Explain why you need access to their profile...',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_displayUser != null) {
                  await AppStore().requestPermission(
                    _displayUser!.id,
                    messageController.text.trim().isEmpty
                        ? 'I would like to request access to view your profile information.'
                        : messageController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Permission request sent successfully'),
                        backgroundColor: AppTheme.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Request'),
            ),
          ],
        );
      },
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
        style: const TextStyle(
            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    if (_displayUser == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final user = _displayUser!;
    return Container(
      color: AppTheme.surfaceVariant,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name header
          Center(
            child: Column(
              children: [
                _buildAvatar(user),
                if (_editing && _canEdit)
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
                  Text('${user.course}  ${user.yearLevel}',
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

          //  Request Permission button (only when viewing other users' profiles)
          if (widget.viewOnly && !_canEdit && _displayUser != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showRequestPermissionDialog,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Request Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
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

          //  Personal Information card
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
                            ? _editField(
                                _studentId!, 'Student ID', Icons.badge_outlined)
                            : Container()),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _yearLevelController != null
                            ? _editField(_yearLevelController!, 'Year Level',
                                Icons.school_outlined)
                            : Container()),
                  ]),
                  const SizedBox(height: 12),
                  if (_location != null)
                    _editField(
                        _location!, 'Location', Icons.location_on_outlined),
                  const SizedBox(height: 12),
                  if (_bio != null)
                    _editField(_bio!, 'Bio', Icons.comment_outlined,
                        keyboard: TextInputType.text, minLines: 1, maxLines: 1),
                  const SizedBox(height: 12),
                  if (_instagramUrl != null)
                    _editField(_instagramUrl!, 'Instagram URL', Icons.camera,
                        keyboard: TextInputType.url),
                  const SizedBox(height: 12),
                  if (_facebookUrl != null)
                    _editField(_facebookUrl!, 'Facebook URL', Icons.facebook,
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
                        const FaIcon(FontAwesomeIcons.facebook,
                            size: 16, color: AppTheme.textMuted),
                        'Facebook',
                        user.facebookUrl),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          //  Summary card
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
                    SummaryItem(
                        label: 'Skills',
                        value: '${user.totalSkills}',
                        color: AppTheme.primary),
                    SummaryItem(
                        label: 'Avg',
                        value: '${user.avgCompetency.round()}%',
                        color: AppTheme.success),
                    SummaryItem(
                        label: 'Projects',
                        value: '${user.projects.length}',
                        color: AppTheme.warning),
                    SummaryItem(
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
}
