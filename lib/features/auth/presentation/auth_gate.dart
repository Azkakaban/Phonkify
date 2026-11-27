import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../home/home_page.dart';
import '../../ai_chatbot/pages/ai_chatbot_page.dart';
import '../../onboarding/pages/onboarding_page.dart';
import '../../onboarding/services/onboarding_service.dart';
import '../../player/pages/full_player_page.dart';
import '../../player/services/audio_player_service.dart';
import '../../player/widgets/mini_player.dart';
import '../../playlist/playlist_page.dart';
import '../../profile/profile_page.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          return const LoginPage();
        }

        return const _AuthenticatedGate();
      },
    );
  }
}

class _AuthenticatedGate extends StatefulWidget {
  const _AuthenticatedGate();

  @override
  State<_AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<_AuthenticatedGate> {
  final OnboardingService _onboardingService = OnboardingService.instance;

  bool _isLoading = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      await AuthService().ensureGoogleProfile();
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', Supabase.instance.client.auth.currentUser!.id)
          .single();

      final role = profile['role'] as String?;

      // Admin tidak dipaksa masuk onboarding.
      if (role == 'ADMIN') {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _needsOnboarding = false;
        });
        return;
      }

      final completed = await _onboardingService.hasCompletedOnboarding();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _needsOnboarding = !completed;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _needsOnboarding = false;
      });
    }
  }

  void _completeOnboarding() {
    if (!mounted) return;

    setState(() {
      _needsOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsOnboarding) {
      return OnboardingPage(onCompleted: _completeOnboarding);
    }

    return const MainNavigation();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PlaylistPage(),
    const ProfilePage(),
  ];

  void _openAiChatbot() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AiChatbotPage()),
    );
  }

  void _openFullPlayer() {
    final currentSong = AudioPlayerService.instance.currentSong;

    if (currentSong == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullPlayerPage(song: currentSong),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 1
          ? null
          : FloatingActionButton(
              onPressed: _openAiChatbot,
              tooltip: 'Phonkify AI',
              elevation: 6,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.graphic_eq_rounded, size: 28),
            ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(onTap: _openFullPlayer),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.album_outlined),
                selectedIcon: Icon(Icons.album),
                label: 'Playlist',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
