import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/bridge_provider.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/packet_log_item.dart';
import 'admin_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _showAdminGate(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('관리자 인증',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '관리자 비밀번호',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.tealAccent, width: 2)),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (_) => _verify(context, ctx, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('취소', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => _verify(context, ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black87,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _verify(BuildContext rootCtx, BuildContext dialogCtx, String input) {
    if (input == AppConstants.adminPassword) {
      Navigator.pop(dialogCtx);
      Navigator.push(
        rootCtx,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else {
      ScaffoldMessenger.of(rootCtx).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 올바르지 않습니다.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bridge = context.watch<BridgeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.monitor_heart, color: Colors.tealAccent, size: 20),
            SizedBox(width: 8),
            Text(
              '모니터링 대시보드',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.admin_panel_settings, color: Colors.white60),
            tooltip: '관리자 설정',
            onPressed: () => _showAdminGate(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white60),
            tooltip: '로그아웃',
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ConnectionStatusBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '패킷 로그  •  ${bridge.packetLog.length}건',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: bridge.packetLog.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_searching,
                            size: 48, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('웨어 기기 데이터를 기다리는 중...',
                            style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: bridge.packetLog.length,
                    itemBuilder: (_, i) =>
                        PacketLogItem(packet: bridge.packetLog[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
