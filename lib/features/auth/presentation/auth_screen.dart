import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hexa/core/theme/hexa_theme.dart';
import 'package:hexa/features/auth/application/auth_service.dart';
import 'package:hexa/features/auth/presentation/widgets/auth_background.dart';
import 'package:hexa/features/auth/presentation/widgets/hexagon_logo.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
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
      // Yönlendirmeyi router yapar. Böylece profil tamamlanmadan feed açılmaz.
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
        setState(() => _isLoading = false);
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
    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 720;
                final verticalPadding = isCompact ? 14.0 : 20.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    HexaSpacing.lg,
                    verticalPadding,
                    HexaSpacing.lg,
                    verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - verticalPadding * 2,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthContent(isCompact: isCompact),
                            Padding(
                              padding: EdgeInsets.only(
                                top: isCompact
                                    ? HexaSpacing.lg
                                    : HexaSpacing.xl,
                              ),
                              child: _AuthActions(
                                isLoading: _isLoading,
                                errorMessage: _errorMessage,
                                onGooglePressed: _handleGoogleSignIn,
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
    );
  }
}

class _AuthContent extends StatelessWidget {
  const _AuthContent({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandHeader(),
        SizedBox(height: isCompact ? HexaSpacing.lg : HexaSpacing.xl),
        _SignalHero(compact: isCompact),
        SizedBox(height: isCompact ? HexaSpacing.lg : HexaSpacing.xl),
        Text(
          'Değer katan videolar\ndaha hızlı keşfedilsin.',
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge?.copyWith(
            fontSize: isCompact ? 28 : 32,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: HexaSpacing.sm),
        Text(
          'Hexa’da beğeni yerine Signal verilir. Topluluk, gerçekten fayda sağlayan içerikleri görünür kılar ve üreticileri destekler.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: HexaColors.inkMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: HexaSpacing.lg),
        const Row(
          children: [
            Expanded(
              child: _ValueCard(
                icon: Icons.favorite_rounded,
                label: 'Signal',
                color: HexaColors.signal,
                background: HexaColors.signalSoft,
              ),
            ),
            SizedBox(width: HexaSpacing.sm),
            Expanded(
              child: _ValueCard(
                icon: Icons.auto_awesome_rounded,
                label: 'Keşif',
                color: HexaColors.success,
                background: HexaColors.mintSoft,
              ),
            ),
            SizedBox(width: HexaSpacing.sm),
            Expanded(
              child: _ValueCard(
                icon: Icons.celebration_rounded,
                label: 'Destek',
                color: Color(0xFF6E5AA8),
                background: HexaColors.lavenderSoft,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const HexagonLogo(size: 40, showShadow: false),
        const SizedBox(width: 10),
        Text(
          'HEXA',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: HexaColors.surface,
            borderRadius: BorderRadius.circular(HexaRadius.pill),
            border: Border.all(color: HexaColors.border),
          ),
          child: const Text(
            'DEĞER ODAKLI',
            style: TextStyle(
              color: HexaColors.inkMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignalHero extends StatelessWidget {
  const _SignalHero({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 126.0 : 160.0;
    final logoSize = compact ? 84.0 : 104.0;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: compact ? 150 : 184,
            height: compact ? 150 : 184,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x55FFE9ED), Color(0x00FFE9ED)],
              ),
            ),
          ),
          Container(
            width: compact ? 118 : 142,
            height: compact ? 118 : 142,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xBFFFFFFF),
              border: Border.all(color: HexaColors.border),
            ),
          ),
          HexagonLogo(size: logoSize),
          Positioned(
            top: compact ? 4 : 8,
            right: compact ? 28 : 64,
            child: const _FloatingBadge(emoji: '💡', text: 'Öğretici'),
          ),
          Positioned(
            left: compact ? 16 : 52,
            bottom: compact ? 0 : 6,
            child: const _FloatingBadge(emoji: '✨', text: 'İlham'),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(HexaRadius.pill),
        border: Border.all(color: HexaColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B141B),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: HexaColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: HexaColors.surface,
        borderRadius: BorderRadius.circular(HexaRadius.md),
        border: Border.all(color: HexaColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HexaColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: errorMessage == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(errorMessage),
                  padding: const EdgeInsets.only(bottom: HexaSpacing.sm),
                  child: _ErrorBanner(message: errorMessage!),
                ),
        ),
        FilledButton(
          onPressed: isLoading ? null : onGooglePressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HexaRadius.md),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Row(
                    key: ValueKey('content'),
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
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Devam ederek Hexa’nın kullanım koşullarını ve gizlilik politikasını kabul etmiş olursun.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: HexaColors.inkSoft,
            fontSize: 11,
            height: 1.35,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
          const SizedBox(width: 9),
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
