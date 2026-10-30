import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final response = await _supabase
        .from('profiles')
        .select('id, username, display_name, avatar_url, role')
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  Future<void> updateDisplayName({
    required String displayName,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User belum login.',
      );
    }

    final name = displayName.trim();

    if (name.isEmpty) {
      throw const PostgrestException(
        message: 'Nama tidak boleh kosong.',
      );
    }

    await _supabase
        .from('profiles')
        .update({
          'display_name': name,
        })
        .eq('id', user.id);
  }

  Future<String> uploadAvatar({
    required String filePath,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'User belum login.',
      );
    }

    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception(
        'File avatar tidak ditemukan.',
      );
    }

    final storagePath = '${user.id}/avatar.jpg';

    await _supabase.storage
        .from('avatars')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    await _supabase
        .from('profiles')
        .update({
          'avatar_url': storagePath,
        })
        .eq('id', user.id);

    return storagePath;
  }

  Future<String> getAvatarUrl({
    required String avatarPath,
  }) async {
    if (avatarPath.startsWith('http://') ||
        avatarPath.startsWith('https://')) {
      return avatarPath;
    }

    return _supabase.storage
        .from('avatars')
        .createSignedUrl(
          avatarPath,
          60 * 60,
        );
  }
}
