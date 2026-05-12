class Packet {
  final String id;
  final DateTime timestamp;
  final int heartRate;
  final int activity;
  final bool sent;

  const Packet({
    required this.id,
    required this.timestamp,
    required this.heartRate,
    required this.activity,
    this.sent = false,
  });

  String get statusLabel => sent ? '✅전송완료' : '⏳대기중';
}
