import 'package:flutter/foundation.dart';
import '../../domain/app_user.dart';
import '../../data/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _currentUser;
  String _verificationId = '';

  AuthViewModel(this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      _verificationId = await _authRepository.sendOtp(phoneNumber);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authRepository.verifyOtp(_verificationId, smsCode);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectRoleAndComplete(String role, String name) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      _currentUser = await _authRepository.updateUserRole(_currentUser!.uid, role, name);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    notifyListeners();
  }
}
