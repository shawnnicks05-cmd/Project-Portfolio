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
  final GlobalKey<_LoginFormState> _loginFormKey = GlobalKey<_LoginFormState>();
  String? _pendingAutoFillEmail;
  String? _pendingAutoFillPassword;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    print('Tab changed to index: ${_tab.index}');
    print('Pending auto-fill data: email=$_pendingAutoFillEmail, password=$_pendingAutoFillPassword');
    print('Login form key current state: ${_loginFormKey.currentState != null}');
    
    // If we have pending auto-fill data and switched to login tab (index 0)
    if (_pendingAutoFillEmail != null && 
        _pendingAutoFillPassword != null && 
        _tab.index == 0) {
      print('Attempting auto-fill...');
      // Small delay to ensure tab animation is complete
      Future.delayed(const Duration(milliseconds: 200), () {
        print('Delayed auto-fill attempt - mounted: $mounted, formState: ${_loginFormKey.currentState != null}');
        if (mounted && _loginFormKey.currentState != null) {
          print('Calling autoFillCredentials with: $_pendingAutoFillEmail, $_pendingAutoFillPassword');
          _loginFormKey.currentState!.autoFillCredentials(
            _pendingAutoFillEmail!,
            _pendingAutoFillPassword!,
          );
          // Clear pending data
          setState(() {
            _pendingAutoFillEmail = null;
            _pendingAutoFillPassword = null;
          });
          print('Auto-fill completed and pending data cleared');
        } else {
          print('Auto-fill failed - mounted or form state null');
        }
      });
    }
  }

  void _handleAutoFill(String email, String password) {
    print('Auto-fill handler called with: email=$email, password=$password');
    
    // Always switch to login tab and wait for it to complete
    _tab.animateTo(0);
    
    // Wait for tab animation to complete, then auto-fill
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _loginFormKey.currentState != null) {
        print('Auto-filling credentials after tab switch');
        _loginFormKey.currentState!.autoFillCredentials(email, password);
        print('Auto-fill completed successfully');
      } else {
        print('Auto-fill failed - form state not available');
        // Try one more time with longer delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _loginFormKey.currentState != null) {
            _loginFormKey.currentState!.autoFillCredentials(email, password);
            print('Auto-fill completed on retry');
          }
        });
      }
    });
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
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tab,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.textMuted,
                        indicator: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
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
                          _LoginForm(key: _loginFormKey),
                          _RegisterForm(
                            tabController: _tab,
                            onAutoFill: _handleAutoFill,
                          ),
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
  const _LoginForm({super.key});

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
    final ok = await AppStore().login(_email.text.trim(), _pass.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _error = 'No account found with that email or incorrect password.';
        _loading = false;
      });
    }
  }

  void autoFillCredentials(String email, String password) {
    print('autoFillCredentials called with: email=$email, password=$password');
    print('Current email text before: ${_email.text}');
    print('Current password text before: ${_pass.text}');
    
    setState(() {
      _email.text = email;
      _pass.text = password;
    });
    
    print('Current email text after: ${_email.text}');
    print('Current password text after: ${_pass.text}');
    print('Auto-fill credentials set successfully');
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
  final Function(String email, String password)? onAutoFill;
  const _RegisterForm({required this.tabController, this.onAutoFill});

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
  final _address = TextEditingController();
  final _bio = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _courseFocus = FocusNode();
  final _studentIdFocus = FocusNode();
  final _addressFocus = FocusNode();
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
      _address,
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
      _addressFocus,
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
      password: _password.text.trim(),
      userType: _userType,
      course: _course.text.trim(),
      yearLevel: _yearLevel,
      studentId: _studentId.text.trim(),
      address: _address.text.trim(),
      avatarInitials: initials,
      bio: _bio.text.trim(),
    );

    // Store credentials before any state changes
    final email = _email.text.trim();
    final password = _password.text.trim();
    
    final ok = await AppStore().createAccount(account);
    if (!mounted) return;
    if (ok) {
      print('Account created successfully with email: $email');

      setState(() {
        _success = 'Account created successfully! You can now sign in.';
        _error = null;
        _loading = false;
      });

      // Trigger auto-fill using the parent's handler
      widget.onAutoFill?.call(email, password);

      // Clear the registration form after a delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          print('Clearing registration form');
          _name.clear();
          _phone.clear();
          _course.clear();
          _studentId.clear();
          _address.clear();
          _bio.clear();
          setState(() {
            _userType = 'Student';
            _yearLevel = '1st Year';
          });
        }
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
                          FocusScope.of(context).requestFocus(_addressFocus)),
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
            _field(_address, 'Address', Icons.location_on_outlined,
                focusNode: _addressFocus,
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
