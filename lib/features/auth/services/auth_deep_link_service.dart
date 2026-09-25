import 'dart:async';

import 'package:app_links/app_links.dart';

class AuthDeepLinkService {
  AuthDeepLinkService._();

  static final AuthDeepLinkService instance =
      AuthDeepLinkService._();

  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _subscription;

  /// Memulai listener untuk deep link yang masuk.
  void start({
    required void Function(Uri uri) onLink,
  }) {
    _subscription?.cancel();

    _subscription = _appLinks.uriLinkStream.listen(
      onLink,
      onError: (_) {
        // Error deep link tidak boleh menghentikan aplikasi.
      },
    );
  }

  /// Menghentikan listener.
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}