import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;

  bool get _isGoogleUser {
    return user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _bioCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _photoUrl = user?.photoURL;
    _loadExtra();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExtra() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _bioCtrl.text = doc.data()?['bio'] ?? '';
          _phoneCtrl.text = doc.data()?['phone'] ?? user?.phoneNumber ?? '';
          _photoUrl = doc.data()?['photoURL'] ?? user?.photoURL;
        });
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await user!.updateDisplayName(_nameCtrl.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'displayName': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': user!.email,
        'photoURL': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  // ── Change password ─────────────────────────────────────────────────────────

  void _showChangePasswordSheet() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    bool obscOld = true, obscNew = true, obscConf = true;
    bool loading = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Change Password',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Enter your current password then choose a new one.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),
              _pwField(oldCtrl, 'Current Password', obscOld,
                      () => setBS(() => obscOld = !obscOld)),
              const SizedBox(height: 14),
              _pwField(newCtrl, 'New Password', obscNew,
                      () => setBS(() => obscNew = !obscNew)),
              const SizedBox(height: 14),
              _pwField(confCtrl, 'Confirm New Password', obscConf,
                      () => setBS(() => obscConf = !obscConf)),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(errorMsg!,
                    style:
                    const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                    if (newCtrl.text != confCtrl.text) {
                      setBS(() => errorMsg = 'Passwords do not match');
                      return;
                    }
                    if (newCtrl.text.length < 6) {
                      setBS(() => errorMsg =
                      'Password must be at least 6 characters');
                      return;
                    }
                    setBS(() {
                      loading = true;
                      errorMsg = null;
                    });
                    try {
                      final cred = EmailAuthProvider.credential(
                        email: user!.email!,
                        password: oldCtrl.text,
                      );
                      await user!.reauthenticateWithCredential(cred);
                      await user!.updatePassword(newCtrl.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                            Text('Password changed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      setBS(() {
                        loading = false;
                        errorMsg = e.code == 'wrong-password'
                            ? 'Current password is incorrect'
                            : e.message ?? 'An error occurred';
                      });
                    }
                  },
                  child: loading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Update Password',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pwField(TextEditingController ctrl, String label, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
    );
  }

  // ── Pick & upload avatar ────────────────────────────────────────────────────

  Future<void> _pickAvatar() async {
    // Hiện bottom sheet chọn nguồn ảnh
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Choose photo source',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: Theme.of(ctx).colorScheme.primary),
                ),
                title: const Text('Take a photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.photo_library_outlined,
                      color: Theme.of(ctx).colorScheme.primary),
                ),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    // Người dùng đóng sheet mà không chọn
    if (source == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 400,
      );

      if (picked == null) {
        if (mounted) setState(() => _isUploadingPhoto = false);
        return;
      }

      final ref =
      FirebaseStorage.instance.ref().child('avatars/${user!.uid}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await user!.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({'photoURL': url}, SetOptions(merge: true));

      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with avatar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: cs.primary,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => setState(() => _isEditing = true),
                )
              else ...[
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Save',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.primary.withOpacity(0.7)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 36),
                      // Avatar
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? Container(
                                  color: Colors.grey[300],
                                  child:
                                  const CircularProgressIndicator())
                                  : (_photoUrl != null
                                  ? Image.network(_photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarPlaceholder())
                                  : _avatarPlaceholder()),
                            ),
                          ),
                          if (_isEditing)
                            GestureDetector(
                              onTap: _pickAvatar,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: cs.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 15),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user?.displayName ?? user?.email ?? 'User',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isGoogleUser
                                ? Icons.g_mobiledata
                                : Icons.email_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isGoogleUser
                                ? 'Google Account'
                                : 'Email Account',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personal Info ───────────────────────────────────────
                    _sectionTitle('Personal Information'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      isDark: isDark,
                      children: [
                        _field(
                          ctrl: _nameCtrl,
                          label: 'Display Name',
                          icon: Icons.person_outline,
                          enabled: _isEditing,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        _divider(),
                        _field(
                          ctrl: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          enabled: false,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _divider(),
                        _field(
                          ctrl: _phoneCtrl,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                        ),
                        _divider(),
                        _field(
                          ctrl: _bioCtrl,
                          label: 'Bio',
                          icon: Icons.info_outline,
                          enabled: _isEditing,
                          maxLines: 3,
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Security ────────────────────────────────────────────
                    if (!_isGoogleUser) ...[
                      _sectionTitle('Security'),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        isDark: isDark,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.lock_outline,
                                  color: cs.primary, size: 20),
                            ),
                            title: const Text('Change Password',
                                style:
                                TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: const Text('Update your password',
                                style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 15),
                            onTap: _showChangePasswordSheet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Account Info ────────────────────────────────────────
                    _sectionTitle('Account'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      isDark: isDark,
                      children: [
                        _infoTile(
                          icon: Icons.fingerprint,
                          label: 'User ID',
                          value: user?.uid ?? '-',
                          valueColor: cs.primary,
                          isMonospace: true,
                        ),
                        _divider(),
                        _infoTile(
                          icon: _isGoogleUser
                              ? Icons.g_mobiledata
                              : Icons.email_outlined,
                          label: 'Login Method',
                          value:
                          _isGoogleUser ? 'Google' : 'Email / Password',
                        ),
                        _divider(),
                        _infoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Email Verified',
                          value: (user?.emailVerified ?? false) ? 'Yes' : 'No',
                          valueColor: (user?.emailVerified ?? false)
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _avatarPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(Icons.person,
          size: 48, color: Theme.of(context).colorScheme.primary),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style:
    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  );

  Widget _buildInfoCard(
      {required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: enabled
              ? Theme.of(context).textTheme.bodyLarge?.color
              : Colors.grey,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,
              color: enabled ? cs.primary : Colors.grey, size: 20),
          border: InputBorder.none,
          disabledBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isMonospace = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
                fontFamily: isMonospace ? 'monospace' : null,
              )),
        ]),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}