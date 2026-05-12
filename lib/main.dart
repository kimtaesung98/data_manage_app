import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'chat/pages/login_page.dart';
import 'chat/providers/chat_auth_provider.dart';
import 'core/services/background_service.dart';
import 'core/services/network_monitor.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/buffer_repository_impl.dart';
import 'data/sources/bluetooth_source.dart';
import 'data/sources/firestore_source.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/bridge_provider.dart';
import 'profile/pages/profile_dashboard_page.dart';
import 'profile/providers/profile_provider.dart';

// ── Supabase credentials ───────────────────────────────────────────────────
// Supply at build time:
//   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=eyJ...
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://YOUR_PROJECT_ID.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR_SUPABASE_ANON_KEY',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase — 노인 모니터링 브릿지
  await Firebase.initializeApp();
  await initBackgroundService();

  // Supabase — 사용자 프로필 관리 + AI 채팅
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const DataManageApp());
}

class DataManageApp extends StatelessWidget {
  const DataManageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── 노인 모니터링 (Firebase) ───────────────────────────────────
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
        // ── 사용자 인증 (Supabase) ────────────────────────────────────
        ChangeNotifierProvider(create: (_) => ChatAuthProvider()),
        // ── 프로필 CRUD (Supabase user_profiles) ─────────────────────
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: '데이터 관리 앱',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF7C5CFC),
            secondary: Color(0xFF7C5CFC),
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Routes based on Supabase session state.
/// Session is persisted across restarts automatically by supabase_flutter.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<ChatAuthProvider>();
    return auth.isAuthenticated
        ? const ProfileDashboardPage()
        : const LoginPage();
  }
}
