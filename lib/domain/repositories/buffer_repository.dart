import '../entities/packet.dart';

abstract class BufferRepository {
  Future<void> savePacket(Packet packet);
  Future<List<Packet>> getPendingPackets();
  Future<void> deletePacket(String id);
  Future<int> getPendingCount();
}
