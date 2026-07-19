import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/data/user_repository.dart';
import 'package:hexa/features/auth/presentation/widgets/hexagon_logo.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() {
    return _CompleteProfileScreenState();
  }
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
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
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _serverUsernameError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Oturum bulunamadı. Lütfen yeniden giriş yap.');

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(userRepositoryProvider)
          .completeUserProfile(
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
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_isSaving || _isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await ref.read(authServiceProvider).signOut();
    } catch (_) {
      _showMessage('Çıkış yapılamadı. Tekrar dene.');
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
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
      ..showSnackBar(SnackBar(content: Text(message)));
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

    if (!RegExp(r'^[a-z0-9](?:[a-z0-9._]*[a-z0-9])$').hasMatch(cleanValue)) {
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

    final interactionLocked = _isSaving || _isSigningOut;

    return Theme(
      data: HexaTheme.darkTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: HexaColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }

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
          },
          child: Scaffold(
            backgroundColor: HexaColors.backgroundDark,
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFF0A0A0F),
                    HexaColors.backgroundDark,
                    HexaColors.backgroundDark,
                  ],
                  stops: <double>[0, 0.34, 1],
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 760;

                    final horizontalPadding = constraints.maxWidth < 380
                        ? 18.0
                        : 24.0;

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        10,
                        horizontalPadding,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: AutofillGroup(
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: AbsorbPointer(
                                absorbing: interactionLocked,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _ProfileTopBar(
                                      isSigningOut: _isSigningOut,
                                      onSignOut: _signOut,
                                    ),
                                    SizedBox(height: isCompact ? 34 : 50),
                                    _ProfileIntro(
                                      user: user,
                                      compact: isCompact,
                                    ),
                                    SizedBox(height: isCompact ? 26 : 34),
                                    _ProfileFormSurface(
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
                                          setState(() {
                                            _serverUsernameError = null;
                                          });
                                        }
                                      },
                                      onSubmitted: (_) {
                                        _submitProfile();
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 54,
                                      child: FilledButton.icon(
                                        onPressed: interactionLocked
                                            ? null
                                            : _submitProfile,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: HexaColors.purple,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.white
                                              .withOpacity(0.08),
                                          disabledForegroundColor: Colors.white
                                              .withOpacity(0.38),
                                          elevation: 0,
                                          shape: const StadiumBorder(),
                                        ),
                                        icon: _isSaving
                                            ? const SizedBox.square(
                                                dimension: 19,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.1,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                              ),
                                        label: Text(
                                          _isSaving
                                              ? 'Profil hazırlanıyor...'
                                              : 'HEXA’ya katıl',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 13),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'Kullanıcı adın profil bağlantında ve paylaştığın videolarda görünür.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0x52FFFFFF),
                                          fontSize: 10.5,
                                          height: 1.4,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.02,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.isSigningOut, required this.onSignOut});

  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HexaColors.surfaceDark,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: HexagonLogo(size: 25, showShadow: false),
          ),
          const SizedBox(width: 11),
          const Text(
            'HEXA',
            style: TextStyle(
              color: Color(0xF2FFFFFF),
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.7,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: isSigningOut ? null : onSignOut,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.62),
              disabledForegroundColor: Colors.white.withOpacity(0.28),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: isSigningOut
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: HexaColors.purpleSoft,
                    ),
                  )
                : const Text(
                    'Hesap değiştir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.06,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({required this.user, required this.compact});

  final User? user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _ProfileAvatar(user: user, size: compact ? 88 : 98),
        SizedBox(height: compact ? 22 : 26),
        Text(
          'Profilini tamamla',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HexaColors.inkOnDark,
            fontSize: compact ? 29 : 33,
            height: 1.06,
            fontWeight: FontWeight.w700,
            letterSpacing: compact ? -1.05 : -1.22,
          ),
        ),
        const SizedBox(height: 11),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 390),
          child: Text(
            'Topluluğun seni tanıyabilmesi için görünen adını ve kullanıcı adını belirle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0x80FFFFFF),
              fontSize: 13.5,
              height: 1.48,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.10,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.size});

  final User? user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL?.trim() ?? '';

    final fallbackLetter = _fallbackLetter(user);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: HexaGradients.signal,
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x338B5CF6), blurRadius: 28, spreadRadius: -7),
          BoxShadow(
            color: Color(0x1F06B6D4),
            blurRadius: 36,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: HexaColors.backgroundDark,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: ColoredBox(
            color: HexaColors.surfaceMutedDark,
            child: photoUrl.isEmpty
                ? _AvatarFallback(letter: fallbackLetter)
                : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return _AvatarFallback(letter: fallbackLetter);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return _AvatarFallback(letter: fallbackLetter);
                    },
                  ),
          ),
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
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: HexaColors.purpleSoft,
          fontSize: 30,
          height: 1,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
        ),
      ),
    );
  }
}

