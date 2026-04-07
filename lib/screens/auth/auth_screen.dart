import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/fleet_provider.dart';
import 'otp_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isPhoneMode = false;

  // Email fields
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  // Phone fields
  final _phoneCtrl = TextEditingController();
  String _countryCode = '+974';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+974', 'flag': '🇶🇦', 'name': 'Qatar'},
    {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
    {'code': '+966', 'flag': '🇸🇦', 'name': 'Saudi Arabia'},
    {'code': '+973', 'flag': '🇧🇭', 'name': 'Bahrain'},
    {'code': '+968', 'flag': '🇴🇲', 'name': 'Oman'},
    {'code': '+965', 'flag': '🇰🇼', 'name': 'Kuwait'},
    {'code': '+20',  'flag': '🇪🇬', 'name': 'Egypt'},
    {'code': '+962', 'flag': '🇯🇴', 'name': 'Jordan'},
    {'code': '+961', 'flag': '🇱🇧', 'name': 'Lebanon'},
    {'code': '+91',  'flag': '🇮🇳', 'name': 'India'},
    {'code': '+92',  'flag': '🇵🇰', 'name': 'Pakistan'},
    {'code': '+63',  'flag': '🇵🇭', 'name': 'Philippines'},
    {'code': '+44',  'flag': '🇬🇧', 'name': 'UK'},
    {'code': '+1',   'flag': '🇺🇸', 'name': 'USA'},
  ];

  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _error = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isSignup => _tabController.index == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildTabs(),
              const SizedBox(height: 24),
              _buildMethodToggle(),
              const SizedBox(height: 20),
              if (_error != null) _buildError(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isPhoneMode ? _buildPhoneForm() : _buildEmailForm(),
              ),
              const SizedBox(height: 28),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              _buildDivider(),
              const SizedBox(height: 20),
              _buildSocialButtons(),
              const SizedBox(height: 16),
              if (kDemoMode) _buildDemoButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LOGO ────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.accent, Color(0xFF0066FF)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.local_taxi, color: Colors.black, size: 36),
        ),
        const SizedBox(height: 20),
        const Text(
          'MyeTaxi Tracker',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Fleet Intelligence Platform',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 0.5),
        ),
      ],
    );
  }

  // ─── TABS ────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: AppTheme.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        labelColor: Colors.black,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'SIGN IN'),
          Tab(text: 'SIGN UP'),
        ],
      ),
    );
  }

  // ─── METHOD TOGGLE ───────────────────────────────────────────────────────

  Widget _buildMethodToggle() {
    return Row(
      children: [
        _methodChip(
          icon: Icons.email_outlined,
          label: 'Email',
          selected: !_isPhoneMode,
          onTap: () => setState(() { _isPhoneMode = false; _error = null; }),
        ),
        const SizedBox(width: 10),
        _methodChip(
          icon: Icons.phone_android,
          label: 'Mobile',
          selected: _isPhoneMode,
          onTap: () => setState(() { _isPhoneMode = true; _error = null; }),
        ),
      ],
    );
  }

  Widget _methodChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AppTheme.accent : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ERROR ───────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.red.withOpacity(0.08),
        border: Border.all(color: AppTheme.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.red.withOpacity(0.8), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.red.withOpacity(0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMAIL FORM ──────────────────────────────────────────────────────────

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSignup) ...[
          _label('FULL NAME'),
          const SizedBox(height: 6),
          _inputField(
            controller: _nameCtrl,
            hint: 'e.g. Ahmed Al-Mansouri',
            icon: Icons.person_outline,
            inputType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
        ],

        _label('EMAIL ADDRESS'),
        const SizedBox(height: 6),
        _inputField(
          controller: _emailCtrl,
          hint: 'owner@company.com',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        _label('PASSWORD'),
        const SizedBox(height: 6),
        _inputField(
          controller: _passCtrl,
          hint: '••••••••',
          icon: Icons.lock_outline,
          isPassword: true,
          obscure: _obscurePass,
          onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
        ),

        if (_isSignup) ...[
          const SizedBox(height: 16),
          _label('CONFIRM PASSWORD'),
          const SizedBox(height: 6),
          _inputField(
            controller: _confirmPassCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline,
            isPassword: true,
            obscure: _obscureConfirm,
            onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ],
      ],
    );
  }

  // ─── PHONE FORM ──────────────────────────────────────────────────────────

  Widget _buildPhoneForm() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isSignup) ...[
          _label('FULL NAME'),
          const SizedBox(height: 6),
          _inputField(
            controller: _nameCtrl,
            hint: 'e.g. Ahmed Al-Mansouri',
            icon: Icons.person_outline,
            inputType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
        ],

        _label('MOBILE NUMBER'),
        const SizedBox(height: 6),
        Row(
          children: [
            // Country code picker
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1520),
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      _countryCodes.firstWhere((c) => c['code'] == _countryCode)['flag']!,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _countryCode,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.textMuted, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Phone number input
            Expanded(
              child: _inputField(
                controller: _phoneCtrl,
                hint: '5512 3456',
                icon: Icons.phone_outlined,
                inputType: TextInputType.phone,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── SHARED INPUT FIELD ──────────────────────────────────────────────────

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      textCapitalization: textCapitalization,
      obscureText: isPassword && obscure,
      inputFormatters: formatters,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: onToggleObscure,
                child: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ─── SUBMIT BUTTON ───────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final label = _isPhoneMode
        ? 'SEND OTP'
        : (_isSignup ? 'CREATE ACCOUNT' : 'SIGN IN');

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.accent.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPhoneMode ? Icons.sms_outlined : (_isSignup ? Icons.person_add : Icons.login),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── DIVIDER ─────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppTheme.textMuted.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
      ],
    );
  }

  // ─── SOCIAL BUTTONS ─────────────────────────────────────────────────────

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: _socialButton(
            label: 'Google',
            icon: Icons.g_mobiledata,
            onTap: _handleGoogleSignIn,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textPrimary, size: 28),
            const SizedBox(width: 8),
            Text(
              'Continue with $label',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DEMO BUTTON ────────────────────────────────────────────────────────

  Widget _buildDemoButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _DemoRedirect()),
        );
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.green.withOpacity(0.08),
          border: Border.all(color: AppTheme.green.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, color: AppTheme.green.withOpacity(0.8), size: 22),
            const SizedBox(width: 10),
            Text(
              'EXPLORE DEMO MODE',
              style: TextStyle(
                color: AppTheme.green.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── COUNTRY PICKER ─────────────────────────────────────────────────────

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SELECT COUNTRY',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _countryCodes.length,
                itemBuilder: (_, i) {
                  final c = _countryCodes[i];
                  final selected = c['code'] == _countryCode;
                  return ListTile(
                    leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      c['name']!,
                      style: TextStyle(
                        color: selected ? AppTheme.accent : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      c['code']!,
                      style: TextStyle(
                        color: selected ? AppTheme.accent : AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    selected: selected,
                    onTap: () {
                      setState(() => _countryCode = c['code']!);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ─── HANDLERS ───────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    setState(() { _loading = true; _error = null; });

    try {
      if (_isPhoneMode) {
        await _handlePhoneAuth();
      } else if (_isSignup) {
        await _handleEmailSignup();
      } else {
        await _handleEmailLogin();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      setState(() => _error = e.toString());
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleEmailLogin() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      throw Exception('Please fill in all fields');
    }

    if (kDemoMode) {
      // Demo: skip real auth
      return;
    }

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }

  Future<void> _handleEmailSignup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      throw Exception('Please enter your full name');
    }
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      throw Exception('Please fill in all fields');
    }
    if (_passCtrl.text.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      throw Exception('Passwords do not match');
    }

    if (kDemoMode) return;

    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    await cred.user?.updateDisplayName(_nameCtrl.text.trim());
  }

  Future<void> _handlePhoneAuth() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      throw Exception('Please enter your mobile number');
    }
    if (_isSignup && _nameCtrl.text.trim().isEmpty) {
      throw Exception('Please enter your full name');
    }

    final fullPhone = '$_countryCode${_phoneCtrl.text.trim()}';

    if (kDemoMode) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: fullPhone,
            verificationId: 'demo-verification',
            isSignup: _isSignup,
            displayName: _nameCtrl.text.trim(),
          ),
        ),
      );
      return;
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
        if (_isSignup && _nameCtrl.text.trim().isNotEmpty) {
          await FirebaseAuth.instance.currentUser
              ?.updateDisplayName(_nameCtrl.text.trim());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) setState(() => _error = _friendlyError(e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: fullPhone,
              verificationId: verificationId,
              isSignup: _isSignup,
              displayName: _nameCtrl.text.trim(),
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _handleGoogleSignIn() async {
    // Google sign-in requires google_sign_in package
    // Placeholder for future integration
    setState(() => _error = 'Google Sign-In coming soon');
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'An account with this email already exists';
      case 'weak-password': return 'Password is too weak — use at least 6 characters';
      case 'invalid-email': return 'Please enter a valid email address';
      case 'too-many-requests': return 'Too many attempts. Please try again later';
      case 'invalid-phone-number': return 'Invalid phone number format';
      case 'invalid-verification-code': return 'Incorrect OTP code';
      default: return 'Something went wrong. Please try again';
    }
  }
}

// Placeholder widget for demo redirect — gets replaced by MainShell via auth gate
class _DemoRedirect extends StatelessWidget {
  const _DemoRedirect();

  @override
  Widget build(BuildContext context) {
    // In demo mode, the auth gate shows MainShell directly
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );
  }
}
