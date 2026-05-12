import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatAuthProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  User? _user;
  bool _loading = false;
  String? _error;

  ChatAuthProvider() {
    _user = _client.auth.currentUser;
    _client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> signInWithGoogle() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      _error = '로그인 실패: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _loading = true;
    notifyListeners();
    try {
      await _client.auth.signOut();
      _user = null;
    } catch (e) {
      _error = '로그아웃 실패: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
