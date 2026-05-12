import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/network_monitor.dart';
import '../../data/models/packet_model.dart';
import '../../data/repositories/buffer_repository_impl.dart';
import '../../data/sources/bluetooth_source.dart';
import '../../data/sources/firestore_source.dart';
import '../../domain/entities/packet.dart';

enum StreamInterval { realtime, one, three, five }

/// Orchestrates the BT→WiFi→Firestore bridge.
///
/// Auto-streams when both BT data arrives and WiFi is online.
/// Buffers to SQLite when offline and flushes FIFO on reconnect.
class BridgeProvider extends ChangeNotifier {
  final BluetoothSource _bt;
  final FirestoreSource _firestore;
  final BufferRepositoryImpl _buffer;
  final NetworkMonitor _network;

  final List<Packet> _log = [];
  final List<Packet> _pendingBatch = [];

  bool _online = false;
  StreamInterval _interval = StreamInterval.one;
  int _pendingCount = 0;

  StreamSubscription<Packet>? _btSub;
  StreamSubscription<bool>? _netSub;
  Timer? _batchTimer;

  BridgeProvider({
    required BluetoothSource btSource,
    required FirestoreSource firestoreSource,
    required BufferRepositoryImpl bufferRepo,
    required NetworkMonitor networkMonitor,
  })  : _bt = btSource,
        _firestore = firestoreSource,
        _buffer = bufferRepo,
        _network = networkMonitor {
    _init();
  }

  List<Packet> get packetLog => List.unmodifiable(_log);
  bool get isOnline => _online;
  bool get isScanning => _bt.isScanning;
  StreamInterval get interval => _interval;
  int get pendingCount => _pendingCount;

  Future<void> _init() async {
    _online = await _network.isOnline;
    _netSub = _network.onlineStream.listen(_onNetworkChange);
    await _bt.startScanning();
    _btSub = _bt.packetStream.listen(_onPacket);
    await _refreshPendingCount();
  }

  void _onPacket(Packet packet) {
    _log.insert(0, packet);
    if (_log.length > 100) _log.removeLast();

    if (_online) {
      if (_interval == StreamInterval.realtime) {
        _upload(packet);
      } else {
        _pendingBatch.add(packet);
        _scheduleBatch();
      }
    } else {
      _buffer.savePacket(packet);
      _refreshPendingCount();
    }
    notifyListeners();
  }

  void _scheduleBatch() {
    if (_batchTimer?.isActive ?? false) return;
    final secs = switch (_interval) {
      StreamInterval.realtime => 0,
      StreamInterval.one => 1,
      StreamInterval.three => 3,
      StreamInterval.five => 5,
    };
    _batchTimer = Timer(Duration(seconds: secs), _flushBatch);
  }

  Future<void> _flushBatch() async {
    final batch = List<Packet>.from(_pendingBatch);
    _pendingBatch.clear();
    if (!_online) {
      for (final p in batch) {
        await _buffer.savePacket(p);
      }
      await _refreshPendingCount();
      return;
    }
    for (final p in batch) {
      await _upload(p);
    }
  }

  Future<void> _upload(Packet packet) async {
    try {
      await _firestore.uploadPacket(packet);
      _markSent(packet.id);
    } catch (_) {
      await _buffer.savePacket(packet);
      await _refreshPendingCount();
    }
  }

  void _markSent(String id) {
    final i = _log.indexWhere((p) => p.id == id);
    if (i >= 0) {
      final p = _log[i];
      _log[i] = PacketModel(
        id: p.id,
        timestamp: p.timestamp,
        heartRate: p.heartRate,
        activity: p.activity,
        sent: true,
      );
      notifyListeners();
    }
  }

  Future<void> _onNetworkChange(bool online) async {
    _online = online;
    notifyListeners();
    if (online) await _flushBuffer();
  }

  Future<void> _flushBuffer() async {
    final pending = await _buffer.getPendingPackets();
    for (final p in pending) {
      try {
        await _firestore.uploadPacket(p);
        await _buffer.deletePacket(p.id);
      } catch (_) {
        break;
      }
    }
    await _refreshPendingCount();
  }

  Future<void> _refreshPendingCount() async {
    _pendingCount = await _buffer.getPendingCount();
    notifyListeners();
  }

  void setInterval(StreamInterval value) {
    _interval = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _btSub?.cancel();
    _netSub?.cancel();
    _batchTimer?.cancel();
    _bt.dispose();
    _network.dispose();
    super.dispose();
  }
}
