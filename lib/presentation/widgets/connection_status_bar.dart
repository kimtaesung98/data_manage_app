import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bridge_provider.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bridge = context.watch<BridgeProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black38,
      child: Row(
        children: [
          _Chip(
            icon: Icons.bluetooth,
            label: bridge.isScanning ? 'BT 연결됨' : 'BT 없음',
            color: bridge.isScanning ? Colors.tealAccent : Colors.grey,
          ),
          const SizedBox(width: 16),
          _Chip(
            icon: Icons.wifi,
            label: bridge.isOnline ? 'WiFi 연결됨' : '오프라인',
            color: bridge.isOnline ? Colors.greenAccent : Colors.redAccent,
          ),
          const Spacer(),
          if (bridge.pendingCount > 0)
            _Chip(
              icon: Icons.hourglass_bottom,
              label: '버퍼: ${bridge.pendingCount}개',
              color: Colors.orangeAccent,
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      );
}
