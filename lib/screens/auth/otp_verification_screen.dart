import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../providers/fleet_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final bool isSignup;
  final String displayName;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.isSignup,
    this.displayName = '',
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;
  int _resendSeconds = 30;
  Timer? _timer;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNodes[0].requestFocus();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds == 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildBackButton(),
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildOtpBoxes(),
              const SizedBox(height: 16),
              if (_error != null) _buildError(),
              const SizedBox(height: 32),
              _buildVerifyButton(),
              const SizedBox(height: 24),
              _buildResendRow(),
              const Spacer(),
              _buildSecurityNote(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BACK BUTTON ─────────────────────────────────────────────────────────

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 18),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.1),
            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.sms_outlined, color: AppTheme.accent, size: 28),
        ),
        const SizedBox(height: 20),
        const Text(
          'Verify your number',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(text: 'Enter the 6-digit code sent to '),
              TextSpan(
                text: widget.phoneNumber,
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── OTP BOXES ───────────────────────────────────────────────────────────

  Widget _buildOtpBoxes() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final dx = _shakeController.isAnimating
            ? (4.0 * (_shakeController.value < 0.5 ? _shakeController.value : 1 - _shakeController.value) - 1) * 8
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) => _otpBox(i)),
      ),
    );
  }

  Widget _otpBox(int index) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final hasFocus = _focusNodes[index].hasFocus;

    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: hasValue ? AppTheme.accent : AppTheme.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          filled: true,
          fillColor: hasFocus
              ? AppTheme.accent.withOpacity(0.06)
              : (hasValue ? AppTheme.surface : const Color(0xFF0D1520)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasValue ? AppTheme.accent.withOpacity(0.5) : AppTheme.border,
              width: hasValue ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
          // Auto-verify when all 6 digits entered
          if (_otpCode.length == 6) {
            _verifyOtp();
          }
        },
      ),
    );
  }

  // ─── ERROR ───────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
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

  // ─── VERIFY BUTTON ──────────────────────────────────────────────────────

  Widget _buildVerifyButton() {
    final complete = _otpCode.length == 6;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_loading || !complete) ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.accent.withOpacity(0.2),
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
                    Icons.verified_outlined,
                    size: 20,
                    color: complete ? Colors.black : Colors.black.withOpacity(0.3),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'VERIFY & CONTINUE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 15,
                      color: complete ? Colors.black : Colors.black.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── RESEND ──────────────────────────────────────────────────────────────

  Widget _buildResendRow() {
    return Center(
      child: _resendSeconds > 0
          ? RichText(
              text: TextSpan(
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                children: [
                  const TextSpan(text: 'Resend code in '),
                  TextSpan(
                    text: '${_resendSeconds}s',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: _resendOtp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: AppTheme.accent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'RESEND CODE',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── SECURITY NOTE ──────────────────────────────────────────────────────

  Widget _buildSecurityNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.green.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your number is used only for verification and fleet security. We never share it.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) return;
    setState(() { _loading = true; _error = null; });

    try {
      if (kDemoMode) {
        // Demo mode: accept any 6-digit code
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (widget.isSignup && widget.displayName.isNotEmpty) {
        await FirebaseAuth.instance.currentUser
            ?.updateDisplayName(widget.displayName);
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      _shakeController.forward(from: 0);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() => _error = e.code == 'invalid-verification-code'
          ? 'Incorrect code. Please try again.'
          : 'Verification failed. Please try again.');
    } catch (e) {
      _shakeController.forward(from: 0);
      setState(() => _error = e.toString());
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resendOtp() async {
    _startTimer();
    if (kDemoMode) return;

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _error = 'Failed to resend. Please try again.');
        }
      },
      codeSent: (_, __) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Code resent successfully'),
              backgroundColor: AppTheme.green.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }
}
