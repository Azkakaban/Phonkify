import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfilePage({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState
    extends State<EditProfilePage> {
  final ProfileService _profileService =
      ProfileService();

  late final TextEditingController _nameController;

  String? _avatarPath;
  String? _avatarUrl;
  String? _selectedAvatarPath;

  bool _isLoading = false;
  bool _isLoadingAvatar = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.profile['display_name'] as String? ??
          '',
    );

    _avatarPath =
        widget.profile['avatar_url'] as String?;

    _loadAvatarUrl();
  }

  Future<void> _loadAvatarUrl() async {
    final path = _avatarPath;

    if (path == null || path.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingAvatar = true;
    });

    try {
      final url =
          await _profileService.getAvatarUrl(
        avatarPath: path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarUrl = url;
        _isLoadingAvatar = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingAvatar = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    if (_isLoading) {
      return;
    }

    try {
      final file =
          await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file == null || file.path == null) {
        return;
      }

      setState(() {
        _selectedAvatarPath = file.path;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memilih foto: $error',
          ),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) {
      return;
    }

    final displayName =
        _nameController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Nama tidak boleh kosong.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileService.updateDisplayName(
        displayName: displayName,
      );

      if (_selectedAvatarPath != null) {
        await _profileService.uploadAvatar(
          filePath: _selectedAvatarPath!,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile berhasil diperbarui.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui profile: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    if (_selectedAvatarPath != null) {
      return CircleAvatar(
        radius: 64,
        backgroundImage: FileImage(
          File(_selectedAvatarPath!),
        ),
      );
    }

    if (_avatarUrl != null &&
        _avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 64,
        backgroundImage: NetworkImage(
          _avatarUrl!,
        ),
      );
    }

    return const CircleAvatar(
      radius: 64,
      child: Icon(
        Icons.person,
        size: 64,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username =
        widget.profile['username'] as String? ??
            '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  alignment:
                      Alignment.bottomRight,
                  children: [
                    _isLoadingAvatar &&
                            _selectedAvatarPath ==
                                null
                        ? const SizedBox(
                            width: 128,
                            height: 128,
                            child: Center(
                              child:
                                  CircularProgressIndicator(),
                            ),
                          )
                        : _buildAvatar(),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Ganti foto',
                        onPressed:
                            _isLoading
                                ? null
                                : _pickAvatar,
                        icon: const Icon(
                          Icons.camera_alt,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Foto profil',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                enabled: !_isLoading,
                textInputAction:
                    TextInputAction.done,
                textCapitalization:
                    TextCapitalization.words,
                decoration:
                    const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama',
                  prefixIcon:
                      Icon(Icons.person_outline),
                  border:
                      OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              InputDecorator(
                decoration:
                    const InputDecoration(
                  labelText: 'Username',
                  prefixIcon:
                      Icon(Icons.alternate_email),
                  border:
                      OutlineInputBorder(),
                ),
                child: Text(
                  username.isEmpty
                      ? '-'
                      : '@$username',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
