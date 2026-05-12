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
          await FlutterBluePlus.startScan(
              timeout: const Duration(seconds: 30), continueScanning: true);
          _scanSub = FlutterBluePlus.scanResults.listen(_onScanResult);
        }
      });
    } catch (_) {
      // BT unavailable on this device — simulation continues
    }
  }

  void _onScanResult(List<ScanResult> results) {
    // Filter for Wear OS / health devices by service UUID or name prefix
    for (final r in results) {
      if (r.device.platformName.toLowerCase().contains('wear') ||
          r.device.platformName.toLowerCase().contains('health')) {
        // Real device found; real data integration can be wired here
      }
    }
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(PacketModel(
        id: 'WEAR-${_uuid.v4().substring(0, 8).toUpperCase()}',
        timestamp: DateTime.now(),
        heartRate: 55 + _random.nextInt(50),
        activity: _random.nextInt(100),
      ));
    });
  }

  Future<void> stopScanning() async {
    _isScanning = false;
    _simulationTimer?.cancel();
    _scanSub?.cancel();
    _stateSub?.cancel();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  void dispose() {
    stopScanning();
    _controller.close();
  }
}
