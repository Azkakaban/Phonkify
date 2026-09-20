import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/services/auth_deep_link_service.dart';
import 'features/player/services/audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  await AudioService.init(
    builder: () => PhonkifyAudioHandler()..initialize(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.phonkify.audio',
      androidNotificationChannelName: 'Phonkify Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final deepLinkService = AuthDeepLinkService.instance;
  final appLinks = AppLinks();

  unawaited(
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleAuthDeepLink(uri);
      }
    }),
  );

  deepLinkService.start(
    onLink: _handleAuthDeepLink,
  );

  runApp(const PhonkifyApp());
}

void _handleAuthDeepLink(Uri uri) {
  if (uri.scheme != 'phonkify') {
    return;
  }

  if (uri.host != 'auth-callback') {
    return;
  }

  debugPrint(
    'Phonkify auth deep link received: $uri',
  );
}