import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStep { phoneEntry, otpEntry, done }

class AuthProvider with ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStep _step = AuthStep.phoneEntry;
  String _phoneNumber = '';
  String _verificationId = '';
  int? _resendToken;
  bool _loading = false;
  String? _error;
  bool _otpSent = false;

  // ── Getters ─────────────────────────────────────────────
  AuthStep get step => _step;
  String get phoneNumber => _phoneNumber;
  bool get loading => _loading;
  String? get error => _error;
  bool get otpSent => _otpSent;
  bool get isLoggedIn => _service.isLoggedIn;
  User? get currentUser => _service.currentUser;
  Stream<User?> get authStateChanges => _service.authStateChanges;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void resetToPhone() {
    _step = AuthStep.phoneEntry;
    _error = null;
    _otpSent = false;
    notifyListeners();
  }

  // ── Send OTP ─────────────────────────────────────────────
  Future<void> sendOtp(String rawPhone) async {
    _error = null;
    _loading = true;
    notifyListeners();

    // Normalise: add +91 if no country code
    final phone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';
    _phoneNumber = phone;

    await _service.sendOtp(
      phoneNumber: phone,
      resendToken: _resendToken,
      onCodeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _step = AuthStep.otpEntry;
        _otpSent = true;
        _loading = false;
        notifyListeners();
      },
      onError: (msg) {
        _error = msg;
        _loading = false;
        notifyListeners();
      },
      onAutoVerified: (credential) async {
        await _service.signInWithCredential(credential);
        _step = AuthStep.done;
        _loading = false;
        notifyListeners();
      },
    );
  }

  // ── Resend OTP ────────────────────────────────────────────
  Future<void> resendOtp() async {
    await sendOtp(_phoneNumber);
  }

  // ── Verify OTP ────────────────────────────────────────────
  Future<bool> verifyOtp(String otp) async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      await _service.verifyOtp(
        verificationId: _verificationId,
        otp: otp,
      );
      _step = AuthStep.done;
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-verification-code':
          msg = 'Invalid OTP. Please check and try again.';
          break;
        case 'session-expired':
          msg = 'OTP expired. Please request a new one.';
          break;
        default:
          msg = e.message ?? 'Verification failed.';
      }
      _error = msg;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────
  Future<void> signOut() async {
    await _service.signOut();
    _step = AuthStep.phoneEntry;
    _otpSent = false;
    _error = null;
    notifyListeners();
  }
}