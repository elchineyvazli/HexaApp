// lib/features/profile/edit_profile_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';

import 'profile_model.dart';
import 'widgets/avatar_media_station_sheet.dart';
import 'widgets/edit_profile_avatar_card.dart';
import 'widgets/edit_profile_form_widgets.dart';

class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({required this.user, super.key});

  final UserProfileModel user;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  bool _isLoading = false;
  String? _selectedCategory;

  static const List<String> _categories = <String>[
    'Video Editor',
    'Streamer',
    'Coder',
    'Gamer',
    'Drone Pilot',
    'Cyber Nomad',
  ];

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController(text: widget.user.username);

    _bioController = TextEditingController(text: widget.user.bio);

    _selectedCategory = 'Coder';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isLoading) {
      return;
    }

    final newUsername = _usernameController.text.trim();
    final newBio = _bioController.text.trim();

    if (newUsername.isEmpty) {
      _showMessage('Kullanıcı adı boş bırakılamaz.');
      return;
    }

    if (newBio.length > 160) {
      _showMessage('Biyografi en fazla 160 karakter olabilir.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(<String, dynamic>{
            'username': newUsername.startsWith('@')
                ? newUsername
                : '@$newUsername',
            'bio': newBio,
            'category': _selectedCategory ?? 'Cyber Nomad',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      _showMessage('Profil güncellenemedi: ${_shortError(error)}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAvatarBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AvatarMediaStationSheet(
          profileImageUrl: widget.user.profileImageUrl,
          onPickMedia: () {
            Navigator.of(sheetContext).pop();

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Galeriden profil görseli seçme özelliği yakında.',
                  ),
                ),
              );
          },
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _shortError(Object error) {
    final text = error.toString().trim();

    if (text.length <= 140) {
      return text;
    }

    return '${text.substring(0, 140)}...';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(HexaRadius.xl),
        ),
        child: Scaffold(
          backgroundColor: HexaColors.background,
          body: Stack(
            children: [
              const AuthBackground(),
              SafeArea(
                top: false,
                child: Column(
                  children: [
                    EditProfileHeader(
                      isLoading: _isLoading,
                      onClose: () {
                        Navigator.of(context).maybePop();
                      },
                      onSave: _saveProfile,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          HexaSpacing.md,
                          HexaSpacing.xs,
                          HexaSpacing.md,
                          HexaSpacing.xl,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                EditProfileAvatarCard(
                                  imageUrl: widget.user.profileImageUrl,
                                  username: widget.user.username,
                                  onTap: _showAvatarBottomSheet,
                                ),
                                const SizedBox(height: HexaSpacing.md),
                                EditProfileSection(
                                  title: 'Profil bilgileri',
                                  description:
                                      'Topluluğun seni nasıl göreceğini düzenle.',
                                  icon: Icons.person_outline_rounded,
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _usernameController,
                                        maxLength: 25,
                                        textInputAction: TextInputAction.next,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        decoration: const InputDecoration(
                                          labelText: 'Kullanıcı adı',
                                          hintText: '@kullaniciadi',
                                          prefixIcon: Icon(
                                            Icons.alternate_email_rounded,
                                          ),
                                          counterText: '',
                                        ),
                                      ),
                                      const SizedBox(height: HexaSpacing.md),
                                      TextField(
                                        controller: _bioController,
                                        minLines: 3,
                                        maxLines: 5,
                                        maxLength: 160,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: const InputDecoration(
                                          labelText: 'Biyografi',
                                          hintText:
                                              'İnsanlara hangi konuda değer katıyorsun?',
                                          alignLabelWithHint: true,
                                          prefixIcon: Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 72,
                                            ),
                                            child: Icon(
                                              Icons.short_text_rounded,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: HexaSpacing.md),
                                EditProfileSection(
                                  title: 'İçerik alanı',
                                  description:
                                      'Profilinde öne çıkmasını istediğin alanı seç.',
                                  icon: Icons.auto_awesome_rounded,
                                  child: EditProfileCategorySelector(
                                    categories: _categories,
                                    selectedCategory: _selectedCategory,
                                    onSelected: (category) {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: HexaSpacing.lg),
                                FilledButton.icon(
                                  onPressed: _isLoading ? null : _saveProfile,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.2,
                                          ),
                                        )
                                      : const Icon(Icons.check_rounded),
                                  label: Text(
                                    _isLoading
                                        ? 'Kaydediliyor...'
                                        : 'Değişiklikleri kaydet',
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
