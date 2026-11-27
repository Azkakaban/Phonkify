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

  /// Login/registrasi melalui Google OAuth.
  Future<bool> signInWithGoogle() async {
    return _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: emailRedirectUrl,
    );
  }

  /// Memastikan profil Google user tersedia di tabel profiles.
  /// Username dibuat permanen dan unik dengan suffix UID.
  Future<void> ensureGoogleProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (existing != null) return;

    final metadata = user.userMetadata ?? {};
    final displayName = (metadata['full_name'] ?? metadata['name'] ??
            user.email?.split('@').first ?? 'Google User')
        .toString()
        .trim();
    final rawUsername = displayName.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = rawUsername.isEmpty ? 'user' : rawUsername;
    final suffix = user.id.replaceAll('-', '').substring(0, 6).toLowerCase();
    final username = '${base}_$suffix';
    final avatarUrl = (metadata['avatar_url'] ?? metadata['picture'])?.toString();

    await _supabase.from('profiles').insert({
      'id': user.id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    });
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