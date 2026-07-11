import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/data/user_repository.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';
import 'package:hexa/features/auth/presentation/widgets/hexagon_logo.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() {
    return _CompleteProfileScreenState();
  }
}

class _CompleteProfileScreenState
    extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _usernameFocusNode = FocusNode();

  bool _isSaving = false;
  bool _isSigningOut = false;
  String? _serverUsernameError;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _displayNameController.text = _suggestDisplayName(user);
      _usernameController.text = _suggestUsername(user);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  String _suggestDisplayName(User user) {
    final displayName = user.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final emailName = user.email?.split('@').first.trim() ?? '';
    return emailName.isEmpty ? 'Hexa kullanıcısı' : emailName;
  }

  String _suggestUsername(User user) {
    final emailName = user.email?.split('@').first ?? '';
    final displayName = user.displayName ?? '';
    final source = emailName.isNotEmpty ? emailName : displayName;

    var candidate = source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._]'), '')
        .replaceAll(RegExp(r'^[._]+|[._]+$'), '');

    if (candidate.length > 24) {
      candidate = candidate.substring(0, 24);
    }

    if (candidate.length < 3) {
      final suffix = user.uid.length >= 6
          ? user.uid.substring(0, 6).toLowerCase()
          : user.uid.toLowerCase();
      candidate = 'hexa_$suffix';
    }

    return candidate;
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();
    setState(() => _serverUsernameError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Oturum bulunamadı. Lütfen yeniden giriş yap.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(userRepositoryProvider).completeUserProfile(
            uid: user.uid,
            username: _usernameController.text,
            displayName: _displayNameController.text,
            bio: _bioController.text,
          );

      if (mounted) {
        context.go('/feed');
      }
    } on UsernameTakenException {
      if (mounted) {
        setState(() {
          _serverUsernameError = 'Bu kullanıcı adı daha önce alınmış.';
        });
        _formKey.currentState?.validate();
        _usernameFocusNode.requestFocus();
      }
    } on ProfileValidationException catch (error) {
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      _showMessage(_firebaseErrorMessage(error));
    } catch (error, stackTrace) {
      debugPrint('Profile completion failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showMessage('Profil kaydedilemedi. Biraz sonra tekrar dene.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_isSaving || _isSigningOut) {
      return;
    }

    setState(() => _isSigningOut = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (error) {
      _showMessage('Çıkış yapılamadı. Tekrar dene.');
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  String _firebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Firebase izinleri profil kaydına izin vermiyor. Firestore kurallarını kontrol et.';
      case 'unavailable':
        return 'Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.';
      case 'deadline-exceeded':
        return 'İşlem zaman aşımına uğradı. Tekrar dene.';
      default:
        return 'Profil kaydedilemedi. Biraz sonra tekrar dene.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String? _validateDisplayName(String? value) {
    final cleanValue = value?.trim() ?? '';
    if (cleanValue.length < 2) {
      return 'Görünen ad en az 2 karakter olmalı.';
    }
    if (cleanValue.length > 40) {
      return 'Görünen ad en fazla 40 karakter olabilir.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (_serverUsernameError != null) {
      return _serverUsernameError;
    }

    final cleanValue = UserRepository.normalizeUsername(value ?? '');
    if (cleanValue.length < 3 || cleanValue.length > 24) {
      return '3–24 karakter kullan.';
    }
    if (!RegExp(r'^[a-z0-9](?:[a-z0-9._]*[a-z0-9])$')
        .hasMatch(cleanValue)) {
      return 'Harf, rakam, nokta ve alt çizgi kullan; işaretle başlama.';
    }
    return null;
  }

  String? _validateBio(String? value) {
    if ((value?.trim().length ?? 0) > 160) {
      return 'Biyografi en fazla 160 karakter olabilir.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: const Text(
                  'Devam etmek için profilini tamamla veya hesabını değiştir.',
                ),
                action: SnackBarAction(
                  label: 'Hesap değiştir',
                  onPressed: _signOut,
                ),
              ),
            );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            const AuthBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      HexaSpacing.lg,
                      HexaSpacing.md,
                      HexaSpacing.lg,
                      HexaSpacing.xl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProfileTopBar(
                                isSigningOut: _isSigningOut,
                                onSignOut: _signOut,
                              ),
                              const SizedBox(height: HexaSpacing.lg),
                              _ProfileIntro(user: user),
                              const SizedBox(height: HexaSpacing.lg),
                              _ProfileFormCard(
                                displayNameController:
                                    _displayNameController,
                                usernameController: _usernameController,
                                bioController: _bioController,
                                usernameFocusNode: _usernameFocusNode,
                                validateDisplayName: _validateDisplayName,
                                validateUsername: _validateUsername,
                                validateBio: _validateBio,
                                onUsernameChanged: (_) {
                                  if (_serverUsernameError != null) {
                                    setState(
                                      () => _serverUsernameError = null,
                                    );
                                  }
                                },
                                onSubmitted: (_) => _submitProfile(),
                              ),
                              const SizedBox(height: HexaSpacing.lg),
                              FilledButton.icon(
                                onPressed: _isSaving || _isSigningOut
                                    ? null
                                    : _submitProfile,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 21,
                                        height: 21,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.3,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_rounded,
                                      ),
                                label: Text(
                                  _isSaving
                                      ? 'Profil hazırlanıyor...'
                                      : 'Hexa’ya katıl',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(58),
                                ),
                              ),
                              const SizedBox(height: HexaSpacing.sm),
                              const Text(
                                'Kullanıcı adın profil bağlantında ve videolarının üzerinde görünür.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: HexaColors.inkSoft,
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.isSigningOut,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HexagonLogo(size: 38, showShadow: false),
        const SizedBox(width: 10),
        Text(
          'HEXA',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: isSigningOut ? null : onSignOut,
          icon: isSigningOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz_rounded, size: 19),
          label: const Text('Hesap değiştir'),
        ),
      ],
    );
  }
}

