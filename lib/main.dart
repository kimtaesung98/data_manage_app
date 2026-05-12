import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/background_service.dart';
import 'core/services/network_monitor.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/buffer_repository_impl.dart';
import 'data/sources/bluetooth_source.dart';
import 'data/sources/firestore_source.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/bridge_provider.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initBackgroundService();
  runApp(const DataBridgeApp());
}

class DataBridgeApp extends StatelessWidget {
  const DataBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) => BridgeProvider(
            btSource: BluetoothSource(),
            firestoreSource: FirestoreSource(),
            bufferRepo: BufferRepositoryImpl(),
            networkMonitor: NetworkMonitor(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '노인 상태 모니터링',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: Colors.tealAccent,
            secondary: Colors.tealAccent.shade400,
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated
        ? const DashboardScreen()
        : const LoginScreen();
  }
}
