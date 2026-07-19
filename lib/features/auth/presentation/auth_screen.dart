import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/widgets/hexagon_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithGoogle();

      // Yönlendirmeyi router yapar.
      // Böylece profil tamamlanmadan Feed açılmaz.
    } catch (error, stackTrace) {
      debugPrint('Google sign-in failed: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _errorMessage = _friendlyAuthMessage(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyAuthMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return 'İnternet bağlantını kontrol edip tekrar dene.';

        case 'account-exists-with-different-credential':
          return 'Bu e-posta başka bir giriş yöntemiyle kayıtlı.';

        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış.';

        case 'operation-not-allowed':
          return 'Google girişi Firebase Console üzerinde etkin değil.';

        case 'popup-blocked':
          return 'Tarayıcı giriş penceresini engelledi. Açılır pencerelere izin ver.';

        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Google giriş penceresi kapatıldı.';

        default:
          return 'Google ile giriş tamamlanamadı. Biraz sonra tekrar dene.';
      }
    }

    if (error is PlatformException) {
      switch (error.code) {
        case 'network_error':
          return 'İnternet bağlantını kontrol edip tekrar dene.';

        case 'sign_in_canceled':
          return 'Google girişi iptal edildi.';

        case 'sign_in_failed':
          return 'Google yapılandırması doğrulanamadı. SHA anahtarlarını kontrol et.';
      }
    }

    return 'Giriş sırasında beklenmeyen bir sorun oluştu. Tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
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
                stops: <double>[0, 0.42, 1],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 690;

                  final horizontalPadding = constraints.maxWidth < 380
                      ? 20.0
                      : 28.0;

                  final verticalPadding = isCompact ? 18.0 : 26.0;

                  final minimumHeight =
                      constraints.maxHeight - verticalPadding * 2;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minimumHeight),
                      child: IntrinsicHeight(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const _BrandHeader(),
                                SizedBox(height: isCompact ? 48 : 82),
                                _AuthContent(isCompact: isCompact),
                                const Spacer(),
                                SizedBox(height: isCompact ? 40 : 68),
                                _AuthActions(
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                  onGooglePressed: _handleGoogleSignIn,
                                ),
                              ],
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
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
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
            fontSize: 17,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.8,
          ),
        ),
      ],
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: isCompact ? 76 : 88,
          height: isCompact ? 76 : 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: HexaColors.surfaceDark,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x248B5CF6),
                blurRadius: 36,
                spreadRadius: -8,
              ),
              BoxShadow(
                color: Color(0x1406B6D4),
                blurRadius: 44,
                spreadRadius: -12,
              ),
            ],
          ),
          child: HexagonLogo(size: isCompact ? 48 : 56, showShadow: false),
        ),
        SizedBox(height: isCompact ? 28 : 34),
        Text(
          'Değerli içerik,\ndaha görünür.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFF5F5F7),
            fontSize: isCompact ? 31 : 37,
            height: 1.06,
            fontWeight: FontWeight.w700,
            letterSpacing: isCompact ? -1.15 : -1.45,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: const Text(
            'HEXA, fayda sağlayan videoları topluluk etkileşimleriyle öne çıkarır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0x8FFFFFFF),
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.12,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({
    required this.isLoading,
    required this.errorMessage,
    required this.onGooglePressed,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGooglePressed;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = HexaMotion.reduceMotionOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AnimatedSwitcher(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            );
          },
          child: errorMessage == null
              ? const SizedBox.shrink(key: ValueKey<String>('empty-auth-error'))
              : Padding(
                  key: ValueKey<String>(errorMessage!),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ErrorBanner(message: errorMessage!),
                ),
        ),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: isLoading ? null : onGooglePressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: HexaColors.backgroundDark,
              disabledBackgroundColor: Colors.white.withOpacity(0.72),
              disabledForegroundColor: HexaColors.backgroundDark.withOpacity(
                0.58,
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isLoading
                  ? const SizedBox.square(
                      key: ValueKey<String>('google-auth-loading'),
                      dimension: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.1,
                        color: HexaColors.backgroundDark,
                      ),
                    )
                  : const Row(
                      key: ValueKey<String>('google-auth-content'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _GoogleGlyph(),
                        SizedBox(width: 11),
                        Text(
                          'Google ile devam et',
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Devam ederek Kullanım Koşulları’nı ve Gizlilik Politikası’nı kabul etmiş olursun.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0x52FFFFFF),
              fontSize: 10.5,
              height: 1.42,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.02,
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 19,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          color: HexaColors.error.withOpacity(0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HexaColors.error.withOpacity(0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.error_outline_rounded,
              color: HexaColors.error.withOpacity(0.88),
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xE6FFB3BA),
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.06,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