class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _StepBadge(),
        const SizedBox(height: HexaSpacing.md),
        _ProfileAvatar(user: user),
        const SizedBox(height: HexaSpacing.md),
        Text(
          'Seni nasıl tanıyalım?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
        ),
        const SizedBox(height: 7),
        Text(
          'Toplulukta görünecek adını ve kısa profilini belirle.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HexaColors.inkMuted,
              ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: HexaColors.mintSoft,
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: HexaColors.mint),
      ),
      child: const Text(
        'SON ADIM · PROFİLİNİ TAMAMLA',
        style: TextStyle(
          color: HexaColors.success,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.75,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL?.trim() ?? '';
    final fallbackLetter = _fallbackLetter(user);

    return Container(
      width: 86,
      height: 86,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: HexaColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x1FD83A56),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl.isEmpty
            ? _AvatarFallback(letter: fallbackLetter)
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _AvatarFallback(letter: fallbackLetter);
                },
              ),
      ),
    );
  }

  String _fallbackLetter(User? user) {
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName.substring(0, 1).toUpperCase();
    }

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }

    return 'H';
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HexaColors.signalSoft,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: HexaColors.signal,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ProfileFormCard extends StatelessWidget {
  const _ProfileFormCard({
    required this.displayNameController,
    required this.usernameController,
    required this.bioController,
    required this.usernameFocusNode,
    required this.validateDisplayName,
    required this.validateUsername,
    required this.validateBio,
    required this.onUsernameChanged,
    required this.onSubmitted,
  });

  final TextEditingController displayNameController;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final FocusNode usernameFocusNode;
  final FormFieldValidator<String> validateDisplayName;
  final FormFieldValidator<String> validateUsername;
  final FormFieldValidator<String> validateBio;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HexaSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.lg),
        border: Border.all(color: HexaColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0B141B),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: displayNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            maxLength: 40,
            validator: validateDisplayName,
            decoration: const InputDecoration(
              labelText: 'Görünen ad',
              hintText: 'Örn. Elçin Eyvazlı',
              prefixIcon: Icon(Icons.badge_outlined),
              counterText: '',
            ),
          ),
          const SizedBox(height: HexaSpacing.md),
          TextFormField(
            controller: usernameController,
            focusNode: usernameFocusNode,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 24,
            inputFormatters: const [
              _LowerCaseTextFormatter(),
              _UsernameTextFormatter(),
            ],
            validator: validateUsername,
            onChanged: onUsernameChanged,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı adı',
              hintText: 'kullaniciadi',
              prefixText: '@',
              prefixStyle: TextStyle(
                color: HexaColors.signal,
                fontWeight: FontWeight.w900,
              ),
              prefixIcon: Icon(Icons.alternate_email_rounded),
              helperText: '3–24 karakter · a–z, 0–9, nokta ve alt çizgi',
              counterText: '',
            ),
          ),
          const SizedBox(height: HexaSpacing.md),
          TextFormField(
            controller: bioController,
            minLines: 3,
            maxLines: 4,
            maxLength: 160,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            validator: validateBio,
            onFieldSubmitted: onSubmitted,
            decoration: const InputDecoration(
              labelText: 'Kısa biyografi',
              hintText: 'İnsanlara hangi konuda değer katıyorsun?',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 54),
                child: Icon(Icons.short_text_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowerCaseTextFormatter extends TextInputFormatter {
  const _LowerCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lowerCaseText = newValue.text.toLowerCase();
    return newValue.copyWith(
      text: lowerCaseText,
      selection: TextSelection.collapsed(offset: lowerCaseText.length),
      composing: TextRange.empty,
    );
  }
}

class _UsernameTextFormatter extends TextInputFormatter {
  const _UsernameTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(
      RegExp(r'[^a-z0-9._]'),
      '',
    );

    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
      composing: TextRange.empty,
    );
  }
}
