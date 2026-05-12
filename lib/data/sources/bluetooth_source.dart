import 'dart:async';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/packet.dart';
import '../models/packet_model.dart';

class BluetoothSource {
  final _controller = StreamController<Packet>.broadcast();
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _stateSub;
  Timer? _simulationTimer;
  final _random = Random();
  final _uuid = const Uuid();
  bool _isScanning = false;

  Stream<Packet> get packetStream => _controller.stream;
  bool get isScanning => _isScanning;

  Future<void> startScanning() async {
    _isScanning = true;
    _startSimulation();

    try {
      _stateSub = FlutterBluePlus.adapterState.listen((state) async {
        if (state == BluetoothAdapterState.on) {
          // [Fix #2] Cancel previous subscription before creating a new one.
          await _scanSub?.cancel();
          _scanSub = null;
          // [Fix #5] Wrap inner async work so errors don't become unhandled.
          try {
            // [Fix #1] Removed non-existent `continueScanning` parameter.
            await FlutterBluePlus.startScan(
                timeout: const Duration(seconds: 30));
            _scanSub = FlutterBluePlus.scanResults.listen(_onScanResult);
          } catch (_) {
            // scan permission denied or hardware error — simulation continues
          }
        } else {
          // BT turned off: clean up scan subscription immediately.
          await _scanSub?.cancel();
          _scanSub = null;
        }
      });
    } catch (_) {
      // BT adapter unavailable on this device — simulation continues
    }
  }

  void _onScanResult(List<ScanResult> results) {
    for (final r in results) {
      if (r.device.platformName.toLowerCase().contains('wear') ||
          r.device.platformName.toLowerCase().contains('health')) {
        // Real device found; wire actual data parsing here
      }
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // [Fix #3] Guard against adding to a closed stream after dispose().
      if (_controller.isClosed) return;
      _controller.add(PacketModel(
        id: 'WEAR-${_uuid.v4().substring(0, 8).toUpperCase()}',
        timestamp: DateTime.now(),
        heartRate: 55 + _random.nextInt(50),
        activity: _random.nextInt(100),
      ));
    });
  }

  // [Fix #4] Made synchronous so dispose() can safely call it then close the
  // stream without an await gap. FlutterBluePlus.stopScan() is fire-and-forget;
  // the scan will also stop naturally when its timeout expires.
  void stopScanning() {
    _isScanning = false;
    _simulationTimer?.cancel();
    _scanSub?.cancel();
    _stateSub?.cancel();
    _scanSub = null;
    _stateSub = null;
    FlutterBluePlus.stopScan().ignore();
  }

  void dispose() {
    stopScanning();
    _controller.close();
  }
}
