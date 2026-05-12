import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bridge_provider.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bridge = context.watch<BridgeProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('관리자 설정',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section('연결 정보'),
          _Card([
            _Row('블루투스 상태', bridge.isScanning ? '● 스캔 중' : '○ 비활성'),
            _Row('네트워크', bridge.isOnline ? '● WiFi 연결됨' : '○ 오프라인'),
            _Row('SQLite 버퍼 대기', '${bridge.pendingCount}개'),
          ]),
          const SizedBox(height: 24),
          _Section('전송 속도 설정'),
          _Card([
            _IntervalTile(
              label: '실시간 (RT)',
              value: StreamInterval.realtime,
              current: bridge.interval,
              onTap: bridge.setInterval,
            ),
            _IntervalTile(
              label: '1초마다',
              value: StreamInterval.one,
              current: bridge.interval,
              onTap: bridge.setInterval,
            ),
            _IntervalTile(
              label: '3초마다',
              value: StreamInterval.three,
              current: bridge.interval,
              onTap: bridge.setInterval,
            ),
            _IntervalTile(
              label: '5초마다',
              value: StreamInterval.five,
              current: bridge.interval,
              onTap: bridge.setInterval,
            ),
          ]),
          const SizedBox(height: 24),
          _Section('패킷 통계'),
          _Card([
            _Row('누적 수신', '${bridge.packetLog.length}개'),
            _Row('전송 완료',
                '${bridge.packetLog.where((p) => p.sent).length}개'),
            _Row(
              '전송 대기',
              '${bridge.packetLog.where((p) => !p.sent).length}개',
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8),
        ),
      );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card(this.children);

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: children),
      );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        title: Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 14)),
        trailing:
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      );
}

class _IntervalTile extends StatelessWidget {
  final String label;
  final StreamInterval value;
  final StreamInterval current;
  final void Function(StreamInterval) onTap;

  const _IntervalTile({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return ListTile(
      dense: true,
      title: Text(label,
          style: TextStyle(
              color: selected ? Colors.tealAccent : Colors.white70,
              fontSize: 14)),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Colors.tealAccent : Colors.white24,
        size: 20,
      ),
      onTap: () => onTap(value),
    );
  }
}
