import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  User? _user;
  bool _loading = false;
  String? _error;

  AuthProvider(this._repo) {
    _repo.authStateChanges.listen((user) {
      _user = user;
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
      _user = await _repo.signInWithGoogle();
    } catch (e) {
      _error = '로그인 실패: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    notifyListeners();
  }
}
