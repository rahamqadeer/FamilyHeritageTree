import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  User? get user => _supabase.auth.currentUser;

  AuthProvider() {
    _bootstrap();
    _supabase.auth.onAuthStateChange.listen((data) {
      _isAuthenticated = data.session != null;
      notifyListeners();
    });
  }

  Future<void> _bootstrap() async {
    final session = _supabase.auth.currentSession;
    _isAuthenticated = session != null;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final token = response.session?.accessToken;
    if (token != null) {
      await _secureStorage.write(key: 'access_token', value: token);
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> registerWithEmail(String email, String password, {String? displayName}) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );

    final token = response.session?.accessToken;
    if (token != null) {
      await _secureStorage.write(key: 'access_token', value: token);
    }

    _isAuthenticated = response.session != null;
    notifyListeners();
  }

  Future<bool> tryBiometricLogin() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) return false;

    final didAuth = await _localAuth.authenticate(
      localizedReason: 'Authenticate to access your Family Vault',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (didAuth && _supabase.auth.currentUser != null) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _secureStorage.delete(key: 'access_token');
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Get the current access token for API calls
  String? get accessToken => _supabase.auth.currentSession?.accessToken;
}
