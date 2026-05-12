import '../../domain/entities/packet.dart';

class PacketModel extends Packet {
  const PacketModel({
    required super.id,
    required super.timestamp,
    required super.heartRate,
    required super.activity,
    super.sent,
  });

  factory PacketModel.fromMap(Map<String, dynamic> map) {
    return PacketModel(
      id: map['id'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      heartRate: map['heartRate'] as int,
      activity: map['activity'] as int,
      sent: (map['sent'] as int? ?? 0) == 1,
    );
  }

  PacketModel copyWithSent(bool sent) => PacketModel(
        id: id,
        timestamp: timestamp,
        heartRate: heartRate,
        activity: activity,
        sent: sent,
      );

  Map<String, dynamic> toSqlMap() => {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'heartRate': heartRate,
        'activity': activity,
        'sent': sent ? 1 : 0,
      };

  Map<String, dynamic> toFirestore() => {
        'timestamp': timestamp.toIso8601String(),
        'heartRate': heartRate,
        'activity': activity,
        'deviceId': id.split('-').first,
      };
}
