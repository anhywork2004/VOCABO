import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/bubble_background.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 60;

  final List<TextEditingController> _controllers =
  List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(_otpLength, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  bool _hasError = false;
  String _errorMsg = '';

  int _countdown = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  // ── Auto-verify when all 6 digits entered ──────────────────────────────────
  void _onDigitChanged(int index, String value) {
    setState(() => _hasError = false);

    if (value.length == 1) {
      // Move to next box
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered → auto verify
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  void _onKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  // ── Verify OTP against Firestore ───────────────────────────────────────────
  Future<void> _verifyOtp() async {
    final code = _otpValue;
    if (code.length < _otpLength) {
      _setError('Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    try {
      final emailKey = widget.email.toLowerCase().replaceAll('.', '_');
      final doc = await FirebaseFirestore.instance
          .collection('otp_verifications')
          .doc(emailKey)
          .get();

      if (!doc.exists) {
        _setError('OTP not found. Please request a new one.');
        return;
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String? ?? '';
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = data['attempts'] as int? ?? 0;

      // Check max attempts (5)
      if (attempts >= 5) {
        _setError('Too many attempts. Please request a new OTP.');
        return;
      }

      // Check expiry
      if (DateTime.now().isAfter(expiresAt)) {
        _setError('OTP has expired. Please request a new one.');
        return;
      }

      // Increment attempt count
      await doc.reference.update({'attempts': attempts + 1});

      // Check code
      if (code != storedCode) {
        _setError('Incorrect OTP. ${4 - attempts} attempts remaining.');
        // Shake animation feedback
        _shakeBoxes();
        return;
      }

      // ✅ OTP correct → mark as verified
      await doc.reference.update({'verified': true});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } catch (e) {
      _setError('Verification failed: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── Resend OTP ─────────────────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (_countdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      final callable =
      FirebaseFunctions.instance.httpsCallable('sendOtp');
      await callable.call({'email': widget.email});

      // Clear boxes
      for (final c in _controllers) {
        c.clear();
      }
      setState(() => _hasError = false);
      _focusNodes[0].requestFocus();
      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent to your email'),
            backgroundColor: Color(0xFF5B7BFE),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMsg = msg;
        _isVerifying = false;
      });
    }
  }

  void _shakeBoxes() {
    // Clear all boxes on wrong OTP
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const BubbleBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      // ── Header ───────────────────────────────────────────
                      const SizedBox(height: 24),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0x155B7BFE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: Color(0xFF5B7BFE),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Verify OTP",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B1D28),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "We sent a 6-digit code to\n",
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF7A8091),
                              ),
                            ),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF5B7BFE),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // ── Card ─────────────────────────────────────────────
                      Container(
                        padding:
                        const EdgeInsets.fromLTRB(22, 28, 22, 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── OTP boxes ─────────────────────────────────
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                _otpLength,
                                    (i) => _OtpBox(
                                  controller: _controllers[i],
                                  focusNode: _focusNodes[i],
                                  hasError: _hasError,
                                  isVerifying: _isVerifying,
                                  onChanged: (v) => _onDigitChanged(i, v),
                                  onKeyEvent: (e) => _onKeyDown(i, e),
                                ),
                              ),
                            ),

                            // ── Error ─────────────────────────────────────
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _hasError
                                  ? Container(
                                width: double.infinity,
                                margin:
                                const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF0F0),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFFCDD2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMsg,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 24),

                            // ── Verify Button ─────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5B7BFE),
                                      Color(0xFF7B61FF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5B7BFE)
                                          .withOpacity(0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                  _isVerifying ? null : _verifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    disabledBackgroundColor:
                                    Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: _isVerifying
                                      ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                      AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                      : const Text(
                                    "VERIFY CODE",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Resend ────────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Didn't receive the code? ",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                ),
                                _countdown > 0
                                    ? Text(
                                  "Resend in ${_countdown}s",
                                  style: const TextStyle(
                                    color: Color(0xFF5B7BFE),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                )
                                    : GestureDetector(
                                  onTap: _resendOtp,
                                  child: _isResending
                                      ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF5B7BFE),
                                    ),
                                  )
                                      : const Text(
                                    "Resend",
                                    style: TextStyle(
                                      color: Color(0xFF5B7BFE),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Change Email',
                                style: TextStyle(
                                  color: Color(0xFF7A8091),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isVerifying;
  final ValueChanged<String> onChanged;
  final ValueChanged<RawKeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isVerifying,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 54,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: !isVerifying,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B1D28),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasError
                ? const Color(0xFFFFF0F0)
                : controller.text.isNotEmpty
                ? const Color(0xFFEEF2FF)
                : const Color(0xFFF6F8FC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red.shade300
                    : controller.text.isNotEmpty
                    ? const Color(0xFF5B7BFE)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red
                    : const Color(0xFF5B7BFE),
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}