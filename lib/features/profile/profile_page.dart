import 'package:flutter/material.dart';

import '../admin/pages/admin_panel_page.dart';
import '../auth/services/auth_service.dart';
import 'pages/edit_profile_page.dart';
import '../player/services/audio_player_service.dart';
import '../recommendation/pages/behavioral_scoring_test_page.dart';
import '../recommendation/pages/explicit_preference_test_page.dart';
import '../recommendation/pages/recommendation_scoring_test_page.dart';
import '../recommendation/pages/similarity_test_page.dart';
import 'services/profile_service.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfilePage({
    super.key,
    this.onLogout,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {
  final ProfileService _profileService =
      ProfileService();

  final AuthService _authService =
      AuthService();

  final AudioPlayerService _audioPlayerService =
    AudioPlayerService.instance;

  Map<String, dynamic>? _profile;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile =
          await _profileService.getCurrentProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
  try {
    // Bersihkan audio session akun saat ini terlebih dahulu.
    await _audioPlayerService.clearForLogout();

    // Setelah player dan queue bersih, baru logout Supabase.
    await _authService.logout();

    if (!mounted) return;

    widget.onLogout?.call();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Gagal logout: $e',
        ),
      ),
    );
  }
}

  void _openAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AdminPanelPage(),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    if (_profile == null) {
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          profile: _profile!,
        ),
      ),
    );

    if (updated == true && mounted) {
      await _loadProfile();
    }
  }

  void _openDevelopmentTesting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const _DevelopmentTestingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _profile?['display_name'] as String? ??
            'User';

    final username =
        _profile?['username'] as String? ??
            '';

    final role =
        _profile?['role'] as String? ??
            'USER';

    final avatarPath =
        _profile?['avatar_url'] as String?;

    final isAdmin =
        role.toUpperCase() == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 16),

                  _ProfileHero(
                    displayName: displayName,
                    username: username,
                    role: role,
                    avatarPath: avatarPath,
                    profileService:
                        _profileService,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Akun',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 10),

                  _ProfileMenuCard(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle:
                        'Ubah nama dan foto profil',
                    onTap: _openEditProfile,
                  ),

                  if (isAdmin) ...[
                    const SizedBox(height: 28),

                    Text(
                      'Admin',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight:
                                FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 10),

                    _ProfileMenuCard(
                      icon: Icons
                          .admin_panel_settings_outlined,
                      title: 'Admin Panel',
                      subtitle:
                          'Kelola lagu dan trending',
                      onTap: _openAdminPanel,
                    ),

                    const SizedBox(height: 10),

                    _ProfileMenuCard(
                      icon: Icons
                          .developer_mode_outlined,
                      title:
                          'Development & Testing',
                      subtitle:
                          'Pengujian sistem rekomendasi',
                      onTap:
                          _openDevelopmentTesting,
                    ),
                  ],

                  const SizedBox(height: 28),

                  Text(
                    'Aplikasi',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 10),

                  _ProfileMenuCard(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle:
                        'Keluar dari akun Phonkify',
                    destructive: true,
                    onTap: _logout,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ProfileHero extends StatefulWidget {
  final String displayName;
  final String username;
  final String role;
  final String? avatarPath;
  final ProfileService profileService;

  const _ProfileHero({
    required this.displayName,
    required this.username,
    required this.role,
    required this.avatarPath,
    required this.profileService,
  });

  @override
  State<_ProfileHero> createState() =>
      _ProfileHeroState();
}

class _ProfileHeroState
    extends State<_ProfileHero> {
  String? _avatarUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didUpdateWidget(
    covariant _ProfileHero oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.avatarPath !=
        widget.avatarPath) {
      _loadAvatar();
    }
  }

  Future<void> _loadAvatar() async {
    final path = widget.avatarPath;

    if (path == null || path.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarUrl = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final url =
          await widget.profileService.getAvatarUrl(
        avatarPath: path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarUrl = url;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarUrl = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        24,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest,
            colorScheme.surface,
          ],
        ),
        border: Border.all(
          color: colorScheme.outline
              .withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary
                    .withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 58,
              backgroundImage:
                  _avatarUrl != null &&
                          _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
              child: _loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : _avatarUrl == null ||
                          _avatarUrl!.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 58,
                        )
                      : null,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            widget.displayName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),

          if (widget.username.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '@${widget.username}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: colorScheme
                        .onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 12),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              widget.role.toUpperCase(),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _ProfileMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DevelopmentTestingPage extends StatelessWidget {
  const _DevelopmentTestingPage();

  void _openPage(
    BuildContext context,
    Widget page,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Development & Testing'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.analytics,
              ),
              title: const Text(
                'Behavioral Scoring Test',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _openPage(
                context,
                const BehavioralScoringTestPage(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.favorite,
              ),
              title: const Text(
                'Explicit Preference Test',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _openPage(
                context,
                const ExplicitPreferenceTestPage(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calculate,
              ),
              title: const Text(
                'Recommendation Scoring Test',
              ),
              subtitle: const Text(
                'Test Behavioral + Explicit Preference',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _openPage(
                context,
                const RecommendationScoringTestPage(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.compare_arrows,
              ),
              title: const Text(
                'Similarity Test',
              ),
              subtitle: const Text(
                'Test nilai kemiripan antar lagu',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () => _openPage(
                context,
                const SimilarityTestPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
