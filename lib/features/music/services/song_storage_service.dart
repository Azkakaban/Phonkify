import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SongStorageService {
  SongStorageService._();

  static final SongStorageService instance =
      SongStorageService._();

  final SupabaseClient _supabase =
      Supabase.instance.client;

  Future<String> uploadAudio({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final extension = _getExtension(fileName);

    final path =
        '${DateTime.now().millisecondsSinceEpoch}_'
        '${_sanitizeFileName(fileName)}'
        '$extension';

    await _supabase.storage
        .from('audio')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/mpeg',
            upsert: false,
          ),
        );

    return path;
  }

  Future<String> uploadCover({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final extension = _getExtension(fileName);

    final path =
        '${DateTime.now().millisecondsSinceEpoch}_'
        '${_sanitizeFileName(fileName)}'
        '$extension';

    await _supabase.storage
        .from('covers')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _getImageContentType(
              extension,
            ),
            upsert: false,
          ),
        );

    return path;
  }

  String _getExtension(
    String fileName,
  ) {
    final dotIndex =
        fileName.lastIndexOf('.');

    if (dotIndex == -1) {
      return '';
    }

    return fileName
        .substring(dotIndex)
        .toLowerCase();
  }

  String _sanitizeFileName(
    String fileName,
  ) {
    final withoutExtension =
        fileName.contains('.')
            ? fileName.substring(
                0,
                fileName.lastIndexOf('.'),
              )
            : fileName;

    return withoutExtension
        .replaceAll(
          RegExp(r'[^a-zA-Z0-9_-]'),
          '_',
        );
  }

  String _getImageContentType(
    String extension,
  ) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}