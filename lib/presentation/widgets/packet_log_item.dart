import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/packet.dart';

class PacketLogItem extends StatelessWidget {
  final Packet packet;

  const PacketLogItem({super.key, required this.packet});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(packet.timestamp);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '[$time] 심박:${packet.heartRate}bpm / 활동:${packet.activity}% | 상태: ${packet.statusLabel}',
        style: TextStyle(
          color: packet.sent ? Colors.greenAccent[200] : Colors.white70,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
