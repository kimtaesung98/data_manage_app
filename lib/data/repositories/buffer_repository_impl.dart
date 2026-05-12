import '../../domain/entities/packet.dart';
import '../../domain/repositories/buffer_repository.dart';
import '../sources/sqlite_buffer.dart';

class BufferRepositoryImpl implements BufferRepository {
  final SqliteBuffer _buffer;

  BufferRepositoryImpl({SqliteBuffer? buffer})
      : _buffer = buffer ?? SqliteBuffer();

  @override
  Future<void> savePacket(Packet packet) => _buffer.insert(packet);

  @override
  Future<List<Packet>> getPendingPackets() => _buffer.getPending();

  @override
  Future<void> deletePacket(String id) => _buffer.remove(id);

  @override
  Future<int> getPendingCount() => _buffer.pendingCount();
}
