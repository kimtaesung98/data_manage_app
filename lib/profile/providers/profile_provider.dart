import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

enum ProfileStatus { idle, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  ProfileProvider({ProfileService? service})
      : _service = service ?? ProfileService();

  UserProfile? _profile;
  ProfileStatus _status = ProfileStatus.idle;
  String? _error;

  UserProfile? get profile => _profile;
  ProfileStatus get status => _status;
  String? get error => _error;
  bool get isLoaded => _status == ProfileStatus.loaded;

  /// Loads profile from Supabase; creates a default row from Google metadata
  /// if the user is logging in for the first time.
  Future<void> loadProfile() async {
    _setLoading();
    try {
      _profile = await _service.fetchProfile() ?? await _service.createFromGoogle();
      _status = ProfileStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  Future<void> updateProfile({String? nickname, String? avatarUrl}) async {
    if (_profile == null) return;
    _setLoading();
    try {
      _profile = await _service.updateProfile(
        id: _profile!.id,
        nickname: nickname,
        avatarUrl: avatarUrl,
      );
      _status = ProfileStatus.loaded;
    } catch (e) {
      _error = e.toString();
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  Future<void> deleteProfile() async {
    _setLoading();
    try {
      await _service.deleteProfile();
      await Supabase.instance.client.auth.signOut();
      _profile = null;
      _status = ProfileStatus.idle;
    } catch (e) {
      _error = e.toString();
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = ProfileStatus.loading;
    _error = null;
    notifyListeners();
  }
}
