import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/packet.dart';
import '../models/packet_model.dart';

class FirestoreSource {
  final FirebaseFirestore _firestore;

  FirestoreSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> uploadPacket(Packet packet) async {
    final model = packet is PacketModel
        ? packet
        : PacketModel(
            id: packet.id,
            timestamp: packet.timestamp,
            heartRate: packet.heartRate,
            activity: packet.activity,
            sent: true,
          );
    await _firestore
        .collection('packets')
        .doc(model.id)
        .set(model.toFirestore());
  }
}