class _ProfileFormSurface extends StatelessWidget {
  const _ProfileFormSurface({
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
      decoration: BoxDecoration(
        color: HexaColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: displayNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const <String>[AutofillHints.name],
            maxLength: 40,
            validator: validateDisplayName,
            cursorColor: HexaColors.purple,
            cursorWidth: 1.6,
            style: _fieldTextStyle,
            decoration: _fieldDecoration(
              label: 'Görünen ad',
              hint: 'Adın veya üretici adın',
              icon: Icons.badge_outlined,
            ),
          ),
          const _FormDivider(),
          TextFormField(
            controller: usernameController,
            focusNode: usernameFocusNode,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            maxLength: 24,
            inputFormatters: const <TextInputFormatter>[
              _LowerCaseTextFormatter(),
              _UsernameTextFormatter(),
            ],
            validator: validateUsername,
            onChanged: onUsernameChanged,
            cursorColor: HexaColors.purple,
            cursorWidth: 1.6,
            style: _fieldTextStyle,
            decoration: _fieldDecoration(
              label: 'Kullanıcı adı',
              hint: 'kullaniciadi',
              icon: Icons.alternate_email_rounded,
              prefixText: '@',
              helper: '3–24 karakter · harf, rakam, nokta ve alt çizgi',
            ),
          ),
          const _FormDivider(),
          TextFormField(
            controller: bioController,
            minLines: 3,
            maxLines: 4,
            maxLength: 160,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            validator: validateBio,
            onFieldSubmitted: onSubmitted,
            cursorColor: HexaColors.purple,
            cursorWidth: 1.6,
            style: _fieldTextStyle,
            decoration: _fieldDecoration(
              label: 'Kısa biyografi · İsteğe bağlı',
              hint: 'Hangi konuda içerik üretiyorsun?',
              icon: Icons.notes_rounded,
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _fieldTextStyle {
    return const TextStyle(
      color: Color(0xF2FFFFFF),
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.12,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? prefixText,
    String? helper,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      filled: false,
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixText: prefixText,
      alignLabelWithHint: alignLabelWithHint,
      counterText: '',
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: alignLabelWithHint ? 54 : 0),
        child: Icon(icon, color: const Color(0x80FFFFFF), size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 48),
      prefixStyle: const TextStyle(
        color: HexaColors.purpleSoft,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelStyle: const TextStyle(
        color: Color(0x80FFFFFF),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: HexaColors.purpleSoft,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0x52FFFFFF),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      helperStyle: const TextStyle(
        color: Color(0x52FFFFFF),
        fontSize: 10.5,
        height: 1.3,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: const TextStyle(
        color: HexaColors.error,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 17, 16, 14),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    );
  }
}

class _FormDivider extends StatelessWidget {
  const _FormDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 50),
      child: Divider(height: 1, thickness: 1, color: Color(0x14FFFFFF)),
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
    final filtered = newValue.text.replaceAll(RegExp(r'[^a-z0-9._]'), '');

    return newValue.copyWith(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
      composing: TextRange.empty,
    );
  }
}
