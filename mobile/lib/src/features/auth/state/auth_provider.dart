import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
  final _firebaseAuth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  User? get user => _firebaseAuth.currentUser;

  AuthProvider() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final currentUser = _firebaseAuth.currentUser;
    _isAuthenticated = currentUser != null;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final token = await cred.user?.getIdToken();
    if (token != null) {
      await _secureStorage.write(key: 'id_token', value: token);
    }

    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> registerWithEmail(String email, String password) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final token = await cred.user?.getIdToken();
    if (token != null) {
      await _secureStorage.write(key: 'id_token', value: token);
    }

    _isAuthenticated = true;
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

    if (didAuth && _firebaseAuth.currentUser != null) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _secureStorage.delete(key: 'id_token');
    _isAuthenticated = false;
    notifyListeners();
  }
}
