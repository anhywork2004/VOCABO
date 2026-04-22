import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/bubble_background.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isDone = false;

  // Password strength
  double get _strength {
    final p = _newPassCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.length >= 12) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9!@#\$%^&*]').hasMatch(p)) s += 0.25;
    return s;
  }

  Color get _strengthColor {
    if (_strength <= 0.25) return Colors.red;
    if (_strength <= 0.5) return Colors.orange;
    if (_strength <= 0.75) return Colors.amber;
    return Colors.green;
  }

  String get _strengthLabel {
    if (_strength <= 0.25) return 'Weak';
    if (_strength <= 0.5) return 'Fair';
    if (_strength <= 0.75) return 'Good';
    return 'Strong';
  }

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Call Cloud Function to change password
      final callable =
      FirebaseFunctions.instance.httpsCallable('resetPasswordWithOtp');
      await callable.call({
        'email': widget.email,
        'newPassword': _newPassCtrl.text,
      });

      if (!mounted) return;
      setState(() => _isDone = true);

      // Auto-navigate to login after 2.5s
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          // Pop all routes back to login
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } on FirebaseFunctionsException catch (e) {
      _showSnack(e.message ?? 'Failed to reset password');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback toggleObscure,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5B7BFE), size: 20),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.grey.shade500,
          size: 20,
        ),
        onPressed: toggleObscure,
      ),
      filled: true,
      fillColor: const Color(0xFFF6F8FC),
      contentPadding:
      const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide:
        const BorderSide(color: Color(0xFF5B7BFE), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1.4),
      ),
    );
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _isDone
                            ? Container(
                          key: const ValueKey('done'),
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: 36,
                          ),
                        )
                            : Container(
                          key: const ValueKey('lock'),
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0x155B7BFE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_outlined,
                            color: Color(0xFF5B7BFE),
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isDone
                              ? "Password Updated!"
                              : "Set New Password",
                          key: ValueKey(_isDone),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B1D28),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isDone
                            ? "Your password has been changed successfully. Redirecting to login..."
                            : "Create a strong new password for\n${widget.email}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF7A8091),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Card ─────────────────────────────────────────────
                      if (!_isDone)
                        Container(
                          padding:
                          const EdgeInsets.fromLTRB(22, 24, 22, 20),
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── New Password ──────────────────────────
                                TextFormField(
                                  controller: _newPassCtrl,
                                  obscureText: _obscureNew,
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please enter a new password';
                                    }
                                    if (v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                  decoration: _inputStyle(
                                    label: 'New Password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscureNew,
                                    toggleObscure: () => setState(
                                            () => _obscureNew = !_obscureNew),
                                  ),
                                ),

                                // ── Strength bar ──────────────────────────
                                if (_newPassCtrl.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: _strength,
                                            backgroundColor:
                                            Colors.grey.shade200,
                                            color: _strengthColor,
                                            minHeight: 5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        _strengthLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _strengthColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 16),

                                // ── Confirm Password ──────────────────────
                                TextFormField(
                                  controller: _confirmPassCtrl,
                                  obscureText: _obscureConfirm,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (v != _newPassCtrl.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  decoration: _inputStyle(
                                    label: 'Confirm Password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscureConfirm,
                                    toggleObscure: () => setState(() =>
                                    _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Requirements hint ─────────────────────
                                _buildRequirements(),

                                const SizedBox(height: 24),

                                // ── Submit Button ─────────────────────────
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
                                      borderRadius:
                                      BorderRadius.circular(18),
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
                                      onPressed: _isLoading
                                          ? null
                                          : _resetPassword,
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
                                      child: _isLoading
                                          ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          valueColor:
                                          AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                          : const Text(
                                        "UPDATE PASSWORD",
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
                              ],
                            ),
                          ),
                        ),

                      // ── Success card ──────────────────────────────────────
                      if (_isDone)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const LinearProgressIndicator(
                                backgroundColor: Color(0xFFE8F5E9),
                                color: Colors.green,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Redirecting to login in 2.5 seconds...',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.of(context)
                                    .popUntil((route) => route.isFirst),
                                child: const Text(
                                  'Go to Login Now',
                                  style: TextStyle(
                                    color: Color(0xFF5B7BFE),
                                    fontWeight: FontWeight.w700,
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

  Widget _buildRequirements() {
    final pass = _newPassCtrl.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password requirements',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A8091),
          ),
        ),
        const SizedBox(height: 8),
        _reqRow('At least 6 characters', pass.length >= 6),
        _reqRow('At least one uppercase letter',
            RegExp(r'[A-Z]').hasMatch(pass)),
        _reqRow('At least one number or symbol',
            RegExp(r'[0-9!@#\$%^&*]').hasMatch(pass)),
      ],
    );
  }

  Widget _reqRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}