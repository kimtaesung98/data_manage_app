import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../constants/app_constants.dart';

/// Configures and starts the foreground service that keeps BT→Firestore
/// streaming alive even when the host app is backgrounded.
///
/// Call [initBackgroundService] once from main() before runApp().
/// Platform setup required:
///   Android — AndroidManifest.xml must declare the service and
///             FOREGROUND_SERVICE permission (see README).
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: AppConstants.bgChannelId,
      initialNotificationTitle: '데이터 브릿지 실행 중',
      initialNotificationContent: '웨어 기기 모니터링 중',
      foregroundServiceNotificationId: AppConstants.bgNotificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) {
  // The bridge orchestration runs in the UI isolate via BridgeProvider.
  // This entry point keeps the process alive and can forward events via
  // service.invoke() when needed for deeper background integration.
  Timer.periodic(const Duration(seconds: 30), (_) {
    service.invoke('heartbeat', {'ts': DateTime.now().toIso8601String()});
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async => true;
