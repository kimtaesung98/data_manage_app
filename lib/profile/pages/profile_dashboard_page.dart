import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../chat/pages/chat_list_page.dart';
import '../../chat/providers/chat_auth_provider.dart';
import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_page.dart';

class ProfileDashboardPage extends StatefulWidget {
  const ProfileDashboardPage({super.key});

  @override
  State<ProfileDashboardPage> createState() => _ProfileDashboardPageState();
}

class _ProfileDashboardPageState extends State<ProfileDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('계정 삭제',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          '프로필 데이터가 영구 삭제됩니다. 계속하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      // Delete DB row first, then sign out via ChatAuthProvider so its
      // onAuthStateChange listener handles the session cleanup cleanly.
      await context.read<ProfileProvider>().deleteProfile();
      if (mounted) {
        await context.read<ChatAuthProvider>().signOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = context.watch<ProfileProvider>();
    final authProv = context.watch<ChatAuthProvider>();
    final User? supaUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text('내 프로필',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                color: Colors.white60, size: 20),
            tooltip: 'AI 채팅',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: '로그아웃',
            onPressed: authProv.signOut,
          ),
        ],
      ),
      body: profileProv.status == ProfileStatus.loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C5CFC)))
          : profileProv.status == ProfileStatus.error
              ? _ErrorView(
                  message: profileProv.error ?? '오류가 발생했습니다.',
                  onRetry: () => context.read<ProfileProvider>().loadProfile(),
                )
              : _DashboardBody(
                  profile: profileProv.profile,
                  supaUser: supaUser,
                  onEdit: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfilePage()),
                    );
                    if (updated == true && mounted) {
                      context.read<ProfileProvider>().loadProfile();
                    }
                  },
                  onDelete: _confirmDelete,
                ),
    );
  }
}

// ── Dashboard body ─────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  // [Fix #5] Use concrete types instead of dynamic.
  final UserProfile? profile;
  final User? supaUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DashboardBody({
    required this.profile,
    required this.supaUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final email = supaUser?.email ?? '';
    final nickname = profile?.nickname ?? email.split('@').first;
    final avatarUrl = profile?.avatarUrl;
    final updatedAt = profile?.updatedAt;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Avatar ────────────────────────────────────────────────
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFF7C5CFC).withOpacity(0.2),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        nickname.isNotEmpty
                            ? nickname[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFF7C5CFC),
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C5CFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Name ──────────────────────────────────────────────────
        Text(
          nickname,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 32),

        // ── Info cards ────────────────────────────────────────────
        _InfoCard(children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: '닉네임',
            value: profile?.nickname ?? '(설정 없음)',
          ),
          const Divider(color: Colors.white10, height: 1),
          _InfoRow(
            icon: Icons.email_outlined,
            label: '이메일',
            value: email,
          ),
          const Divider(color: Colors.white10, height: 1),
          _InfoRow(
            icon: Icons.update_rounded,
            label: '마지막 업데이트',
            value: updatedAt != null
                ? DateFormat('yyyy.MM.dd HH:mm').format(updatedAt.toLocal())
                : '-',
          ),
        ]),
        const SizedBox(height: 28),

        // ── Actions ───────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('프로필 편집'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C5CFC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_forever_outlined,
              size: 18, color: Colors.redAccent),
          label: const Text('계정 데이터 삭제',
              style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Colors.redAccent),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7C5CFC)),
            const SizedBox(width: 12),
            Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C5CFC)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
}
