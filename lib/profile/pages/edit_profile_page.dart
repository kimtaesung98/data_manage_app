import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _avatarCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileProvider>().profile;
    _nicknameCtrl = TextEditingController(text: profile?.nickname ?? '');
    _avatarCtrl = TextEditingController(text: profile?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<ProfileProvider>();
    await provider.updateProfile(
      nickname: _nicknameCtrl.text.trim().isEmpty
          ? null
          : _nicknameCtrl.text.trim(),
      avatarUrl: _avatarCtrl.text.trim().isEmpty
          ? null
          : _avatarCtrl.text.trim(),
    );
    if (!mounted) return;
    if (provider.error == null) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileProvider>().status ==
        ProfileStatus.loading;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('프로필 편집',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF7C5CFC)),
                  )
                : const Text('저장',
                    style: TextStyle(
                        color: Color(0xFF7C5CFC), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AvatarPreview(controller: _avatarCtrl),
            const SizedBox(height: 28),
            _Label('닉네임'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nicknameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('표시 이름을 입력하세요'),
              validator: (v) {
                if (v != null && v.trim().length > 30) {
                  return '닉네임은 30자 이하로 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _Label('프로필 사진 URL'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _avatarCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('https://example.com/photo.jpg'),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || uri.scheme != 'https') {
                    return 'https:// 로 시작하는 URL을 입력하세요';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C5CFC)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
      );
}

class _AvatarPreview extends StatefulWidget {
  final TextEditingController controller;
  const _AvatarPreview({required this.controller});

  @override
  State<_AvatarPreview> createState() => _AvatarPreviewState();
}

class _AvatarPreviewState extends State<_AvatarPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFF7C5CFC).withOpacity(0.2),
        backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
        onBackgroundImageError: url.isNotEmpty ? (_, __) {} : null,
        child: url.isEmpty
            ? const Icon(Icons.person, size: 48, color: Color(0xFF7C5CFC))
            : null,
      ),
    );
  }
}
