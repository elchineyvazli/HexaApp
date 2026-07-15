import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';
import 'package:hexa/features/auth/presentation/widgets/hexagon_logo.dart';

class UnauthenticatedProfileView extends ConsumerStatefulWidget {
  const UnauthenticatedProfileView({super.key});

  @override
  ConsumerState<UnauthenticatedProfileView> createState() {
    return _UnauthenticatedProfileViewState();
  }
}

class _UnauthenticatedProfileViewState
    extends ConsumerState<UnauthenticatedProfileView> {
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
    } catch (error, stackTrace) {
      debugPrint('Profile Google sign-in failed: $error');
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
          return 'Google girişi şu anda kullanılamıyor.';
        case 'popup-blocked':
          return 'Tarayıcı giriş penceresini engelledi.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Google giriş penceresi kapatıldı.';
        default:
          return 'Google ile giriş tamamlanamadı. Tekrar dene.';
      }
    }

    if (error is PlatformException) {
      switch (error.code) {
        case 'network_error':
          return 'İnternet bağlantını kontrol edip tekrar dene.';
        case 'sign_in_canceled':
          return 'Google girişi iptal edildi.';
        case 'sign_in_failed':
          return 'Google giriş yapılandırması doğrulanamadı.';
      }
    }

    return 'Giriş sırasında beklenmeyen bir sorun oluştu.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexaColors.background,
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HexaSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    padding: const EdgeInsets.all(HexaSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xF7FFFFFF),
                      borderRadius: BorderRadius.circular(HexaRadius.lg),
                      border: Border.all(color: HexaColors.border),
                      boxShadow: HexaShadows.soft,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _ProfileSignInHero(),
                        const SizedBox(height: HexaSpacing.lg),
                        AnimatedSwitcher(
                          duration: HexaMotion.fast,
                          child: _errorMessage == null
                              ? const SizedBox.shrink()
                              : Padding(
                                  key: ValueKey(_errorMessage),
                                  padding: const EdgeInsets.only(
                                    bottom: HexaSpacing.md,
                                  ),
                                  child: _ProfileAuthError(
                                    message: _errorMessage!,
                                  ),
                                ),
                        ),
                        FilledButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(58),
                          ),
                          child: AnimatedSwitcher(
                            duration: HexaMotion.fast,
                            child: _isLoading
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Row(
                                    key: ValueKey('google'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _GoogleGlyph(),
                                      SizedBox(width: 12),
                                      Text(
                                        'Google ile devam et',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: HexaSpacing.sm),
                        const Text(
                          'Giriş yaptığında profilini, videolarını ve topluluk etkileşimlerini yönetebilirsin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: HexaColors.inkSoft,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSignInHero extends StatelessWidget {
  const _ProfileSignInHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HexagonLogo(size: 38, showShadow: false),
            SizedBox(width: 10),
            Text(
              'HEXA',
              style: TextStyle(
                color: HexaColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: HexaSpacing.lg),
        Container(
          width: 104,
          height: 104,
          decoration: const BoxDecoration(
            color: HexaColors.signalSoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: HexaColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: HexaColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_outline_rounded,
              size: 39,
              color: HexaColors.signalStrong,
            ),
          ),
        ),
        const SizedBox(height: HexaSpacing.lg),
        Text(
          'Profiline ulaşmak için giriş yap',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: HexaSpacing.xs),
        Text(
          'Video paylaşmak, Signal vermek, yorum yapmak ve üreticileri takip etmek için Hexa hesabını kullan.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HexaColors.inkMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: HexaSpacing.md),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: HexaSpacing.xs,
          runSpacing: HexaSpacing.xs,
          children: [
            _FeatureBadge(
              icon: Icons.video_library_rounded,
              label: 'Videolar',
              background: HexaColors.signalSoft,
              foreground: HexaColors.signalStrong,
            ),
            _FeatureBadge(
              icon: Icons.favorite_rounded,
              label: 'Signal',
              background: HexaColors.surfaceWarm,
              foreground: HexaColors.signal,
            ),
            _FeatureBadge(
              icon: Icons.people_alt_rounded,
              label: 'Topluluk',
              background: HexaColors.mintSoft,
              foreground: HexaColors.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: HexaColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileAuthError extends StatelessWidget {
  const _ProfileAuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(HexaSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(HexaRadius.md),
        border: Border.all(color: const Color(0xFFF7C8C4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: HexaColors.error,
            size: 20,
          ),
          const SizedBox(width: HexaSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: HexaColors.error,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
