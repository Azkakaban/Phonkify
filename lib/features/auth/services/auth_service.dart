import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String emailRedirectUrl =
      'phonkify://auth-callback';

  /// Register user baru.
  ///
  /// Setelah user mendaftar, Supabase mengirim
  /// email verifikasi dengan tujuan kembali
  /// ke aplikasi Phonkify.
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? username,
    String? displayName,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': displayName,
      },
      emailRedirectTo: emailRedirectUrl,
    );

    return response;
  }

  /// Mengirim ulang email verifikasi.
  Future<void> resendVerificationEmail({
    required String email,
  }) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: emailRedirectUrl,
    );
  }

  /// Login user.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response;
  }

  /// Logout user.
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// User yang sedang login.
  User? get currentUser {
    return _supabase.auth.currentUser;
  }

  /// Session yang sedang aktif.
  Session? get currentSession {
    return _supabase.auth.currentSession;
  }

  /// Stream perubahan authentication.
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}