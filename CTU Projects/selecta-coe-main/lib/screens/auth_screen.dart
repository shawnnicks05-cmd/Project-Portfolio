// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/app_store.dart';
import '../models/models.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Logo
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppTheme.primary,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/LOGO.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECTA-COE',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 7,
                        ),
                      ),
                      Text(
                        '   Student Electronic Tracker',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 250, 248, 248)
                                  .withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppTheme.textPrimary,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Sign In'),
                          Tab(text: 'Create Account'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 480,
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          const _LoginForm(),
                          _RegisterForm(tabController: _tab),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Demo: any password works
    final ok = await AppStore().login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _error = 'No account found with that email.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome!',
              style: TextStyle(
                  letterSpacing: 3,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Sign in to your account',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          TextFormField(
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_passFocus),
            style: const TextStyle(color: AppTheme.textPrimary),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            focusNode: _passFocus,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            style: const TextStyle(color: AppTheme.textPrimary),
            controller: _pass,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 249, 245, 245), fontSize: 13)),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Demo: use maria.santos@ctu.edu.ph\nPassword: password123',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  final TabController tabController;
  const _RegisterForm({required this.tabController});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _course = TextEditingController();
  final _studentId = TextEditingController();
  final _location = TextEditingController();
  final _bio = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _courseFocus = FocusNode();
  final _studentIdFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String _userType = 'Student';
  String _yearLevel = '1st Year';
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  final _years = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year'];
  final _userTypes = ['Student', 'Professor'];

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
      _password
    ]) {
      c.dispose();
    }
    for (final node in [
      _nameFocus,
      _emailFocus,
      _phoneFocus,
      _courseFocus,
      _studentIdFocus,
      _locationFocus,
      _bioFocus,
      _passwordFocus,
    ]) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final initials = _name.text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final account = UserAccount(
      id: const Uuid().v4(),
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      password: _password.text,
      userType: _userType,
      course: _course.text.trim(),
      yearLevel: _yearLevel,
      studentId: _studentId.text.trim(),
      location: _location.text.trim(),
      avatarInitials: initials,
      bio: _bio.text.trim(),
    );

    final ok = await AppStore().createAccount(account);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _success = 'Account created successfully! You can now sign in.';
        _error = null;
        _loading = false;
        // Clear the registration form
        _name.clear();
        _email.clear();
        _phone.clear();
        _password.clear();
        _course.clear();
        _studentId.clear();
        _location.clear();
        _bio.clear();
        setState(() {
          _userType = 'Student';
          _yearLevel = '1st Year';
        });
        // Switch to login tab
        widget.tabController.animateTo(0);
      });
    } else {
      setState(() {
        _error = 'An account with this email already exists.';
        _success = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create account',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            _field(_name, 'Full Name', Icons.person_outline,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _userType,
              decoration: const InputDecoration(labelText: 'User Type'),
              items: _userTypes
                  .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textPrimary),
                      )))
                  .toList(),
              onChanged: (v) => setState(() => _userType = v!),
            ),
            const SizedBox(height: 10),
            _field(_email, 'Email', Icons.email_outlined,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
                keyboard: TextInputType.emailAddress,
                validator: (v) =>
                    v!.contains('@') ? null : 'Enter a valid email'),
            const SizedBox(height: 10),
            _field(_phone, 'Phone', Icons.phone_outlined,
                focusNode: _phoneFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_courseFocus),
                keyboard: TextInputType.phone),
            const SizedBox(height: 10),
            _field(_course, 'Course / Program', Icons.book_outlined,
                focusNode: _courseFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_studentIdFocus),
                validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field(_studentId, 'Student ID', Icons.badge_outlined,
                      focusNode: _studentIdFocus,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_locationFocus)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _yearLevel,
                    decoration: const InputDecoration(labelText: 'Year Level'),
                    items: _years
                        .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(
                              y,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textPrimary),
                            )))
                        .toList(),
                    onChanged: (v) => setState(() => _yearLevel = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _field(_location, 'Location', Icons.location_on_outlined,
                focusNode: _locationFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_bioFocus)),
            const SizedBox(height: 10),
            TextFormField(
              focusNode: _bioFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              style: const TextStyle(color: AppTheme.textPrimary),
              controller: _bio,
              keyboardType: TextInputType.text,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Short bio (optional)',
                prefixIcon: Icon(Icons.comment_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              focusNode: _passwordFocus,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              style: const TextStyle(color: AppTheme.textPrimary),
              controller: _password,
              obscureText: _obscure,
              validator: (v) => v!.isEmpty
                  ? 'Password is required'
                  : v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      size: 18),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style:
                        const TextStyle(color: AppTheme.danger, fontSize: 13)),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_success!,
                    style: const TextStyle(color: Colors.green, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard,
      FocusNode? focusNode,
      TextInputAction? textInputAction,
      void Function(String)? onFieldSubmitted,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }
}
